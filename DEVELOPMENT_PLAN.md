# ThatLine iOS On-Device OCR 전환 개발 계획서

**작성일**: 2025-11-09
**프로젝트**: ThatLine (그때 그 문장)
**목표**: Google Cloud Vision API → Apple Vision Framework 전환
**방식**: Flutter + iOS Vision Framework (Method Channel)
**예상 기간**: 2-3일

---

## 📋 Executive Summary

### 현재 상황
- Google Cloud Vision API 사용 중 (서버 기반 OCR)
- 네트워크 의존성 + API 비용 발생
- 오프라인 사용 불가능

### 목표
- On-device AI로 전환 (Apple Vision Framework)
- 오프라인 OCR 지원
- API 비용 제거
- 응답 속도 개선 (2-3초 → 0.5-1초)

### 전략
- Flutter UI 100% 유지
- iOS Vision Framework를 Method Channel로 연결
- 기존 서버 OCR 엔드포인트는 fallback으로 보존

---

## 🎯 프로젝트 목표 (SMART)

| 항목 | 목표 |
|------|------|
| **Specific** | iOS에서 Apple Vision Framework 기반 On-device OCR 구현 |
| **Measurable** | 한국어 인식률 95%+, 처리 속도 1초 이내 |
| **Achievable** | 기존 Flutter 코드 유지, Method Channel 추가만으로 가능 |
| **Relevant** | 오프라인 지원 + 비용 절감 + 사용자 경험 개선 |
| **Time-bound** | 2-3일 내 완료 |

---

## 📊 현재 프로젝트 분석

### 코드베이스 현황
```
Client (Flutter):
├── lib/screens/camera_screen.dart      (189줄) ← OCR 호출 부분
├── lib/services/api_service.dart       (115줄) ← OCR API 클라이언트
├── lib/models/ocr_result.dart          (57줄)  ← 데이터 모델
└── 기타 UI 파일들 (약 900줄)

Server (Dart):
└── lib/handlers/ocr_handler.dart       (191줄) ← Google Vision API 호출

총 라인 수: ~1,244줄
```

### 현재 OCR 플로우
```
1. 사용자가 갤러리에서 이미지 선택
2. camera_screen.dart → 서버로 이미지 업로드
3. 서버 → Google Cloud Vision API 호출
4. 서버 → OCR 결과 반환
5. camera_screen.dart → 더미 데이터로 문장 저장 (!)

현재 문제: 실제 OCR 결과를 사용하지 않음
```

### 변경 대상 파일
```
수정:
  ✏️  ios/Runner/AppDelegate.swift         (Vision Framework 추가)
  ✏️  lib/services/api_service.dart         (새 메서드 추가)
  ✏️  lib/screens/camera_screen.dart        (OCR 호출 로직 변경)

신규:
  ➕ lib/services/on_device_ocr_service.dart (Method Channel 래퍼)
  ➕ ios/Runner/VisionOCRHandler.swift       (Vision Framework 구현)

선택적:
  🗑️  server/lib/handlers/ocr_handler.dart   (제거 or Fallback 유지)
```

---

## 🗓️ 세부 개발 일정

### **Day 1: iOS Native 구현** (6-8시간)

#### Phase 1.1: iOS Vision Framework 핸들러 구현 (3시간)
- [ ] VisionOCRHandler.swift 파일 생성
- [ ] VNRecognizeTextRequest 구현
- [ ] 한국어/영어 인식 설정
- [ ] Bounding Box 정보 추출 (선택)
- [ ] 에러 처리

**예상 코드:**
```swift
// ios/Runner/VisionOCRHandler.swift
import Vision
import UIKit

class VisionOCRHandler {
    func recognizeText(
        imagePath: String,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        guard let image = UIImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation]
            else {
                completion(.success([]))
                return
            }

            let texts = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            completion(.success(texts))
        }

        // 고정밀 인식 모드
        request.recognitionLevel = .accurate

        // 한국어 + 영어 우선
        request.recognitionLanguages = ["ko-KR", "en-US"]

        // 언어 교정 활성화
        request.usesLanguageCorrection = true

        // 최소 텍스트 높이 (작은 글씨 무시)
        request.minimumTextHeight = 0.02

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
}
```

