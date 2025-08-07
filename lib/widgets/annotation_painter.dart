import 'package:flutter/material.dart';
import 'package:music_pdf/models/annotation_models.dart' as my_annotations;

class AnnotationPainter extends CustomPainter {
  final Map<int, List<my_annotations.Annotation>> annotations;
  final int currentPage;
  final my_annotations.FreehandAnnotation currentLine; // Nouvel état pour le tracé en cours
  final double scale;
  final Offset translation;

  AnnotationPainter({
    required this.annotations,
    required this.currentPage,
    required this.currentLine,
    required this.scale,
    required this.translation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessine la ligne en cours de tracé si la page est la bonne
    if (currentLine.pageIndex == currentPage && currentLine.points.isNotEmpty) {
      _drawFreehandAnnotation(canvas, currentLine);
    }
    
    // Dessine toutes les annotations déjà sauvegardées
    if (annotations.containsKey(currentPage)) {
      final currentAnnotations = annotations[currentPage]!;
      for (final annotation in currentAnnotations) {
        if (annotation is my_annotations.FreehandAnnotation) {
          _drawFreehandAnnotation(canvas, annotation);
        } else if (annotation is my_annotations.TextAnnotation) {
          _drawTextAnnotation(canvas, annotation);
        }
      }
    }
  }

  void _drawFreehandAnnotation(Canvas canvas, my_annotations.FreehandAnnotation annotation) {
  final paint = Paint()
    ..color = Colors.red
    ..strokeWidth = 3.0 / scale
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final path = Path();
  if (annotation.points.isNotEmpty) {
    path.moveTo(
      (annotation.points.first.dx * scale) - translation.dx,
      (annotation.points.first.dy * scale) - translation.dy,
    );
    for (int i = 1; i < annotation.points.length; i++) {
      path.lineTo(
        (annotation.points[i].dx * scale) - translation.dx,
        (annotation.points[i].dy * scale) - translation.dy,
      );
    }
  }
  canvas.drawPath(path, paint);
}

  void _drawTextAnnotation(Canvas canvas, my_annotations.TextAnnotation annotation) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: annotation.text,
      style: TextStyle(
        color: annotation.textColor,
        fontSize: annotation.fontSize / scale,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  
  // Transforme la position absolue de l'annotation en une position relative à l'écran.
  // On applique le zoom et la translation.
  final Offset translatedPosition = Offset(
    (annotation.position.dx * scale) - translation.dx,
    (annotation.position.dy * scale) - translation.dy,
  );

  textPainter.paint(canvas, translatedPosition);
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    // Le peintre doit se redessiner si l'une des conditions suivantes est vraie
    return oldDelegate.annotations != annotations ||
           oldDelegate.currentPage != currentPage ||
           oldDelegate.currentLine != currentLine || // Ajout de la vérification de la ligne en cours
           oldDelegate.scale != scale ||
           oldDelegate.translation != translation;
  }
}