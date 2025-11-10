<div align="center">
  <h1>📚 ThatLine - Capture Your Literary Moments</h1>
  <h3>그때 그 문장 | Spring 2025 FSSN</h3>

  [![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev/)
  [![iOS](https://img.shields.io/badge/iOS-13.0+-000000?logo=apple)](https://www.apple.com/ios/)

  <p>ThatLine은 독서 기록과 큐레이션을 위한 서비스입니다. <strong>On-device AI OCR</strong>을 활용한 문장 추출, 문장 저장, 큐레이션 기능을 제공합니다.</p>
</div>

## ✨ 주요 기능

### 📸 On-Device OCR 텍스트 추출 ⚡
- **오프라인 지원**: 인터넷 연결 없이 사용 가능
- **빠른 처리**: 0.5-1초 내 텍스트 인식 (기존 대비 3배 향상)
- **Apple Vision Framework**: iOS에 최적화된 고정밀 한국어/영어 인식
- 갤러리에서 이미지 선택 후 즉시 처리
- 인식된 문장 편집 및 책 정보 입력 가능

### 📚 문장 관리
- 마음에 드는 문장 저장
- 북마크 및 태그 기능
- 검색 기능으로 빠르게 찾기

### 🌟 큐레이션
- 테마별 문장 모음
- 도서 추천 리스트
- 서점/도서관 큐레이션

## 🛠 기술 스택

### 프론트엔드
- **Flutter 3.0+**: 크로스 플랫폼 UI 프레임워크
- **Dart 3.0+**: 프로그래밍 언어
- **Apple Vision Framework**: iOS On-device OCR (네이티브)
- **Provider**: 상태 관리
- **UUID**: 고유 식별자 생성

### 백엔드
- **Dart with Shelf**: 서버 프레임워크
- **SQLite**: 로컬 데이터베이스
- **JWT**: 인증 (예정)

### 플랫폼 지원
- ✅ **iOS 13.0+**: 완전 지원 (On-device OCR)
- 🚧 **Android**: 서버 OCR Fallback (향후 Google ML Kit 지원 예정)

## 🚀 시작하기

### 필수 조건

#### iOS 개발 (권장)
- **macOS**: Xcode 개발용
- **Flutter SDK**: 3.0.0 이상
- **Xcode**: 15.0 이상
- **iOS Simulator** 또는 **실제 iPhone** (iOS 13.0+)

#### 백엔드
- **Dart SDK**: 3.0.0 이상

### 설치

1. **저장소 클론**
```bash
git clone https://github.com/hoonly01/thatline.git
cd thatline
```

2. **의존성 설치**
```bash
# Flutter 앱
cd client
flutter pub get

# iOS 의존성 (macOS에서만)
cd ios
pod install
cd ..

# 백엔드
cd ../server
dart pub get
```

3. **애플리케이션 실행**

**iOS 앱 (On-device OCR):**
```bash
cd client
flutter run -d ios
```

또는 Xcode에서:
```bash
open ios/Runner.xcworkspace
```

**백엔드 서버 (선택):**
```bash
cd server
dart run bin/server.dart
```
서버는 `http://localhost:8080`에서 실행됩니다.

> **참고**: iOS에서 On-device OCR을 사용하므로 백엔드 서버 없이도 OCR 기능이 작동합니다.

## 📚 API 문서

Swagger UI를 통해 API 문서를 확인할 수 있습니다:
```
http://localhost:8080/docs
```

### 📡 주요 API 엔드포인트

#### 🔍 OCR (Fallback용 - Android 등)
- `POST /ocr/text`: 이미지에서 텍스트 추출 (서버 기반)
- `POST /ocr/form`: 폼 데이터로 이미지 업로드 및 텍스트 추출

> **참고**: iOS는 On-device OCR을 사용하므로 서버 OCR 엔드포인트를 호출하지 않습니다.

#### 📝 문장
- `GET /sentences`: 저장된 문장 목록 조회
- `POST /sentences`: 새 문장 저장
  ```json
  {
    "sentenceId": "string",
    "text": "string",
    "bookName": "string",
    "bookWriter": "string",
    "date": "string",
    "imageUrl": "string"
  }
  ```

#### 🎨 큐레이션
- `GET /curation/{curationId}`: 큐레이션 상세 정보 조회
  ```json
  {
    "title": "string",
    "subtitle": "string",
    "image": "string",
    "description": "string",
    "recommenderTitle": "string",
    "recommenderLocation": {
      "latitude": 0,
      "longitude": 0
    },
    "books": [
      {
        "title": "string",
        "author": "string",
        "coverImage": "string"
      }
    ]
  }
  ```

## 🤝 기여 방법

1. 이 저장소를 포크하세요.
2. 새로운 기능 브랜치를 만드세요: `git checkout -b feature/amazing-feature`
3. 변경사항을 커밋하세요: `git commit -m 'Add some amazing feature'`
4. 브랜치에 푸시하세요: `git push origin feature/amazing-feature`
5. 풀 리퀘스트를 오픈하세요.

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 🎯 기술적 하이라이트

### On-Device OCR 구현
- **Apple Vision Framework**: VNRecognizeTextRequest 사용
- **Thread Safety**: DispatchQueue.main.async로 모든 콜백 처리
- **Method Channel**: Flutter ↔ iOS Native 통신
- **고정밀 인식**: `.accurate` 모드 + 한국어/영어 우선 설정
- **에러 처리**: 사용자 친화적 한국어 메시지

### 성능 최적화
- **OCR 처리 시간**: 0.5-1초 (기존 2-3초 대비 3배 향상)
- **오프라인 지원**: 네트워크 불필요
- **API 비용**: $0 (기존 월 $X 절감)
- **앱 크기**: 약 45MB (Vision Framework는 iOS 내장)

### 코드 품질
- **UUID v4**: 충돌 없는 고유 ID 생성
- **Safe Casting**: guard let으로 크래시 방지
- **Exception Handling**: code, details 정보 보존
- **Fallback**: iOS 외 플랫폼은 서버 OCR 자동 전환

---

## 📧 문의 및 기여

### 문의
프로젝트 관련 문의는 [Issue](https://github.com/hoonly01/thatline/issues)를 통해 남겨주세요.

### 기여 방법
1. 이 저장소를 포크하세요
2. 새로운 기능 브랜치를 만드세요: `git checkout -b feature/amazing-feature`
3. 변경사항을 커밋하세요: `git commit -m 'Add amazing feature'`
4. 브랜치에 푸시하세요: `git push origin feature/amazing-feature`
5. Pull Request를 오픈하세요

---

## 데이터베이스 스키마

### images
- `id`: INTEGER PRIMARY KEY
- `image_path`: TEXT
- `text_content`: TEXT
- `created_at`: TIMESTAMP

### sentences
- `id`: INTEGER PRIMARY KEY
- `sentence_id`: TEXT UNIQUE
- `text`: TEXT
- `book_name`: TEXT
- `book_writer`: TEXT
- `date`: TEXT
- `image_url`: TEXT
- `created_at`: TIMESTAMP

### curations
- `id`: INTEGER PRIMARY KEY
- `title`: TEXT
- `subtitle`: TEXT
- `image`: TEXT
- `description`: TEXT
- `recommender_title`: TEXT
- `recommender_name`: TEXT
- `recommender_latitude`: REAL
- `recommender_longitude`: REAL
- `created_at`: TIMESTAMP

### books
- `id`: INTEGER PRIMARY KEY
- `name`: TEXT
- `writer`: TEXT
- `summary`: TEXT
- `image`: TEXT
- `created_at`: TIMESTAMP

### curation_books
- `curation_id`: INTEGER
- `book_id`: INTEGER
- `created_at`: TIMESTAMP
- PRIMARY KEY (curation_id, book_id)
- FOREIGN KEY (curation_id) REFERENCES curations (id)
- FOREIGN KEY (book_id) REFERENCES books (id)

---

## 📚 추가 문서

- [개발 계획](./DEVELOPMENT_PLAN.md) - 3일 개발 일정 및 구현 가이드
- [기술 증명](./PROOF_OF_CONCEPT.md) - Flutter + Vision Framework 호환성 증명
- [구현 요약](./IMPLEMENTATION_SUMMARY.md) - 상세 구현 보고서
- [코드 리뷰 응답](./CODE_REVIEW_RESPONSE.md) - PR #8 코드 리뷰 대응

---

<div align="center">
  <p>Made with ❤️ by ThatLine Team</p>
  <p>Spring 2025 FSSN Project</p>
</div>
