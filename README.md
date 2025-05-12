# 그때 그 문장
# ThatLine: Capture Your Literary Moments
# Spring 2025 FSSN

ThatLine은 독서 기록과 큐레이션을 위한 서비스입니다. OCR을 활용한 문장 추출, 문장 저장, 큐레이션 기능을 제공합니다.

## 기능

- **OCR 텍스트 추출**
  - 이미지에서 텍스트 추출 (`/ocr/text`)
  - 폼 데이터로 이미지 업로드 및 텍스트 추출 (`/ocr/form`)

- **문장 관리**
  - 문장 저장 (`POST /sentences`)
  - 저장된 문장 목록 조회 (`GET /sentences`)

- **큐레이션**
  - 큐레이션 상세 정보 조회 (`GET /curation/{curationId}`)
  - 도서 추천 리스트, 큐레이션 설명, 작성 큐레이터(서점) 정보 제공

## 기술 스택

- **Backend**: Dart
- **Database**: SQLite
- **OCR**: Google Cloud Vision API
- **API Documentation**: Swagger UI

## 시작하기

### 필수 조건

- Dart SDK
- Google Cloud Vision API 키

### 설치

1. 저장소 클론
```bash
git clone [repository-url]
cd thatline
```

2. 의존성 설치
```bash
dart pub get
```

3. 설정 파일 생성
`config.json` 파일을 생성하고 Google Cloud Vision API 키를 설정합니다:
```json
{
  "google_cloud_api_key": "your-api-key"
}
```

### 실행

서버 실행:
```bash
dart run bin/server.dart
```

서버는 기본적으로 `http://localhost:8080`에서 실행됩니다.

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
