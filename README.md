# Project-4-MNIST

# 🔢 MNIST Digit Identifier: An End-to-End ML Case Study

This project demonstrates a complete Machine Learning lifecycle, from training a **Convolutional Neural Network (CNN)** in Python to deploying it within a **Native Windows Desktop Application** using Flutter and TensorFlow Lite.

## 🎯 Purpose
This repository serves as a showcase of technical problem-solving, specifically focusing on:
* **Model Research**: Training and optimizing a Keras model for edge inference.
* **Low-Level Integration**: Manual configuration of the TensorFlow Lite C-API and CMake on Windows.
* **Real-time Signal Processing**: Converting raw user touch-input into a standardized 28x28 grayscale tensor.

---

## 🔬 Phase 1: Training & Research (Python)
Located in the `/training` directory, this section documents the "Brain" of the project.

* **Architecture**: A CNN built with TensorFlow/Keras, utilizing 2D Convolution layers, MaxPooling, and Dropout for robust feature extraction.
* **Optimization**: The model was converted to `.tflite` (FlatBuffer) format to minimize latency during desktop inference.
* **Reproducibility**: Includes a `requirements.txt` to recreate the training environment.

---

## 🛠 Phase 2: Windows Engineering (Flutter)
The `/mnist_application` directory contains the deployment logic. This phase highlights the bridge between high-level UI and low-level ML binaries.

### 🧩 Challenge: TFLite DLL Integration
Windows desktop development often faces "Module Not Found" errors when loading external ML libraries. 
* **The Solution**: I implemented a custom **CMake** post-build command to automate the creation of a `blobs/` directory.
* **The Result**: The `libtensorflowlite_c-win.dll` is dynamically mapped to the executable at runtime, ensuring a portable and functional build.

### 🖌 Drawing-to-Tensor Logic
To achieve high accuracy with hand-drawn input, I developed a custom preprocessing pipeline:
1. **Bounding Box Detection**: Crops the user's drawing to remove empty space.
2. **Standardized Scaling**: Resizes the digit to fit a 20x20 area centered within a 28x28 black canvas, matching the MNIST dataset distribution.
3. **Grayscale Normalization**: Converts RGBA pixel data into a `float32` array where values range from `0.0` (black) to `1.0` (white).

---

## 📊 Key Features
* **Dual Input Modes**: Support for both manual drawing and image file uploads.
* **ASCII Visualization**: A console-based debug tool that prints the processed tensor as a 2D text-map, allowing for verification of the model's "vision."
* **Confidence Analysis**: Displays probability scores for all 10 digits (0-9).



---

## 🛠 Tech Stack
* **Training**: Python, TensorFlow, Keras, NumPy, Matplotlib
* **Application**: Dart, Flutter (Desktop), CMake
* **Inference**: TensorFlow Lite C-API (Windows)

---

## 📖 How to Run
* *Detailed setup for those wishing to test the research scripts or the app:*

### Training
```bash
cd training
pip install -r requirements.txt
python convert_to_tflite.py

---

### Application

cd mnist_application
flutter pub get
flutter run -d windows