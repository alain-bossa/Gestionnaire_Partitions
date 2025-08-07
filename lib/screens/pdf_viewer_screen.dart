import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:music_pdf/models/annotation_models.dart' as my_annotations;
import 'package:music_pdf/widgets/annotation_painter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum AnnotationMode { none, freehand, text }

class PdfViewerScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String documentPath;

  const PdfViewerScreen({
    super.key,
    required this.pdfBytes,
    required this.documentPath,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Map<int, List<my_annotations.Annotation>> _annotations = {};
  late PdfViewerController _pdfViewerController;
  int _currentPage = 1;

  my_annotations.FreehandAnnotation _currentLine =
      my_annotations.FreehandAnnotation(points: [], pageIndex: 0);

  AnnotationMode _currentMode = AnnotationMode.none;

  double _currentScale = 1.0;
  Offset _currentTranslation = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();

    // Ajoutez un écouteur au contrôleur
    _pdfViewerController.addListener(_onPdfViewerControllerChanged);
    _loadAnnotations();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  // Nouvelle méthode pour charger les annotations
  Future<void> _loadAnnotations() async {
    final prefs = await SharedPreferences.getInstance();
    // Créez la même clé unique pour le chargement
    final annotationKey = 'saved_annotations_${widget.documentPath}';
    final annotationsString = prefs.getString(annotationKey);

    if (annotationsString != null) {
      final decodedData = json.decode(annotationsString) as List<dynamic>;
      final loadedAnnotations = <int, List<my_annotations.Annotation>>{};

      for (final item in decodedData) {
        final annotationType = item['type'];
        // Définissez le type de la variable explicitement comme 'my_annotations.Annotation'
        late my_annotations.Annotation annotation;

        if (annotationType == 'text') {
          annotation = my_annotations.TextAnnotation.fromJson(item);
        } else if (annotationType == 'freehand') {
          annotation = my_annotations.FreehandAnnotation.fromJson(item);
        } else {
          continue;
        }

        if (!loadedAnnotations.containsKey(annotation.pageIndex)) {
          loadedAnnotations[annotation.pageIndex] = [];
        }
        loadedAnnotations[annotation.pageIndex]!.add(annotation);
      }

      setState(() {
        _annotations = loadedAnnotations;
      });
    }
  }

  // Nouvelle méthode pour sauvegarder les annotations
  Future<void> _saveAnnotations() async {
    final prefs = await SharedPreferences.getInstance();

    // Flatten la Map en une seule liste d'annotations pour la sérialisation
    final allAnnotations = _annotations.values.expand((list) => list).toList();
    final jsonString =
        json.encode(allAnnotations.map((a) => a.toJson()).toList());

    // Créez une clé unique pour le document
    final annotationKey = 'saved_annotations_${widget.documentPath}';
    await prefs.setString(annotationKey, jsonString);
  }

  // Créez cette nouvelle méthode pour gérer les changements du contrôleur
  void _onPdfViewerControllerChanged() {
    setState(() {
      _currentTranslation = _pdfViewerController.scrollOffset;
      _currentScale = _pdfViewerController.zoomLevel;
    });
  }

  Offset _getTransformedPoint(Offset localPosition) {
    // Convertit la position du "taper" de l'écran en une position absolue dans le document PDF.
    // On annule le zoom et la translation.
    return (localPosition / _currentScale) + _currentTranslation;
  }

  Future<String?> _showTextInputDialog(Offset tapPosition) {
    final textController = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une annotation textuelle'),
          content: TextField(
            controller: textController,
            decoration:
                const InputDecoration(hintText: 'Saisissez votre texte'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(null), // Retourne null
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context)
                    .pop(textController.text); // Retourne le texte saisi
              },
            ),
          ],
        );
      },
    );
  }

  void _undoLastAnnotation() {
    if (_annotations.containsKey(_currentPage) &&
        _annotations[_currentPage]!.isNotEmpty) {
      // Crée une copie de la Map existante
      final updatedAnnotations =
          Map<int, List<my_annotations.Annotation>>.from(_annotations);

      // Crée une nouvelle liste sans la dernière annotation
      final updatedList = List<my_annotations.Annotation>.from(
          updatedAnnotations[_currentPage]!);
      updatedList.removeLast();

      // Met à jour la copie de la Map
      updatedAnnotations[_currentPage] = updatedList;

      // Met à jour l'état avec la nouvelle Map
      setState(() {
        _annotations = updatedAnnotations;
      });
      _saveAnnotations();
    }
  }

  void _setCurrentMode(AnnotationMode mode) {
    setState(() {
      _currentMode = mode;
      if (_currentMode == AnnotationMode.freehand) {
        _currentLine = my_annotations.FreehandAnnotation(
            points: [], pageIndex: _currentPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visionneuse de PDF'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.draw,
              color: _currentMode == AnnotationMode.freehand
                  ? Colors.blue
                  : Colors.black,
            ),
            onPressed: () => _setCurrentMode(
              _currentMode == AnnotationMode.freehand
                  ? AnnotationMode.none
                  : AnnotationMode.freehand,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.text_fields,
              color: _currentMode == AnnotationMode.text
                  ? Colors.blue
                  : Colors.black,
            ),
            onPressed: () => _setCurrentMode(
              _currentMode == AnnotationMode.text
                  ? AnnotationMode.none
                  : AnnotationMode.text,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoLastAnnotation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Le lecteur PDF est la seule couche active en mode normal.
          SfPdfViewer.memory(
            widget.pdfBytes,
            controller: _pdfViewerController,
            pageLayoutMode: PdfPageLayoutMode.continuous,
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            onZoomLevelChanged: (details) {
              setState(() {
                _currentScale = details.newZoomLevel;
              });
            },
          ),
          // La couche d'annotations est rendue UNIQUEMENT lorsque le mode d'annotation est actif.
          if (_currentMode != AnnotationMode.none)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: _currentMode == AnnotationMode.freehand
                    ? (details) {
                        _currentLine = my_annotations.FreehandAnnotation(
                          points: [_getTransformedPoint(details.localPosition)],
                          pageIndex: _currentPage,
                        );
                      }
                    : null,
                onPanUpdate: _currentMode == AnnotationMode.freehand
                    ? (details) {
                        final updatedPoints = List<Offset>.from(
                            _currentLine.points)
                          ..add(_getTransformedPoint(details.localPosition));
                        setState(() {
                          _currentLine = my_annotations.FreehandAnnotation(
                            points: updatedPoints,
                            pageIndex: _currentPage,
                          );
                        });
                      }
                    : null,
                onPanEnd: _currentMode == AnnotationMode.freehand
                    ? (details) {
                        if (_currentLine.points.isNotEmpty) {
                          final updatedAnnotations =
                              Map<int, List<my_annotations.Annotation>>.from(
                                  _annotations);
                          final updatedList =
                              List<my_annotations.Annotation>.from(
                                  updatedAnnotations[_currentPage] ?? []);
                          updatedList.add(_currentLine);
                          updatedAnnotations[_currentPage] = updatedList;

                          setState(() {
                            _annotations = updatedAnnotations;
                            _currentLine = my_annotations.FreehandAnnotation(
                                points: [], pageIndex: _currentPage);
                          });
                          _saveAnnotations();
                        }
                      }
                    : null,
                onTapUp: _currentMode == AnnotationMode.text
                    ? (details) async {
                        final enteredText =
                            await _showTextInputDialog(details.localPosition);
                        if (enteredText != null && enteredText.isNotEmpty) {
                          final newAnnotation = my_annotations.TextAnnotation(
                            text: enteredText,
                            position:
                                _getTransformedPoint(details.localPosition),
                            pageIndex: _currentPage,
                          );

                          final updatedAnnotations =
                              Map<int, List<my_annotations.Annotation>>.from(
                                  _annotations);
                          final updatedList =
                              List<my_annotations.Annotation>.from(
                                  updatedAnnotations[_currentPage] ?? []);
                          updatedList.add(newAnnotation);
                          updatedAnnotations[_currentPage] = updatedList;

                          setState(() {
                            _annotations = updatedAnnotations;
                          });
                          _saveAnnotations();
                        }
                      }
                    : null,
              ),
            ),
          RepaintBoundary(
            child: CustomPaint(
              painter: AnnotationPainter(
                annotations: _annotations,
                currentPage: _currentPage,
                currentLine: _currentLine,
                scale: _currentScale,
                translation: _currentTranslation,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
