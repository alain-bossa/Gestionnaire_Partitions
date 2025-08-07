import 'package:flutter/material.dart';

abstract class Annotation {
  final int pageIndex;
  // Ajout d'une propriété pour le type d'annotation, utile pour la désérialisation
  final String type; 

  Annotation({required this.pageIndex, required this.type});

  // Méthode abstraite pour la sérialisation
  Map<String, dynamic> toJson();
}

class TextAnnotation extends Annotation {
  final String text;
  final Offset position;
  final Color textColor;
  final double fontSize;

  TextAnnotation({
    required this.text,
    required this.position,
    required super.pageIndex, // Ne pas utiliser 'this.' ici
    this.textColor = Colors.black,
    this.fontSize = 20.0,
  }) : super(type: 'text'); // Transmettez-le à la classe parente

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'pageIndex': pageIndex,
    'text': text,
    'position': {'dx': position.dx, 'dy': position.dy},
    // ignore: deprecated_member_use
    'textColor': textColor.value,
    'fontSize': fontSize,
  };

  static TextAnnotation fromJson(Map<String, dynamic> json) => TextAnnotation(
    text: json['text'],
    position: Offset(json['position']['dx'], json['position']['dy']),
    pageIndex: json['pageIndex'],
    textColor: Color(json['textColor']),
    fontSize: json['fontSize'],
  );
}

class FreehandAnnotation extends Annotation {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  FreehandAnnotation({
    required this.points,
    required super.pageIndex, // Ne pas utiliser 'this.' ici
    this.color = Colors.red,
    this.strokeWidth = 3.0,
  }) : super(type: 'freehand'); // Transmettez-le à la classe parente

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'pageIndex': pageIndex,
    'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    // ignore: deprecated_member_use
    'color': color.value,
    'strokeWidth': strokeWidth,
  };
  
  static FreehandAnnotation fromJson(Map<String, dynamic> json) => FreehandAnnotation(
    points: (json['points'] as List).map((p) => Offset(p['dx'], p['dy'])).toList(),
    pageIndex: json['pageIndex'],
    color: Color(json['color']),
    strokeWidth: json['strokeWidth'],
  );
}