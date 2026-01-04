import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Classifier {
  Classifier();

  Interpreter? interpreter;

  Future<void> loadModel() async {
    if (interpreter != null) return;

    try {
      String modelPath;

      if (Platform.isWindows) {
        // On Windows, load from runner folder
        modelPath = 'windows/runner/Debug/model.tflite';
        interpreter = await Interpreter.fromFile(File(modelPath));
      } else {
        // On mobile, load from Flutter assets
        interpreter = await Interpreter.fromAsset('assets/model.tflite');
      }

      print("Model loaded successfully");
    } catch (e) {
      print("Model failed to load: $e");
    }
  }


  classifyImage(File image) async {
    var file = File(image.path);
    img.Image? imageTemp = img.decodeImage(file.readAsBytesSync());
    if (imageTemp == null) throw Exception("Unable to decode image");

    // 1. Resize the image
    img.Image resizedImg = img.copyResize(imageTemp, height: 28, width: 28);

    // 2. Create the list manually by looking at each pixel
    List<double> resultBytes = List.filled(28 * 28, 0.0);

    int index = 0;
    for (int y = 0; y < 28; y++) {
      for (int x = 0; x < 28; x++) {
        // Get the pixel at x, y
        var pixel = resizedImg.getPixel(x, y);

        // Extract RGB values (works across different library versions)
        num r = pixel.r;
        num g = pixel.g;
        num b = pixel.b;

        // Convert to grayscale 0.0 - 1.0
        double gray = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

        // MNIST is White digit (1.0) on Black background (0.0)
        // If your app uses a white background, keep this inversion:
        // gray = 1.0 - gray;

        resultBytes[index] = gray;
        index++;
      }
    }

    // 3. Pass the processed list directly to getPred
    return getPredFromList(resultBytes);
  }


  Future<Map<String, dynamic>> classifyDrawing(List<Offset?> points) async {
    if (points.isEmpty) return {"digit": -1, "confidence": 0.0};

    // 1. Find the Bounding Box of the drawing
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (var p in points) {
      if (p != null) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(28, 28)));

    canvas.drawRect(Rect.fromLTWH(0, 0, 28, 28), Paint()..color = Colors.black);

    // Calculate drawing dimensions
    double drawingWidth = maxX - minX;
    double drawingHeight = maxY - minY;

    // Prevent division by zero for single dots
    drawingWidth = drawingWidth == 0 ? 1 : drawingWidth;
    drawingHeight = drawingHeight == 0 ? 1 : drawingHeight;

    // 3. Center and Scale Logic
    // We want the digit to fit in a 20x20 area inside the 28x28 box (padding)
    double scale = 18 / (drawingWidth > drawingHeight ? drawingWidth : drawingHeight);

    canvas.save();
    // Move to the center of the 28x28 canvas
    canvas.translate(14, 14);
    canvas.scale(scale);
    canvas.translate(-(minX + drawingWidth / 2), -(minY + drawingHeight / 2));

    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5 / scale; // Adjust thickness based on scale

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
    canvas.restore();

    // 4. Convert to Pixels
    final picture = recorder.endRecording();
    final img = await picture.toImage(28, 28);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    List<double> resultBytes = List.filled(28 * 28, 0.0);
    int index = 0;
    for (int i = 0; i < bytes.length; i += 4) {
      resultBytes[index] = bytes[i] / 255.0;
      index++;
    }

    return getPredFromList(resultBytes);
  }

  Future<Map<String, dynamic>> getPredFromList(List<double> resultBytes) async {
    // Keep your ASCII Debugging block here to verify
    print("--- MODEL INPUT VISUALIZATION ---");
    for (int y = 0; y < 28; y++) {
      String row = "";
      for (int x = 0; x < 28; x++) {
        row += resultBytes[y * 28 + x] > 0.5 ? "##" : "  ";
      }
      print(row);
    }

    var input = resultBytes.reshape(([1, 28, 28, 1]));
    var output = List.generate(1, (_) => List.filled(10, 0.0));

    if (interpreter == null) {
      return {"digit": -1, "confidence": 0.0};
    }
    interpreter!.run(input, output);

    print("--- PROBABILITIES ---");
    for (int i = 0; i < output[0].length; i++) {
      double numProb = output[0][i];
      print("$i: $numProb");
    }
    print("-------------------------");

    double highestProb = -1.0;
    int digitPred = -1;
    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > highestProb) {
        highestProb = output[0][i];
        digitPred = i;
      }
    }
    return {
      "digit": digitPred,
      "confidence": (highestProb * 100).toStringAsFixed(2) // e.g., "98.50"
    };
  }
}