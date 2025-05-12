import 'dart:io';
import 'dart:convert';

/// 설정 관련 기능을 제공하는 클래스
class Config {
  /// 설정 파일에서 API 키를 읽어오는 함수
  static Future<String> loadApiKey() async {
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
} 