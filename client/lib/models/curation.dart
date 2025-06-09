import 'package:json_annotation/json_annotation.dart';
import 'sentence.dart';

part 'curation.g.dart';

@JsonSerializable()
class Curation {
  final int id;
  final String title;
  final String description;
  final List<Sentence> sentences;
  final DateTime createdAt;
  final DateTime updatedAt;

  Curation({
    required this.id,
    required this.title,
    required this.description,
    required this.sentences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Curation.fromJson(Map<String, dynamic> json) => _$CurationFromJson(json);
  Map<String, dynamic> toJson() => _$CurationToJson(this);
} 