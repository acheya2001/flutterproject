import 'package:flutter/material.dart';
import 'video_reconstruction_page.dart';

void main() {
  runApp(const TestVideoApp());
}

class TestVideoApp extends StatelessWidget {
  const TestVideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Reconstitution Vidéo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const AccidentVideoReconstructionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
