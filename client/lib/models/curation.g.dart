// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Curation _$CurationFromJson(Map<String, dynamic> json) => Curation(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      sentences: (json['sentences'] as List<dynamic>)
          .map((e) => Sentence.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CurationToJson(Curation instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'sentences': instance.sentences,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
