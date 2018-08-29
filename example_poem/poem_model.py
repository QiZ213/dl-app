# coding=utf-8

from __future__ import print_function

import os
import random

import numpy as np
from keras.layers import Dense, Activation
from keras.layers import LSTM
from keras.models import Sequential, load_model
from keras.optimizers import RMSprop

from application import RESOURCE_DIR
from application.utils import load_json

# init model for once
maxlen = 32
# charslen = 3802
charslen = 3105

# Load chars
path = os.path.join(RESOURCE_DIR, 'poem_7words.txt')
text = open(path).read().lower()
print('corpus length:', len(text))

start_index = random.randint(0, 30)
# print(text.decode('utf-8')[start_index * 8:start_index * 8 + 64])

chars = sorted(list(set(text.decode('utf-8'))))

print('total chars:', len(chars))
char_indices = dict((c, i) for i, c in enumerate(chars))
indices_char = dict((i, c) for i, c in enumerate(chars))
# TODO：Save in pkl, to save load time, save it as a parameter

# build the model: a single LSTM
print('Build model...')
model = Sequential()
print(maxlen)
print(charslen)
model.add(LSTM(128, input_shape=(maxlen, charslen)))
model.add(Dense(charslen))
model.add(Activation('softmax'))
optimizer = RMSprop(lr=0.01)

model.compile(loss='categorical_crossentropy', optimizer=optimizer)

model = load_model(os.path.join(RESOURCE_DIR, 'my_model_peom_best.h5'))

# predict empty numpy array
model.predict(np.zeros((1, maxlen, charslen)))


def write_poem(data, mark=None, params=None, metas=None):

    data = load_json(data)
    strPrefix = data.get('word')

    def sample(preds, temperature=1.0):
        # helper function to sample an index from a probability array
        preds = np.asarray(preds).astype('float64')
        preds = np.log(preds) / temperature
        exp_preds = np.exp(preds)
        preds = exp_preds / np.sum(exp_preds)
        probas = np.random.multinomial(1, preds, 1)
        return np.argmax(probas)

    outputSentence = []
    # train the model, output generated text after each iteration
    # for iteration in range(1, 60):
    for iteration in range(1, 2):
        print()
        print('-' * 50)
        # print('Iteration', iteration)

        word_index = 0
        # sentence = strPrefix[start_index]

        for diversity in [0.2, 0.5, 1.0, 1.2]:
            # print()
            # print('----- diversity:', diversity)

            generated = ''
            word_index = 0
            sentence = strPrefix[word_index:word_index + 1]
            # generated += sentence.decode('utf-8')
            generated += sentence
            # print('----- Generating with seed: "' + sentence.decode('utf-8') + '"')
            for i in range(1, maxlen - 5):
                if (len(sentence) > maxlen):
                    break
                x = np.zeros((1, maxlen, charslen))
                # print (sentence.decode('utf-8'))
                # for t, char in enumerate(sentence.decode('utf-8')):
                for t, char in enumerate(sentence):
                    # print (t)
                    # print (char)
                    # x[0, t, char_indices[char.decode('utf-8')]] = 1.
                    x[0, t, char_indices[char]] = 1.

                preds = model.predict(x, verbose=0)[0]  # Predict Next char

                next_index = sample(preds, diversity)
                next_char = indices_char[next_index]

                # generated += next_char.decode('utf-8')
                generated += next_char
                sentence = generated

                if ((len(sentence) + 1) % 8 == 0):
                    # sys.stdout.write(' ')
                    sentence += " "
                    generated += " "
                    word_index += 1
                    # print("len{}".format(word_index))
                    if (word_index < len(strPrefix)):
                        generated += strPrefix[word_index:word_index + 1]
                        sentence = generated

            # 有bug, 输入2个字、3个字、4个字返回不同
            generated = generated[0:31]
            outputSentence.append(generated)
            # sys.stdout.write(generated)
            # sys.stdout.flush()
            print()
    return outputSentence


if __name__ == '__main__':
    # Read parameters
    import argparse

    parser = argparse.ArgumentParser(description='Description of your program')
    parser.add_argument('-w', '--word', help='type Word', type=str, required=True, default=u"机器学习")

    args = vars(parser.parse_args())
    word = args['word']
    strPrefix = word.decode('utf-8')

    # reload(sys)
    # sys.setdefaultencoding('utf-8')

    # Print Out
    outputSentence = write_poem(strPrefix)
    for k, v in enumerate(outputSentence):
        print(v)
