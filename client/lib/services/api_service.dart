import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/sentence.dart';
import '../models/curation.dart';
import '../models/ocr_result.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // OCR 텍스트 추출
  Future<List<String>> extractText(Uint8List imageBytes) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/ocr/text'),
        body: imageBytes,
        headers: {'Content-Type': 'application/octet-stream'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((text) => text.toString()).toList();
      } else {
        throw Exception('Failed to extract text: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error extracting text: $e');
    }
  }

  // OCR 폼 데이터 추출
  Future<List<OCRResult>> extractFormData(Uint8List imageBytes) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/ocr/form'),
        body: imageBytes,
        headers: {'Content-Type': 'application/octet-stream'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => OCRResult.fromJson(data)).toList();
      } else {
        throw Exception('Failed to extract form data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error extracting form data: $e');
    }
  }

  // 문장 저장
  Future<String> saveSentence(Sentence sentence) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/sentences'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(sentence.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['sentenceId'] as String;
      } else {
        throw Exception('Failed to save sentence: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving sentence: $e');
    }
  }

  // 모든 문장 조회
  Future<List<Sentence>> getAllSentences() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/sentences'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Sentence.fromJson(data)).toList();
      } else {
        throw Exception('Failed to get sentences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting sentences: $e');
    }
  }

  // 큐레이션 조회
  Future<Curation> getCuration(int curationId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/curation/$curationId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return Curation.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to get curation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting curation: $e');
    }
  }

  void dispose() {
    _client.close();
  }
} 