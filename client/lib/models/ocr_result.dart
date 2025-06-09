import 'package:json_annotation/json_annotation.dart';

part 'ocr_result.g.dart';

@JsonSerializable()
class OCRResult {
  final String text;
  final List<TextAnnotation>? annotations;

  OCRResult({
    required this.text,
    this.annotations,
  });

  factory OCRResult.fromJson(Map<String, dynamic> json) => _$OCRResultFromJson(json);
  Map<String, dynamic> toJson() => _$OCRResultToJson(this);
}

@JsonSerializable()
class TextAnnotation {
  final String text;
  final BoundingBox boundingBox;

  TextAnnotation({
    required this.text,
    required this.boundingBox,
  });

  factory TextAnnotation.fromJson(Map<String, dynamic> json) => _$TextAnnotationFromJson(json);
  Map<String, dynamic> toJson() => _$TextAnnotationToJson(this);
}

@JsonSerializable()
class BoundingBox {
  final List<Vertex> vertices;

  BoundingBox({
    required this.vertices,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) => _$BoundingBoxFromJson(json);
  Map<String, dynamic> toJson() => _$BoundingBoxToJson(this);
}

@JsonSerializable()
class Vertex {
  final int x;
  final int y;

  Vertex({
    required this.x,
    required this.y,
  });

  factory Vertex.fromJson(Map<String, dynamic> json) => _$VertexFromJson(json);
  Map<String, dynamic> toJson() => _$VertexToJson(this);
} 