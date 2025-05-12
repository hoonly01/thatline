import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:shelf_static/shelf_static.dart';
import '../lib/handlers/ocr_handler.dart';
import '../lib/handlers/image_handler.dart';
import '../lib/handlers/sentence_handler.dart';
import '../lib/swagger_ui.dart';

// 설정 파일에서 API 키를 읽어오는 함수
Future<String> _loadApiKey() async {
  try {
    final configFile = File('config.json');
    if (!await configFile.exists()) {
      throw Exception('config.json file not found');
    }
    
    final configContent = await configFile.readAsString();
    final config = jsonDecode(configContent) as Map<String, dynamic>;
    
    final apiKey = config['google_cloud_api_key'] as String?;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key not found in config.json');
    }
    
    return apiKey;
  } catch (e) {
    print('Error loading API key: $e');
    rethrow;
  }
}

// Swagger UI HTML 생성
String _generateSwaggerHtml() {
  return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="description" content="SwaggerUI" />
    <title>SwaggerUI</title>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui.css" />
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-bundle.js" crossorigin></script>
    <script>
        window.onload = () => {
            window.ui = SwaggerUIBundle({
                url: '/swagger/api.swagger',
                dom_id: '#swagger-ui',
                deepLinking: true,
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIBundle.SwaggerUIStandalonePreset
                ],
            });
        };
    </script>
</body>
</html>
''';
}

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..post('/ocr', OcrHandler.handle)
  ..post('/ocr/form', OcrHandler.handleForm)
  ..post('/sentences', SentenceHandler.saveSentence)
  ..get('/docs', (Request request) => Response.ok(SwaggerUI.generateHtml(), headers: {'content-type': 'text/html'}));

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

Future<Response> _ocrHandler(Request request) async {
  try {
    // 요청 본문 읽기
    final body = await request.read().expand((chunk) => chunk).toList();
    if (body.isEmpty) {
      return Response(400, body: 'No image data provided');
    }

    // 이미지 데이터를 base64로 인코딩
    final base64Image = base64Encode(body);

    // API 키 로드
    final apiKey = await _loadApiKey();
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

    // 텍스트 추출 및 반환
    final fullTextAnnotation = responseData['responses'][0]['fullTextAnnotation'];
    final extractedTexts = [fullTextAnnotation['text'] as String];

    return Response(200,
      headers: {'content-type': 'application/json'},
      body: jsonEncode(extractedTexts),
    );
  } catch (e) {
    print('Error processing OCR request: $e');
    return Response(500, body: 'Error processing image: $e');
  }
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // 정적 파일 서빙을 위한 핸들러 생성
  final staticHandler = createStaticHandler('.', defaultDocument: 'index.html');

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(Cascade()
          .add(staticHandler)
          .add(_router.call)
          .handler);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
  print('Swagger UI available at http://localhost:${server.port}/docs');
}