#### Phase 1.2: Method Channel 연결 (2시간)
- [ ] AppDelegate.swift 수정
- [ ] FlutterMethodChannel 등록
- [ ] VisionOCRHandler 통합
- [ ] Flutter 결과 반환 포맷 정의

**예상 코드:**
```swift
// ios/Runner/AppDelegate.swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let ocrHandler = VisionOCRHandler()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        setupMethodChannels()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupMethodChannels() {
        guard let controller = window?.rootViewController as? FlutterViewController
        else { return }

        let ocrChannel = FlutterMethodChannel(
            name: "com.thatline/ocr",
            binaryMessenger: controller.binaryMessenger
        )

        ocrChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }

            switch call.method {
            case "recognizeText":
                self.handleRecognizeText(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func handleRecognizeText(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing imagePath", details: nil))
            return
        }

        ocrHandler.recognizeText(imagePath: imagePath) { ocrResult in
            switch ocrResult {
            case .success(let texts):
                result(texts)
            case .failure(let error):
                result(FlutterError(
                    code: "OCR_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }
}
```

#### Phase 1.3: 단위 테스트 (iOS) (1시간)
- [ ] Xcode에서 Swift 코드 컴파일 확인
- [ ] 샘플 이미지로 OCR 테스트
- [ ] 한국어 텍스트 인식 검증

---

### **Day 2: Flutter 통합** (6-8시간)

#### Phase 2.1: Flutter OCR Service 구현 (2시간)
- [ ] OnDeviceOCRService 클래스 생성
- [ ] Method Channel 래퍼 구현
- [ ] 에러 처리 및 예외 핸들링
- [ ] 플랫폼 감지 (iOS만 지원)

**예상 코드:**
```dart
// lib/services/on_device_ocr_service.dart
import 'dart:io';
import 'package:flutter/services.dart';

class OnDeviceOCRService {
  static const _channel = MethodChannel('com.thatline/ocr');

  /// 이미지에서 텍스트 인식
  ///
  /// [imagePath]: 로컬 이미지 파일 경로
  /// Returns: 인식된 텍스트 목록 (각 줄마다 하나씩)
  Future<List<String>> recognizeText(String imagePath) async {
    if (!Platform.isIOS) {
      throw UnsupportedError('On-device OCR is only supported on iOS');
    }

    try {
      final result = await _channel.invokeMethod('recognizeText', {
        'imagePath': imagePath,
      });

      if (result == null) {
        return [];
      }

      return List<String>.from(result);
    } on PlatformException catch (e) {
      throw OCRException(
        'Vision Framework error: ${e.message}',
        code: e.code,
        details: e.details,
      );
    } catch (e) {
      throw OCRException('Unexpected OCR error: $e');
    }
  }

  /// 여러 줄의 텍스트를 하나의 문자열로 결합
  String joinRecognizedTexts(List<String> texts, {String separator = ' '}) {
    return texts.join(separator).trim();
  }
}

class OCRException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  OCRException(this.message, {this.code, this.details});

  @override
  String toString() => 'OCRException: $message';
}
```

#### Phase 2.2: Camera Screen 수정 (3시간)
- [ ] OnDeviceOCRService 통합
- [ ] _uploadImage 메서드 리팩토링
- [ ] 실제 OCR 결과로 문장 저장 (더미 데이터 제거)
- [ ] 로딩 상태 개선
- [ ] 에러 처리 개선

