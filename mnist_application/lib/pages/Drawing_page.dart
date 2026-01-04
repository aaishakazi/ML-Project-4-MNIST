import 'package:flutter/material.dart';
import 'package:mnist_application/dl_model/Classifier.dart';
import 'dart:ui';

class DrawPage extends StatefulWidget {
  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  Classifier classifier = Classifier();
  List<Offset?> points = [];
  int digit = -1;
  String confidence = "";
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    classifier.loadModel();
  }

  void _clearCanvas() {
    setState(() {
      points.clear();
      digit = -1;
      confidence = "";
      isProcessing = false;
    });
  }
  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.pinkAccent),
          const Text(
            "DIGIT IDENTIFIER",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            onPressed: _clearCanvas,
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
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
              _buildCustomAppBar(),
              const SizedBox(height: 30),

              _buildCanvasCard(),
              const SizedBox(height: 40),

              _buildResultCard(),
              const Spacer(),

              _buildActionButtons(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Translucent white
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
                fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 10),
          isProcessing
              ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          )
              : Text(
            digit == -1 ? "" : "$digit",
            style: const TextStyle(
                fontSize: 70,
                color: Colors.white,
                fontWeight: FontWeight.w200
            ),
          ),
          if (digit != -1 && !isProcessing)
            Text(
              "$confidence% match",
              style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
            ),
        ],
      ),
    );
  }
  Widget _buildCanvasCard() {
    return Container(
      height: 300,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() => points.add(details.localPosition));
          },
          onPanEnd: (details) async {
            points.add(null);
            setState(() => isProcessing = true);
            final result = await classifier.classifyDrawing(points);
            setState(() {
              digit = result['digit'];
              confidence = result['confidence'].toString();
              isProcessing = false;
            });
          },
          child: CustomPaint(
            painter: Painter(points: points),
          ),
        ),
      ),
    );
  }
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton(
        onPressed: _clearCanvas,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 10,
          shadowColor: Colors.pinkAccent.withOpacity(0.5),
        ),
        child: const Text("CLEAR CANVAS", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

}

class Painter extends CustomPainter {
  final  List <Offset?> points;
  Painter({required this.points});

  final Paint paintDetails = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = Colors.black
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i=0; i < points.length -1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paintDetails);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}