import 'dart:convert';
import 'package:flutter/material.dart';

class StoryViewerScreen extends StatelessWidget {
  final String base64Image;
  const StoryViewerScreen({super.key, required this.base64Image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Image.memory(base64Decode(base64Image), fit: BoxFit.contain),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