**예상 코드:**
```dart
// lib/screens/camera_screen.dart (수정)
import 'package:thatline_client/services/on_device_ocr_service.dart';

class _CameraScreenState extends State<CameraScreen> {
  final _ocrService = OnDeviceOCRService();

  Future<void> _uploadImage(File imageFile) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1️⃣ On-device OCR 실행
      final recognizedTexts = await _ocrService.recognizeText(imageFile.path);

      if (recognizedTexts.isEmpty) {
        throw Exception('이미지에서 텍스트를 찾을 수 없습니다');
      }

      // 2️⃣ 첫 번째 줄을 문장으로 사용 (또는 전체 텍스트)
      final extractedText = recognizedTexts.first;

      // 3️⃣ 문장 편집 다이얼로그 표시 (사용자가 수정 가능)
      final editedText = await _showEditDialog(extractedText);

      if (editedText == null || editedText.isEmpty) {
        // 사용자가 취소함
        return;
      }

      // 4️⃣ 서버에 문장 저장
      final sentenceData = {
        'sentenceId': 'ocr-${DateTime.now().millisecondsSinceEpoch}',
        'text': editedText,
        'bookName': '스캔한 책',  // 나중에 입력받도록 개선 가능
        'bookWriter': '작가 미상',
        'date': DateTime.now().toIso8601String(),
        'imageUrl': '',
      };

      final response = await http.post(
        Uri.parse('http://localhost:8080/sentences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sentenceData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog('문장이 저장되었습니다: "$editedText"');
      } else {
        throw Exception('문장 저장 실패: ${response.statusCode}');
      }
    } on OCRException catch (e) {
      _showErrorDialog('텍스트 인식 실패: ${e.message}');
    } catch (e) {
      _showErrorDialog('오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// OCR 결과를 사용자가 편집할 수 있는 다이얼로그
  Future<String?> _showEditDialog(String initialText) async {
    final controller = TextEditingController(text: initialText);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인식된 문장'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '필요시 수정하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
```

#### Phase 2.3: API Service 업데이트 (1시간)
- [ ] extractText 메서드 deprecated 마킹
- [ ] 주석 업데이트
- [ ] Fallback 로직 추가 (선택)

---

### **Day 3: 테스트 및 최적화** (4-6시간)

#### Phase 3.1: 통합 테스트 (2시간)
- [ ] iOS Simulator에서 앱 실행
- [ ] 갤러리에서 이미지 선택 → OCR 테스트
- [ ] 한국어 책 사진으로 테스트
- [ ] 영어 텍스트 테스트
- [ ] 에러 케이스 테스트 (빈 이미지, 텍스트 없음 등)

**테스트 시나리오:**
```
✅ TC-001: 한국어 책 표지 인식
   입력: 한강 작가의 "채식주의자" 표지
   예상: "채식주의자", "한강" 인식

✅ TC-002: 한국어 본문 인식
   입력: 책 본문 사진
   예상: 문장 정확히 추출

✅ TC-003: 영어 텍스트 인식
   입력: 영어 책 사진
   예상: 영어 문장 인식

✅ TC-004: 텍스트 없는 이미지
   입력: 풍경 사진
   예상: "텍스트를 찾을 수 없습니다" 에러 메시지

✅ TC-005: 저화질 이미지
   입력: 흐릿한 사진
   예상: 부분적으로라도 인식 or 적절한 에러
```

#### Phase 3.2: UI/UX 개선 (2시간)
- [ ] 로딩 인디케이터 개선
- [ ] OCR 진행 상태 표시 ("텍스트 인식 중...")
- [ ] 성공 메시지 개선
- [ ] 에러 메시지 사용자 친화적으로 수정

**개선 사항:**
```dart
// 로딩 상태 개선
Widget _buildLoadingOverlay() {
  return Container(
    color: Colors.black54,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            '책 속 문장을 읽고 있어요...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    ),
  );
}
```

