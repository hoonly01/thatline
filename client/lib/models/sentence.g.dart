// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sentence _$SentenceFromJson(Map<String, dynamic> json) => Sentence(
      sentenceId: json['sentenceId'] as String,
      text: json['text'] as String,
      bookName: json['bookName'] as String,
      bookWriter: json['bookWriter'] as String,
      date: json['date'] as String,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$SentenceToJson(Sentence instance) => <String, dynamic>{
      'sentenceId': instance.sentenceId,
      'text': instance.text,
      'bookName': instance.bookName,
      'bookWriter': instance.bookWriter,
      'date': instance.date,
      'imageUrl': instance.imageUrl,
    };
