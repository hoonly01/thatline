import 'dart:io';
import 'package:flutter/services.dart';

/// On-device OCR Service using Apple Vision Framework (iOS)
///
/// iOS에서 Apple Vision Framework를 사용하여 이미지에서 텍스트를 인식합니다.
/// Android는 향후 Google ML Kit으로 구현 예정입니다.
class OnDeviceOCRService {
  /// Method Channel 이름
  static const _channelName = 'com.thatline/ocr';

  /// Method Channel 인스턴스
  static const _channel = MethodChannel(_channelName);

  /// 플랫폼 지원 여부 확인
  static bool get isSupported => Platform.isIOS;

  /// 기본 텍스트 인식
  ///
  /// [imagePath]: 로컬 이미지 파일 경로
  /// Returns: 인식된 텍스트 목록 (각 줄마다 하나씩)
  ///
  /// Example:
  /// ```dart
  /// final ocrService = OnDeviceOCRService();
  /// final texts = await ocrService.recognizeText('/path/to/image.jpg');
  /// print(texts.first); // "채식주의자"
  /// ```
  Future<List<String>> recognizeText(String imagePath) async {
    // 플랫폼 체크
    if (!isSupported) {
      throw UnsupportedError(
        'On-device OCR is only supported on iOS. Current platform: ${Platform.operatingSystem}',
      );
    }

    // 파일 존재 확인
    final file = File(imagePath);
    if (!await file.exists()) {
      throw OCRException(
        'Image file not found: $imagePath',
        code: 'FILE_NOT_FOUND',
      );
    }

    try {
      // Method Channel 호출
      final result = await _channel.invokeMethod('recognizeText', {
        'imagePath': imagePath,
      });

      // 결과 파싱
      if (result == null) {
        return [];
      }

      return List<String>.from(result);
    } on PlatformException catch (e) {
      // iOS Vision Framework 에러
      throw OCRException(
        e.message ?? 'OCR failed',
        code: e.code,
        details: e.details,
      );
    } catch (e) {
      // 예상치 못한 에러
      throw OCRException(
        'Unexpected OCR error: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// 위치 정보 포함 텍스트 인식 (고급 기능)
  ///
  /// [imagePath]: 로컬 이미지 파일 경로
  /// Returns: 인식된 텍스트 블록 목록 (텍스트 + 신뢰도 + 위치)
  ///
  /// Example:
  /// ```dart
  /// final blocks = await ocrService.recognizeTextWithBounds('/path/to/image.jpg');
  /// for (var block in blocks) {
  ///   print('${block.text} (신뢰도: ${block.confidence})');
  ///   print('위치: ${block.boundingBox}');
  /// }
  /// ```
  Future<List<RecognizedTextBlock>> recognizeTextWithBounds(
      String imagePath) async {
    if (!isSupported) {
      throw UnsupportedError(
        'On-device OCR is only supported on iOS. Current platform: ${Platform.operatingSystem}',
      );
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw OCRException(
        'Image file not found: $imagePath',
        code: 'FILE_NOT_FOUND',
      );
    }

    try {
      final result = await _channel.invokeMethod('recognizeTextWithBounds', {
        'imagePath': imagePath,
      });

      if (result == null) {
        return [];
      }

      final List<dynamic> blockList = result as List<dynamic>;
      return blockList
          .map((block) => RecognizedTextBlock.fromJson(block as Map))
          .toList();
    } on PlatformException catch (e) {
      throw OCRException(
        e.message ?? 'OCR with bounds failed',
        code: e.code,
        details: e.details,
      );
    } catch (e) {
      throw OCRException(
        'Unexpected OCR error: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// 여러 줄의 텍스트를 하나의 문자열로 결합
  ///
  /// [texts]: 텍스트 목록
  /// [separator]: 구분자 (기본값: 공백)
  ///
  /// Example:
  /// ```dart
  /// final texts = ['채식주의자', '한강'];
  /// final combined = ocrService.joinTexts(texts);
  /// // "채식주의자 한강"
  /// ```
  String joinTexts(List<String> texts, {String separator = ' '}) {
    return texts.join(separator).trim();
  }

  /// 첫 번째 줄만 추출 (제목, 대표 문장 등)
  ///
  /// [texts]: 텍스트 목록
  /// Returns: 첫 번째 텍스트 (없으면 null)
  String? getFirstLine(List<String> texts) {
    return texts.isEmpty ? null : texts.first;
  }

  /// 모든 줄을 줄바꿈으로 결합
  ///
  /// [texts]: 텍스트 목록
  /// Returns: 줄바꿈으로 결합된 텍스트
  String joinWithNewLines(List<String> texts) {
    return texts.join('\n').trim();
  }
}

/// OCR 예외 클래스
class OCRException implements Exception {
  /// 에러 메시지
  final String message;

  /// 에러 코드
  final String? code;

  /// 상세 정보
  final dynamic details;

  OCRException(this.message, {this.code, this.details});

  @override
  String toString() {
    if (code != null) {
      return 'OCRException [$code]: $message';
    }
    return 'OCRException: $message';
  }

  /// 사용자 친화적 에러 메시지
  String get userFriendlyMessage {
    switch (code) {
      case 'FILE_NOT_FOUND':
        return '이미지 파일을 찾을 수 없습니다';
      case 'INVALID_ARGUMENTS':
        return '잘못된 이미지 경로입니다';
      case 'OCR_ERROR':
        if (message.contains('noTextFound') ||
            message.contains('텍스트를 찾을 수 없습니다')) {
          return '이미지에서 텍스트를 찾을 수 없습니다.\n다른 이미지를 선택해주세요';
        }
        if (message.contains('invalidImage') ||
            message.contains('유효하지 않은 이미지')) {
          return '이미지를 읽을 수 없습니다.\n다른 이미지를 선택해주세요';
        }
        return '텍스트 인식에 실패했습니다';
      default:
        return '오류가 발생했습니다: $message';
    }
  }
}

/// 인식된 텍스트 블록 (텍스트 + 위치 정보)
class RecognizedTextBlock {
  /// 인식된 텍스트
  final String text;

  /// 신뢰도 (0.0 ~ 1.0)
  final double confidence;

  /// 텍스트 위치 (x, y, width, height)
  final BoundingBox boundingBox;

  RecognizedTextBlock({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });

  /// JSON에서 생성
  factory RecognizedTextBlock.fromJson(Map json) {
    return RecognizedTextBlock(
      text: json['text'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: BoundingBox.fromJson(json['boundingBox'] as Map),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'confidence': confidence,
      'boundingBox': boundingBox.toJson(),
    };
  }

  @override
  String toString() {
    return 'RecognizedTextBlock(text: "$text", confidence: ${confidence.toStringAsFixed(2)}, box: $boundingBox)';
  }
}

/// Bounding Box (텍스트 위치 정보)
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BoundingBox.fromJson(Map json) {
    return BoundingBox(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  @override
  String toString() {
    return 'BoundingBox(x: ${x.toStringAsFixed(1)}, y: ${y.toStringAsFixed(1)}, w: ${width.toStringAsFixed(1)}, h: ${height.toStringAsFixed(1)})';
  }
}
