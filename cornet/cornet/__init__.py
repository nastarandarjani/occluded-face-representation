import torch
import torch.utils.model_zoo
from torch import nn
import math

from cornet.cornet_z import CORnet_Z
from cornet.cornet_z import HASH as HASH_Z
from cornet.cornet_r import CORnet_R
from cornet.cornet_r import HASH as HASH_R
from cornet.cornet_rt import CORnet_RT
from cornet.cornet_rt import HASH as HASH_RT
from cornet.cornet_s import CORnet_S
from cornet.cornet_s import HASH as HASH_S
from cornet.cornet_pfc import CORnet_PFC


def get_model(model_letter, pretrained=False, map_location=None, **kwargs):
    model_letter = model_letter.upper()
    model = globals()[f'CORnet_{model_letter}'](**kwargs)
    model = torch.nn.DataParallel(model)
    if pretrained:
        model_hash = globals()[f'HASH_{model_letter}']
        # TODO: add pfc weights folder
        url = f'https://s3.amazonaws.com/cornet-models/cornet_{model_letter.lower()}-{model_hash}.pth'
        ckpt_data = torch.utils.model_zoo.load_url(url, map_location=map_location)
        model.load_state_dict(ckpt_data['state_dict'])
    else:
        if model_letter == 'PFC':
            url = 'https://s3.amazonaws.com/cornet-models/cornet_s-1d3f7974.pth'
            ckpt_data = torch.utils.model_zoo.load_url(url, map_location=map_location)
            model.load_state_dict(ckpt_data['state_dict'], strict=False)

            # freeze V1, V2 and V4 layers
            for name, param in model.named_parameters():
                if ('V1' in name) or ('V2' in name) or ('V4' in name):
                    param.requires_grad = False

            # weight initialization for IT, PFC and decoder layers
            for name, module in model.named_modules():
                if 'IT' in name or 'PFC' in name:
                    if isinstance(module, nn.Conv2d):
                        n = module.kernel_size[0] * module.kernel_size[1] * module.out_channels
                        module.weight.data.normal_(0, math.sqrt(2. / n))
                    elif isinstance(module, nn.BatchNorm2d):
                        module.weight.data.fill_(1)
                        module.bias.data.zero_()
                if 'decoder' in name:
                    if hasattr(module, 'reset_parameters'):
                        module.reset_parameters()
    return model


def cornet_z(pretrained=False, map_location=None):
    return get_model('z', pretrained=pretrained, map_location=map_location)


def cornet_r(pretrained=False, map_location=None, times=5):
    return get_model('r', pretrained=pretrained, map_location=map_location, times=times)


def cornet_rt(pretrained=False, map_location=None, times=5):
    return get_model('rt', pretrained=pretrained, map_location=map_location, times=times)


def cornet_pfc(pretrained=False, map_location=None, times=5):
    return get_model('pfc', pretrained=pretrained, map_location=map_location, times=times)


def cornet_s(pretrained=False, map_location=None):
    return get_model('s', pretrained=pretrained, map_location=map_location)

