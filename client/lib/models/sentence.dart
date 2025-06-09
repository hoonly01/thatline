import 'package:json_annotation/json_annotation.dart';

part 'sentence.g.dart';

@JsonSerializable()
class Sentence {
  final String sentenceId;
  final String text;
  final String bookName;
  final String bookWriter;
  final String date;
  final String? imageUrl;

  Sentence({
    required this.sentenceId,
    required this.text,
    required this.bookName,
    required this.bookWriter,
    required this.date,
    this.imageUrl,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) => _$SentenceFromJson(json);
  Map<String, dynamic> toJson() => _$SentenceToJson(this);
} 