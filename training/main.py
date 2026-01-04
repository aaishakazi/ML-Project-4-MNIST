import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = '2'
import math
import tensorflow as tf
import tensorflow_datasets as tfds
from tensorflow import keras
from tensorflow.keras import layers 
from tensorflow.keras.layers import RandomRotation

# physical_devices = tf.config.list_physical_devices("GPU")
# tf.config.experimental.set_memory_growth(physical_devices[0], True)

(ds_train, ds_test), ds_info = tfds.load(
    "mnist",
    split=["train", "test"],
    shuffle_files = False,
    with_info=True,
    as_supervised=True
)

@tf.function
def normalise_img(image, label):
    return tf.cast(image, tf.float32)/255.0, label

# Create a RandomRotation layer with 25 degrees max rotation
rotation_layer = RandomRotation(
    factor=25/360,  # factor is fraction of 1, so 25 degrees ≈ 25/360
    fill_mode='nearest',       # one of the allowed modes
    interpolation='bilinear'
)

@tf.function
def augment(image, label):
    image = tf.image.resize(image, size=[28, 28])
    image = tf.expand_dims(image, 0) 
    image = rotation_layer(image)
    image = tf.squeeze(image, 0)
    image = tf.image.random_brightness(image, max_delta=0.2)
    image = tf.image.random_contrast(image, lower= 0.5, upper=1.5)
    return image, label

AUTOTUNE = tf.data.experimental.AUTOTUNE
batch_size = 32

ds_train = ds_train.cache()
ds_train = ds_train.shuffle(ds_info.splits['train'].num_examples)
ds_train = ds_train.map(normalise_img, num_parallel_calls=AUTOTUNE)
ds_train = ds_train.map(augment, num_parallel_calls=AUTOTUNE)
ds_train = ds_train.batch(batch_size)
ds_train = ds_train.prefetch(AUTOTUNE)

ds_test = ds_test.map(normalise_img, num_parallel_calls=AUTOTUNE)
ds_test = ds_test.batch(batch_size)
ds_test = ds_test.prefetch(AUTOTUNE)

def my_model():
    inputs = keras.Input(shape = (28, 28, 1))

    x = layers.Conv2D(32,3)(inputs)
    x = layers.BatchNormalization()(x)
    x = keras.activations.relu(x)
    x = layers.MaxPooling2D()(x)

    x = layers.Conv2D(64,3)(x)
    x = layers.BatchNormalization()(x)
    x = keras.activations.relu(x)
    x = layers.MaxPooling2D()(x)

    x = layers.Conv2D(128,3)(x)
    x = layers.BatchNormalization()(x)
    x = keras.activations.relu(x)
    x = layers.Flatten()(x)
    x = layers.Dense(64, activation="relu")(x)

    outputs = layers.Dense(10, activation="softmax")(x)
    return keras.Model(inputs=inputs, outputs=outputs)

model = my_model()
model.compile(loss = keras.losses.SparseCategoricalCrossentropy(from_logits=False), 
            optimizer = keras.optimizers.Adam(learning_rate=1e-4),
            metrics = ["accuracy"],)

model.fit(ds_train, epochs=30, verbose = 2)
model.evaluate(ds_test)
model.export("model")
