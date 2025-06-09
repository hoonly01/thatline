// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OCRResult _$OCRResultFromJson(Map<String, dynamic> json) => OCRResult(
      text: json['text'] as String,
      annotations: (json['annotations'] as List<dynamic>?)
          ?.map((e) => TextAnnotation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OCRResultToJson(OCRResult instance) => <String, dynamic>{
      'text': instance.text,
      'annotations': instance.annotations,
    };

TextAnnotation _$TextAnnotationFromJson(Map<String, dynamic> json) =>
    TextAnnotation(
      text: json['text'] as String,
      boundingBox:
          BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TextAnnotationToJson(TextAnnotation instance) =>
    <String, dynamic>{
      'text': instance.text,
      'boundingBox': instance.boundingBox,
    };

BoundingBox _$BoundingBoxFromJson(Map<String, dynamic> json) => BoundingBox(
      vertices: (json['vertices'] as List<dynamic>)
          .map((e) => Vertex.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BoundingBoxToJson(BoundingBox instance) =>
    <String, dynamic>{
      'vertices': instance.vertices,
    };

Vertex _$VertexFromJson(Map<String, dynamic> json) => Vertex(
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
    );

Map<String, dynamic> _$VertexToJson(Vertex instance) => <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };
