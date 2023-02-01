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

mac = loadmat("rdm\\macaque.mat")
IT1 = mac['cor_IT1']
IT2 = mac['cor_IT2']
PFC = mac['cor_PFC']

IT1_easy = compute_rsa(IT1, "", 'ITZ_whole', ~is_hard)
IT1_hard = compute_rsa(IT1, "", 'ITZ_whole', is_hard)
IT2_easy = compute_rsa(IT2, "", 'ITZ_whole', ~is_hard)
IT2_hard = compute_rsa(IT2, "", 'ITZ_whole', is_hard)
# PFC_easy = compute_rsa(PFC, "", 'ITS_whole', ~is_hard)
# PFC_hard = compute_rsa(PFC, "", 'ITS_whole', is_hard)

time = np.squeeze(loadmat("rdm\\sub1.mat")['time'])


def normalize(data, zero):
    data = np.transpose(data)
    mean = np.mean(data[:zero, :], 0)
    # std = np.std(data[:zero, :], 0)
    data -= mean
    # data /= std
    return np.transpose(data)


zero = np.argmin(np.abs(time))
IT1_easy = normalize(IT1_easy, zero)
IT1_hard = normalize(IT1_hard, zero)
IT2_easy = normalize(IT2_easy, zero)
IT2_hard = normalize(IT2_hard, zero)


savemat("result\\macaque.mat", mdict={'time': time, 'IT1_easy': IT1_easy, 'IT2_easy': IT2_easy, 'IT1_hard': IT1_hard, 'IT2_hard': IT2_hard})

plt.plot(time, np.mean(IT1_easy, 0), label='IT1_easy')
plt.plot(time, np.mean(IT1_hard, 0), label='IT1_hard')
plt.plot(time, np.mean(IT2_easy, 0), label='IT2_easy')
plt.plot(time, np.mean(IT2_hard, 0), label='IT2_hard')
# plt.plot(time, np.mean(PFC_easy, 0), label='PFC_easy')
# plt.plot(time, np.mean(PFC_hard, 0), label='PFC_hard')
plt.legend()
plt.vlines([0.1, 0.23, 0.4], 0, 0.15, color='black', linestyles='--')
plt.show()