#### Phase 3.3: 성능 최적화 (1시간)
- [ ] 이미지 압축 (필요시)
- [ ] OCR 결과 캐싱 (선택)
- [ ] 메모리 누수 확인

---

### **Day 4: 서버 정리 및 배포 준비** (선택, 2-3시간)

#### Phase 4.1: 서버 정리 (1시간)
- [ ] OCR 엔드포인트 제거 OR
- [ ] Fallback으로 유지 (네트워크 오류 시 사용)
- [ ] 문서화 업데이트

**선택지:**
```dart
// Option 1: 완전 제거
// server/lib/handlers/ocr_handler.dart 삭제
// server/bin/server.dart에서 라우트 제거

// Option 2: Fallback 유지
Future<List<String>> recognizeText(String imagePath) async {
  try {
    // 1순위: On-device OCR
    return await _ocrService.recognizeText(imagePath);
  } catch (e) {
    // 2순위: 서버 OCR (네트워크 필요)
    return await _apiService.extractText(imageBytes);
  }
}
```

#### Phase 4.2: 빌드 최적화 (1시간)
- [ ] flutter build ios --release 실행
- [ ] 앱 크기 확인 (< 50MB 목표)
- [ ] 불필요한 의존성 제거
- [ ] Assets 최적화

```bash
# 빌드 크기 분석
flutter build ios --release --analyze-size

# 예상 결과:
# Flutter Engine: 35MB
# Dart AOT: 3MB
# Assets: 5-10MB
# Total: 43-48MB ✅
```

#### Phase 4.3: App Store 준비 (1시간)
- [ ] Application ID 변경 (com.example.thatline_client → 실제 ID)
- [ ] 릴리즈 서명 설정
- [ ] Privacy Manifest 추가 (iOS 17+)
- [ ] App Store Connect 정보 준비

---

## 🧪 테스트 계획

### Unit Tests
```dart
// test/services/on_device_ocr_service_test.dart
void main() {
  group('OnDeviceOCRService', () {
    test('should throw UnsupportedError on non-iOS platform', () {
      // Test implementation
    });

    test('should handle empty recognition results', () {
      // Test implementation
    });
  });
}
```

### Integration Tests
```dart
// integration_test/ocr_flow_test.dart
void main() {
  testWidgets('Complete OCR flow', (tester) async {
    // 1. 앱 실행
    // 2. 카메라 화면 이동
    // 3. 이미지 선택
    // 4. OCR 결과 확인
    // 5. 문장 저장 확인
  });
}
```

### Manual Tests (iOS Simulator)
- [ ] iPhone 15 Pro Simulator
- [ ] iPhone SE Simulator (작은 화면)
- [ ] iPad Simulator
- [ ] 다크모드 테스트

---

## ⚠️ 위험 요소 및 대응 방안

### 위험 1: Vision Framework 인식률 낮음
**확률**: 낮음 (10%)
**영향**: 높음
**대응**:
- VNRecognizeTextRequest 파라미터 튜닝
- `recognitionLevel = .accurate` 사용
- `customWords` 추가 (자주 나오는 책 제목/작가명)
- Fallback으로 Google Vision API 유지

### 위험 2: Method Channel 통신 오류
**확률**: 중간 (30%)
**영향**: 높음
**대응**:
- 상세한 에러 로깅
- Try-catch로 모든 예외 처리
- 사용자 친화적 에러 메시지
- 재시도 로직 추가

### 위험 3: 이미지 형식 호환성 문제
**확률**: 낮음 (15%)
**영향**: 중간
**대응**:
- UIImage → CGImage 변환 실패 처리
- 지원 형식 명시 (JPG, PNG, HEIC)
- 이미지 전처리 (회전, 크기 조정)

### 위험 4: iOS 버전 호환성
**확률**: 낮음 (10%)
**영향**: 중간
**대응**:
- iOS 13+ 타겟 (Vision Framework 안정화)
- Deployment Target 확인
- 구버전 iOS에서 기능 제한 안내

