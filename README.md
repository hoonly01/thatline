<div align="center">
  <h1>📚 ThatLine - Capture Your Literary Moments</h1>
  <h3>그때 그 문장 | Spring 2025 FSSN</h3>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev/)

  <p>ThatLine은 독서 기록과 큐레이션을 위한 서비스입니다. OCR을 활용한 문장 추출, 문장 저장, 큐레이션 기능을 제공합니다.</p>
</div>

## ✨ 주요 기능

### 📸 OCR 텍스트 추출
- 카메라 또는 갤러리에서 이미지 선택
- Google Cloud Vision API를 활용한 정확한 텍스트 인식
- 추출된 텍스트에서 문장 자동 분리

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
- Flutter 3.0+
- Dart 3.0+
- Provider (상태 관리)
- Dio (HTTP 클라이언트)

### 백엔드
- Dart with Shelf
- SQLite (데이터베이스)
- Google Cloud Vision API (OCR)
- JWT (인증)

## 🚀 시작하기

### 필수 조건

- Flutter SDK (3.0.0 이상)
- Dart SDK (3.0.0 이상)
- Google Cloud Vision API 키

### 설치

1. 저장소 클론
```bash
git clone [repository-url]
cd thatline
```

2. 의존성 설치
```bash
# 프론트엔드
cd client
flutter pub get

# 백엔드
cd ../server
dart pub get
```

3. 설정 파일 생성

`config.json` 파일 생성:
```json
{
  "google_cloud_api_key": "your-google-cloud-api-key"
}
```

4. 애플리케이션 실행

프론트엔드:
```bash
cd client
flutter run
```

백엔드:
```bash
cd server
dart run bin/server.dart
```

서버는 기본적으로 `http://localhost:8080`에서 실행됩니다.

## 📚 API 문서

Swagger UI를 통해 API 문서를 확인할 수 있습니다:
```
http://localhost:8080/docs
```

### 📡 주요 API 엔드포인트

#### 🔍 OCR
- `POST /ocr/text`: 이미지에서 텍스트 추출
- `POST /ocr/form`: 폼 데이터로 이미지 업로드 및 텍스트 추출

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

## 📧 문의

문의사항이 있으시면 [your-email@example.com](mailto:your-email@example.com)으로 이메일을 보내주세요.

## API 문서

Swagger UI를 통해 API 문서를 확인할 수 있습니다:
```
http://localhost:8080/docs
```

### 주요 API 엔드포인트

#### OCR
- `POST /ocr/text`: 이미지에서 텍스트 추출
- `POST /ocr/form`: 폼 데이터로 이미지 업로드 및 텍스트 추출

#### 문장
- `GET /sentences`: 저장된 문장 목록 조회
- `POST /sentences`: 새 문장 저장
  ```json
  {
    "sentenceId": "string",
    "text": "string",
    "bookName": "string",
    "bookWriter": "string",
    "date": "string",
    "imageUrl": "string" // optional
  }
  ```

#### 큐레이션
- `GET /curation/{curationId}`: 큐레이션 상세 정보 조회
  ```json
  {
    "title": "string",
    "subtitle": "string",
    "image": "string",
    "description": "string",
    "recommenderTitle": "string",
    "recommenderLocation": {
      "name": "string",
      "latitude": "number",
      "longitude": "number"
    },
    "books": [
      {
        "id": "number",
        "name": "string",
        "writer": "string",
        "summary": "string",
        "image": "string"
      }
    ]
  }
  ```

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

## 라이선스

[라이선스 정보]

## 기여

[기여 방법]
