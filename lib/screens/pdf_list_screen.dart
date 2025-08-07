import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:music_pdf/screens/pdf_viewer_screen.dart';
import 'dart:typed_data';

class PdfListScreen extends StatefulWidget {
  const PdfListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PdfListScreenState createState() => _PdfListScreenState();
}

class _PdfListScreenState extends State<PdfListScreen> {
  final String googleDriveFolderId = '1Ora4ax8JqYGuMp6smKtJPdMblRpR2yUT';
  final String googleApiKey = 'AIzaSyAW_md5zhWt23_BqWnq8geTGHk0bU-9S9g';

  List<Map<String, String>> _pdfFiles = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPdfFilesFromDrive();
  }

  Future<void> _fetchPdfFilesFromDrive() async {
  setState(() {
    _isLoading = true;
    _errorMessage = ''; // Réinitialiser le message d'erreur
  });

  String? pageToken;
  List<Map<String, String>> allFiles = [];

  try {
    do {
      String url =
          'https://www.googleapis.com/drive/v3/files?q=\'$googleDriveFolderId\'+in+parents+and+trashed=false&orderBy=name&pageSize=1000&key=$googleApiKey';
      
      if (pageToken != null) {
        url += '&pageToken=$pageToken';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final files = data['files'] as List;

        allFiles.addAll(files.map((file) {
          return {
            'name': file['name'] as String,
            'id': file['id'] as String,
          };
        }).toList());

        pageToken = data['nextPageToken'];

      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Échec du chargement de la liste PDF. Code: ${response.statusCode}';
        });
        return; // Sortir de la fonction en cas d'erreur
      }
    } while (pageToken != null);

    setState(() {
      _pdfFiles = allFiles;
      _isLoading = false;
    });

  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Une erreur est survenue: $e';
    });
  }
}

  Future<Uint8List?> _downloadPdfBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner un PDF V1.0 - AC 2025'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _pdfFiles.length,
                  itemBuilder: (context, index) {
                    final file = _pdfFiles[index];
                    final fileName = file['name'] ?? 'Nom inconnu';
                    final fileId = file['id'] ?? '';
                    final fileUrl =
                        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media&key=$googleApiKey';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading:
                            const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(fileName),
                        onTap: () async {
                          final pdfBytes = await _downloadPdfBytes(fileUrl);
                          if (pdfBytes != null) {
                            // ignore: use_build_context_synchronously
                            Navigator.push(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfViewerScreen(
                                  pdfBytes: pdfBytes,
                                  documentPath: fileName,
                                ),
                              ),
                            );
                          } else {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Échec du téléchargement du PDF.')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
