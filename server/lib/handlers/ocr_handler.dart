import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:shelf/shelf.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../database/database.dart';

/// OCR 요청을 처리하는 핸들러
class OcrHandler {
  /// POST 요청을 처리하여 이미지에서 텍스트를 추출합니다.
  static Future<Response> handle(Request request) async {
    try {
      // 요청 본문 읽기
      final body = await request.read().expand((chunk) => chunk).toList();
      if (body.isEmpty) {
        return Response(400, body: 'No image data provided');
      }

      // 이미지 데이터를 base64로 인코딩
      final base64Image = base64Encode(body);

      // API 키 로드
      final apiKey = await Config.loadApiKey();
      final url = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
      
      final requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image
            },
            'features': [
              {
                'type': 'DOCUMENT_TEXT_DETECTION'
              }
            ],
            'imageContext': {
              'languageHints': ['ko', 'en']  // 한국어와 영어 지원
            }
          }
        ]
      };

      // API 호출
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        print('Error from Google Cloud Vision API: ${response.body}');
        return Response(500, body: 'Error from Google Cloud Vision API');
      }

      final responseData = jsonDecode(response.body);
      
      // 결과 처리
      if (responseData['responses'] == null || 
          responseData['responses'].isEmpty || 
          responseData['responses'][0]['fullTextAnnotation'] == null) {
        return Response(200, body: jsonEncode([]));
      }

      // 텍스트 추출
      final fullTextAnnotation = responseData['responses'][0]['fullTextAnnotation'];
      final extractedText = fullTextAnnotation['text'] as String;

      // 이미지 저장
      final imagesDir = Directory(join(Directory.current.path, 'images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create();
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = join(imagesDir.path, fileName);
      
      // 이미지 파일 저장
      await File(imagePath).writeAsBytes(body);
      
      // DB에 이미지 정보 저장
      await DatabaseHelper.saveImage(imagePath, extractedText);

      return Response(200,
        headers: {'content-type': 'application/json'},
        body: jsonEncode([extractedText]),
      );
    } catch (e) {
      print('Error processing OCR request: $e');
      return Response(500, body: 'Error processing image: $e');
    }
  }

  /// POST 요청을 처리하여 이미지에서 텍스트와 위치 정보를 추출합니다.
  static Future<Response> handleForm(Request request) async {
    try {
      // 요청 본문 읽기
      final body = await request.read().expand((chunk) => chunk).toList();
      if (body.isEmpty) {
        return Response(400, body: 'No image data provided');
      }

      // 이미지 데이터를 base64로 인코딩
      final base64Image = base64Encode(body);

      // API 키 로드
      final apiKey = await Config.loadApiKey();
      final url = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
      
      final requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image
            },
            'features': [
              {
                'type': 'TEXT_DETECTION'  // TEXT_DETECTION 사용
              }
            ],
            'imageContext': {
              'languageHints': ['ko', 'en']
            }
          }
        ]
      };

      // API 호출
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        print('Error from Google Cloud Vision API: ${response.body}');
        return Response(500, body: 'Error from Google Cloud Vision API');
      }

      final responseData = jsonDecode(response.body);
      
      // 결과 처리
      if (responseData['responses'] == null || 
          responseData['responses'].isEmpty || 
          responseData['responses'][0]['textAnnotations'] == null) {
        return Response(200, body: jsonEncode([]));
      }

      // 텍스트와 위치 정보 추출
      final textAnnotations = responseData['responses'][0]['textAnnotations'] as List;
      final result = textAnnotations.map((annotation) {
        return {
          'text': annotation['description'] as String,
          'boundingBox': annotation['boundingPoly']['vertices'] as List,
        };
      }).toList();

      // 이미지 저장
      final imagesDir = Directory(join(Directory.current.path, 'images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create();
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = join(imagesDir.path, fileName);
      
      // 이미지 파일 저장
      await File(imagePath).writeAsBytes(body);
      
      // DB에 이미지 정보 저장 (첫 번째 텍스트만 저장)
      if (result.isNotEmpty) {
        await DatabaseHelper.saveImage(imagePath, result[0]['text'] as String);
      }

      return Response(200,
        headers: {'content-type': 'application/json'},
        body: jsonEncode(result),
      );
    } catch (e) {
      print('Error processing OCR form request: $e');
      return Response(500, body: 'Error processing image: $e');
    }
  }
} 