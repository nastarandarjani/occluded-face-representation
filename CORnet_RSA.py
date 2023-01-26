import numpy as np
from scipy.io import loadmat
from scipy.stats import pearsonr
from scipy.stats import spearmanr
import matplotlib.pyplot as plt
from tqdm import tqdm
from scipy.io import savemat


def compute_rsa(model, region, name, is_hard):

    model = 1 - np.corrcoef(model[is_hard])

    res = loadmat("rdm\\rdm_EEG" + region + '.mat')
    face = res['cor_EEG']

    face_rsa = np.zeros((11, 206))
    for sub in tqdm(range(11)):
        for t in range(206):
            x = face[sub, is_hard, :, t]
            x = x[:, is_hard]
            # rnd_model = np.random.permutation(model.flatten()).reshape(np.shape(model))

            face_rsa[sub, t], _ = spearmanr(x.flatten(), model.flatten())
            # rand_rsa, _ = spearmanr(x.flatten(), rnd_model.flatten())

            # shuffle correction
            # face_rsa[sub, t] = face_rsa[sub, t] - rand_rsa

    np.save("result\\" + name, face_rsa)
    return face_rsa


is_hard = np.full((27,), False)
is_hard[11:18] = True
is_hard[21:24] = True
is_hard = np.tile(is_hard, (1, 4))
is_hard = np.reshape(is_hard, (108,))

ITS = np.load('CORnet-S_IT_output_feats.npy')
PFCS = np.load('CORnet-S_IT_skip_feats.npy')

ITS_easy = compute_rsa(ITS, "", 'ITS_whole', ~is_hard)
PFCS_easy = compute_rsa(PFCS, "", 'PFCS_whole', ~is_hard)
ITS_hard = compute_rsa(ITS, "", 'ITS_whole', is_hard)
PFCS_hard = compute_rsa(PFCS, "", 'PFCS_whole', is_hard)

time = np.squeeze(loadmat("rdm\\sub1.mat")['time'])

savemat("result\\res.mat", mdict={'time': time, 'ITS_easy': ITS_easy, 'PFCS_easy': PFCS_easy, 'ITS_hard':ITS_hard, 'PFCS_hard':PFCS_hard})

plt.plot(time, np.mean(ITS_easy, 0), label='ITS_easy')
plt.plot(time, np.mean(PFCS_easy, 0), label='PFCS_easy')
plt.plot(time, np.mean(ITS_hard, 0), label='ITS_hard')
plt.plot(time, np.mean(PFCS_hard, 0), label='PFCS_hard')
plt.legend()
plt.vlines([0.1, 0.23, 0.4], 0, 0.3, color='black', linestyles='--')
plt.show()

