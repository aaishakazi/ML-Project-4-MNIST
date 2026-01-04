import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mnist_application/dl_model/Classifier.dart';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  Classifier classifier = Classifier();
  File? _image;
  int digit = -1;
  String confidence = "";
  bool isProcessing = false;
  final picker = ImagePicker();

  void _resetPage() {
    setState(() {
      _image = null;
      digit = -1;
      confidence = "";
      isProcessing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    classifier.loadModel();
  }

  // Function to pick image from gallery or camera
  Future getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        isProcessing = true;
      });

      // Run Classification
      final result = await classifier.classifyImage(_image!);

      setState(() {
        digit = result['digit'];
        confidence = result['confidence'].toString();
        isProcessing = false;
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 40),

              _buildImageCard(),
              const SizedBox(height: 80),

              _buildResultCard(),
              const Spacer(),

              _buildUploadButtons(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          const Text(
            "DIGIT CLASSIFIER",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            onPressed: _resetPage,
            icon: const Icon(Icons.refresh, color: Colors.white54),
            tooltip: "Clear Selection",
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      height: 300,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
          child: _image == null
            ? _buildPlaceholder()
            : Image.file(_image!, fit: BoxFit.cover),
        ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search, size: 60, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 15),
          Text(
            "No Image Selected",
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            "PREDICTION",
            style: TextStyle(
                color: Colors.pinkAccent.withOpacity(0.8),
                letterSpacing: 3,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          isProcessing
              ? const CircularProgressIndicator(color: Colors.pinkAccent)
              : Text(
            digit == -1 ? "" : "$digit",
            style: const TextStyle(
                fontSize: 70, color: Colors.white, fontWeight: FontWeight.w200),
          ),
          if (digit != -1 && !isProcessing)
            Text(
              "$confidence% confident",
              style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: _neonButton(
              icon: Icons.photo_library,
              label: "GALLERY",
              onTap: () => getImage(ImageSource.gallery),
            ),
          ),
          // Only show camera button if NOT on Windows
          if (!Platform.isWindows) ...[
            const SizedBox(width: 15),
            Expanded(
              child: _neonButton(
                icon: Icons.camera_alt,
                label: "CAMERA",
                onTap: () => getImage(ImageSource.camera),
              ),
            ),
          ],
        ],
      )
    );
  }

  Widget _neonButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.white24)),
      ),
    );
  }
}