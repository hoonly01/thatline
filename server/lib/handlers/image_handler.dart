import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../database/database.dart';

/// 이미지 관련 요청을 처리하는 핸들러
class ImageHandler {
  /// 모든 이미지 정보를 가져옵니다.
  static Future<Response> getAllImages(Request request) async {
    try {
      final images = await DatabaseHelper.getAllImages();
      return Response(200,
        headers: {'content-type': 'application/json'},
        body: jsonEncode(images),
      );
    } catch (e) {
      print('Error getting images: $e');
      return Response(500, body: 'Error getting images: $e');
    }
  }

  /// 특정 이미지 정보를 가져옵니다.
  static Future<Response> getImage(Request request) async {
    try {
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return Response(400, body: 'Invalid image ID');
      }

      final image = await DatabaseHelper.getImage(id);
      if (image == null) {
        return Response(404, body: 'Image not found');
      }

      return Response(200,
        headers: {'content-type': 'application/json'},
        body: jsonEncode(image),
      );
    } catch (e) {
      print('Error getting image: $e');
      return Response(500, body: 'Error getting image: $e');
    }
  }

  /// 이미지를 삭제합니다.
  static Future<Response> deleteImage(Request request) async {
    try {
      final id = int.tryParse(request.url.queryParameters['id'] ?? '');
      if (id == null) {
        return Response(400, body: 'Invalid image ID');
      }

      await DatabaseHelper.deleteImage(id);
      return Response(200, body: 'Image deleted successfully');
    } catch (e) {
      print('Error deleting image: $e');
      return Response(500, body: 'Error deleting image: $e');
    }
  }
} 