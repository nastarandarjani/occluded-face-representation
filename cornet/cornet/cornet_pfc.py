import math
from collections import OrderedDict
from torch import nn
import torch

HASH = '1d3f7974'


class Flatten(nn.Module):
    """
    Helper module for flattening input tensor to 1-D for the use in Linear modules
    """

    def forward(self, x):
        return x.view(x.size(0), -1)


class Identity(nn.Module):
    """
    Helper module that stores the current tensor. Useful for accessing by name
    """

    def forward(self, x):
        return x


class CORblock_PFC(nn.Module):
    scale = 4  # scale of the bottleneck convolution channels

    def __init__(self, in_channels, out_channels, times=1):
        super().__init__()
        self.times = times

        self.conv_input = nn.Conv2d(in_channels, out_channels, kernel_size=1, bias=False)
        self.skip = nn.Conv2d(out_channels, out_channels,
                              kernel_size=1, stride=2, bias=False)
        self.norm_skip = nn.BatchNorm2d(out_channels)

        self.conv1 = nn.Conv2d(out_channels, out_channels * self.scale,
                               kernel_size=1, bias=False)
        self.nonlin1 = nn.ReLU(inplace=True)

        self.conv2 = nn.Conv2d(out_channels * self.scale, out_channels * self.scale,
                               kernel_size=3, stride=2, padding=1, bias=False)
        self.nonlin2 = nn.ReLU(inplace=True)

        self.conv3 = nn.Conv2d(out_channels * self.scale, out_channels,
                               kernel_size=1, bias=False)
        self.nonlin3 = nn.ReLU(inplace=True)

        self.output = Identity()  # for an easy access to this block's output

        # need BatchNorm for each time step for training to work well
        for t in range(self.times):
            setattr(self, f'norm1_{t}', nn.BatchNorm2d(out_channels * self.scale))
            setattr(self, f'norm2_{t}', nn.BatchNorm2d(out_channels * self.scale))
            setattr(self, f'norm3_{t}', nn.BatchNorm2d(out_channels))

    def forward(self, inp=None, is_feedback=False, same_size=False):
        if is_feedback:
            x = inp
        else:
            x = self.conv_input(inp)

        for t in range(self.times):
            if t == 0 and (not same_size):
                skip = self.norm_skip(self.skip(x))
                self.conv2.stride = (2, 2)
            else:
                skip = x
                self.conv2.stride = (1, 1)

            x = self.conv1(x)
            x = getattr(self, f'norm1_{t}')(x)
            x = self.nonlin1(x)

            x = self.conv2(x)
            x = getattr(self, f'norm2_{t}')(x)
            x = self.nonlin2(x)

            x = self.conv3(x)
            x = getattr(self, f'norm3_{t}')(x)

            x += skip
            x = self.nonlin3(x)
            output = self.output(x)

        return output


class CORnet_PFC(nn.Module):

    def __init__(self, times=5):
        super().__init__()
        self.times = times

        self.V1 = nn.Sequential(OrderedDict([  # this one is custom to save GPU memory
            ('conv1', nn.Conv2d(3, 64, kernel_size=7, stride=2, padding=3,
                                bias=False)),
            ('norm1', nn.BatchNorm2d(64)),
            ('nonlin1', nn.ReLU(inplace=True)),
            ('pool', nn.MaxPool2d(kernel_size=3, stride=2, padding=1)),
            ('conv2', nn.Conv2d(64, 64, kernel_size=3, stride=1, padding=1,
                                bias=False)),
            ('norm2', nn.BatchNorm2d(64)),
            ('nonlin2', nn.ReLU(inplace=True)),
            ('output', Identity())
        ]))
        self.V2 = CORblock_PFC(64, 128, times=2)
        self.V4 = CORblock_PFC(128, 256, times=4)
        self.IT = CORblock_PFC(256, 512, times=2)
        self.PFC = CORblock_PFC(512, 512, times=2)
        self.decoder = nn.Sequential(OrderedDict([
            ('avgpool', nn.AdaptiveAvgPool2d(1)),
            ('flatten', Flatten()),
            ('linear', nn.Linear(512, 1000)),
            ('output', Identity())
        ]))
        self.norm = nn.GroupNorm(32, 512)

    def forward(self, inp):
        x = self.V1(inp)
        x = self.V2(x)
        x = self.V4(x)
        for t in range(self.times):
            if t == 0:
                # set feedback to zero
                feedback = torch.zeros([len(x), 256, 14, 14])
                if self.V2.conv_input.weight.is_cuda:
                    feedback = feedback.cuda()
                is_feedback = False
                same_size = True
                x = x + feedback
            else:
                x = self.norm(x + feedback)
                is_feedback = True

            if t == self.times - 1:
                same_size = False
            x = self.IT(x, is_feedback=is_feedback, same_size=same_size)
            feedback = self.PFC(x, same_size=same_size)

        out = self.decoder(x)
        return out
