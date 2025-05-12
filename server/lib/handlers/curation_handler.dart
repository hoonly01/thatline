import 'package:shelf/shelf.dart';
import 'dart:convert';
import '../database/database.dart';

/// 큐레이션 관련 요청을 처리하는 핸들러
class CurationHandler {
  /// 특정 큐레이션의 상세 정보를 가져옵니다.
  static Future<Response> getCuration(Request request) async {
    try {
      // URL에서 curationId 추출
      final curationId = int.tryParse(request.url.pathSegments.last);
      if (curationId == null) {
        return Response(400, body: 'Invalid curation ID');
      }

      // 큐레이션 정보 조회
      final curation = await DatabaseHelper.getCuration(curationId);
      if (curation == null) {
        return Response(404, body: 'Curation not found');
      }

      // 응답 반환
      return Response(200,
        headers: {'content-type': 'application/json'},
        body: jsonEncode(curation),
      );
    } catch (e) {
      print('Error getting curation: $e');
      return Response(500, body: 'Error getting curation: $e');
    }
  }
} 