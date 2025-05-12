import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../database/database.dart';

/// 문장 관련 요청을 처리하는 핸들러
class SentenceHandler {
  /// 문장을 저장합니다.
  static Future<Response> saveSentence(Request request) async {
    try {
      // 요청 본문 읽기
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // 필수 필드 검증
      final requiredFields = ['sentenceId', 'text', 'bookName', 'bookWriter', 'date'];
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null) {
          return Response(400, body: 'Missing required field: $field');
        }
      }

      // 문장 저장
      final sentenceId = await DatabaseHelper.saveSentence(
        sentenceId: data['sentenceId'] as String,
        text: data['text'] as String,
        bookName: data['bookName'] as String,
        bookWriter: data['bookWriter'] as String,
        date: data['date'] as String,
        imageUrl: data['imageUrl'] as String?,
      );

      // 응답 반환
      return Response(200,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'status': 'ok',
          'uuid': sentenceId,
        }),
      );
    } catch (e) {
      print('Error saving sentence: $e');
      if (e.toString().contains('already exists')) {
        return Response(409, body: e.toString());
      }
      return Response(500, body: 'Error saving sentence: $e');
    }
  }
} 