---

## 📦 배포 체크리스트

### 코드 품질
- [ ] 모든 TODO 주석 해결
- [ ] Dead code 제거
- [ ] 하드코딩된 URL 환경변수화
- [ ] 로그 레벨 조정 (DEBUG → INFO)

### 보안
- [ ] API 키 노출 확인 (config.json 제외)
- [ ] .gitignore 업데이트
- [ ] Privacy Manifest 추가
- [ ] Camera/Photo Library 권한 설명 추가

### 성능
- [ ] 메모리 프로파일링
- [ ] 앱 시작 시간 측정 (< 2초)
- [ ] OCR 처리 시간 측정 (< 1.5초)

### 문서화
- [ ] README.md 업데이트
- [ ] CHANGELOG.md 작성
- [ ] API 문서 업데이트
- [ ] 아키텍처 다이어그램 추가

---

## 📈 성공 지표 (KPI)

| 지표 | 현재 (Cloud) | 목표 (On-device) |
|------|--------------|------------------|
| **OCR 처리 시간** | 2-3초 | < 1초 |
| **오프라인 지원** | ❌ | ✅ |
| **월간 API 비용** | $X | $0 |
| **앱 크기** | 43MB | < 50MB |
| **한국어 인식률** | 98% | > 95% |
| **사용자 만족도** | - | 4.5+/5.0 |

---

## 🎯 마일스톤

```
✅ M1: 개발 계획 수립                    [Day 0]
⬜ M2: iOS Vision Framework 구현         [Day 1]
⬜ M3: Flutter 통합 완료                [Day 2]
⬜ M4: 테스트 통과                      [Day 3]
⬜ M5: App Store 제출 준비              [Day 4]
```

---

## 📞 의사결정 포인트

### Decision Point 1: 서버 OCR 처리 (Day 2)
**질문**: 기존 서버 OCR 엔드포인트를 어떻게 할 것인가?
**옵션**:
- A) 완전 제거 (권장)
- B) Fallback으로 유지
- C) 사용자 설정으로 선택 가능

**권장**: B) Fallback 유지 (안전성)

### Decision Point 2: OCR 결과 편집 (Day 2)
**질문**: 사용자가 OCR 결과를 편집할 수 있어야 하는가?
**옵션**:
- A) 자동 저장 (편집 불가)
- B) 편집 다이얼로그 표시 (권장)
- C) 전용 편집 화면

**권장**: B) 편집 다이얼로그

---

## 📚 참고 자료

### Apple 공식 문서
- [Vision Framework Documentation](https://developer.apple.com/documentation/vision)
- [VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)
- [Text Recognition Best Practices](https://developer.apple.com/documentation/vision/recognizing_text_in_images)

### Flutter 문서
- [Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [Method Channel](https://api.flutter.dev/flutter/services/MethodChannel-class.html)

### 코드 예제
- [flutter/samples - platform_channels](https://github.com/flutter/samples/tree/main/platform_channels)

---

## 🚀 시작 준비

### 개발 환경 확인
```bash
# Flutter 버전
flutter --version
# Flutter 3.2.3+ 필요

# iOS 개발 환경
xcodebuild -version
# Xcode 15+ 권장

# CocoaPods
pod --version

# iOS Simulator 확인
xcrun simctl list devices
```

### 프로젝트 초기화
```bash
cd /home/user/thatline/client

# 의존성 설치
flutter pub get

# iOS 의존성
cd ios && pod install && cd ..

# 빌드 테스트
flutter build ios --debug
```

---

## ✅ 다음 단계

1. **이 개발 계획서 승인 받기**
2. **Day 1 작업 시작**: iOS Vision Framework 구현
3. **일일 진행 상황 보고**
4. **완료 후 테스트 결과 공유**

---

**작성자**: Claude Code
**검토 필요**: 프로젝트 리더
**상태**: 승인 대기 중
