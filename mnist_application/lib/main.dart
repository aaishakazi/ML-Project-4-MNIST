import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mnist_application/pages/Upload_page.dart';
import 'package:mnist_application/pages/Drawing_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentIndex = 0;
  List tabs = [
    UploadPage(),
    DrawPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabs[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF16213E),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.cloud_upload), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.palette), label: 'Draw'),
        ],
      onTap: (index) {
          setState(() {
            currentIndex = index;
          });
      },
      ),
    );
  }
}


