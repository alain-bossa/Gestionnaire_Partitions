import 'package:flutter/material.dart';
import 'package:music_pdf/screens/pdf_list_screen.dart'; // Mettez à jour ce chemin

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lecteur PDF Annotable V1.0',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PdfListScreen(),
      debugShowCheckedModeBanner: false, // Pour masquer le bandeau "DEBUG"
    );
  }
}