from __future__ import print_function

import os
import os.path

import cv2
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split

import keras
from codes import DATA_DIR, LOG_DIR, MODEL_DIR
from keras.callbacks import ModelCheckpoint
from keras.layers import Conv2D, MaxPooling2D
from keras.layers import Dense, Flatten
from keras.models import Sequential

FLAGS = tf.app.flags.FLAGS
flags = tf.app.flags

size_limit = 200000
test_ratio = 0.1
batch_size = 10
code_classes = 36
epochs = 10
str_center_list = [28, 64, 96, 132]

# input image dimensions
img_rows, img_cols = 48, 48

# alphabet convert to numbers
eng_list = list("0123456789abcdefghijklmnopqrstuvwxyz")
mapping = {}
for i, e in zip(range(37), eng_list):
    if isinstance(e, int):
        mapping[e] = i
    else:
        e = e.upper()
        mapping[e] = i


def get_image_ar_label(data_dir, size_limit=0):
    img_ar_list = []
    img_label_list = []
    iter_n = 0
    for img_file in os.listdir(data_dir):
        try:
            img_tags = img_file.split('_')
            img_label = img_tags[-1].split('.')[0]
            if len(img_label) == 4 and img_label.isalnum() and img_file[-8:-4].isalnum():
                img_path = data_dir + '/' + img_file
                img = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
                ret, img_t = cv2.threshold(img, 127, 255, cv2.THRESH_BINARY_INV)

                for str_seq in range(4):
                    img_label_map = mapping[img_label[str_seq].upper()]
                    str_center = str_center_list[str_seq]
                    img_ar_list.append(img_t[11:59, (str_center - 24):(str_center + 24)])
                    img_label_list.append(img_label_map)

                iter_n = iter_n + 1
                if 0 < size_limit <= iter_n:
                    break
        except Exception as e:
            print(img_file)
            continue

    return img_ar_list, img_label_list


def train(training_set_dir, model_dir, log_dir):
    # get image and label from training set
    x_list, y_list = get_image_ar_label(training_set_dir)

    # split into training and testing sets
    x_train, x_test, y_train, y_test = train_test_split(np.asarray(x_list), np.asarray(y_list), test_size=test_ratio,
                                                        random_state=66)
    x_train = x_train.reshape(x_train.shape[0], img_rows, img_cols, 1)
    x_test = x_test.reshape(x_test.shape[0], img_rows, img_cols, 1)
    input_shape = (img_rows, img_cols, 1)

    x_train = x_train.astype('float32')
    x_test = x_test.astype('float32')

    # convert class vectors to binary class matrices
    y_train = keras.utils.to_categorical(y_train, code_classes)
    y_test = keras.utils.to_categorical(y_test, code_classes)

    print(y_list[:10])
    print('x_train shape:', x_train.shape)
    print(x_train.shape[0], 'train samples')
    print(x_test.shape[0], 'test samples')

    # set up model
    model = Sequential()
    model.add(Conv2D(32, kernel_size=(3, 3),
                     activation='relu',
                     input_shape=input_shape))
    model.add(Conv2D(32, (3, 3), activation='relu'))

    model.add(MaxPooling2D(pool_size=(2, 2)))
    # model.add(Dropout(0.25))

    model.add(Conv2D(64, (3, 3), activation='relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    # model.add(Dropout(0.25))

    model.add(Conv2D(128, (3, 3), activation='relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))

    model.add(Conv2D(256, (3, 3), activation='relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    # model.add(Dropout(0.25))

    model.add(Flatten())
    model.add(Dense(512, activation='relu'))
    # model.add(Dropout(0.5))
    model.add(Dense(code_classes, activation='softmax'))

    model.compile(loss=keras.losses.categorical_crossentropy,
                  optimizer=keras.optimizers.Adadelta(),
                  metrics=['accuracy'])

    # model.load_weights('./weight_structure/10010_v0_best_weight.hdf5')
    model_path = model_dir + '/10010_v0_1_best_weight.hdf5'
    checkpoint = ModelCheckpoint(filepath=model_path, verbose=1, save_best_only=True)
    # tb_callback = keras.callbacks.TensorBoard(log_dir=log_dir, histogram_freq=0, write_graph=True, write_images=True)
    # model.fit(x_train, y_train, batch_size=batch_size, epochs=epochs, verbose=1, validation_data=(x_test, y_test),
    #           callbacks=[checkpoint, tb_callback])
    model.fit(x_train, y_train, batch_size=batch_size, epochs=epochs, verbose=1, validation_data=(x_test, y_test),
              callbacks=[checkpoint])
    score = model.evaluate(x_test, y_test, verbose=0)
    print('Test loss:', score[0])
    print('Test accuracy:', score[1])

    json_string = model.to_json()
    open(model_dir + '/10010_v0_1_structure.json', 'w').write(json_string)


if __name__ == "__main__":
    print("start training ... ")
    train(DATA_DIR + '/10010/', MODEL_DIR, LOG_DIR)
    print("train done")
