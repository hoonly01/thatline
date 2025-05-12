/// Swagger UI 관련 기능을 제공하는 클래스
import 'dart:convert';

class SwaggerUI {
  /// Swagger UI HTML을 생성합니다.
  static String generateHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="description" content="ThatLine API Documentation" />
    <title>ThatLine API Documentation</title>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui.css" />
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-bundle.js" crossorigin></script>
    <script>
        window.onload = () => {
            window.ui = SwaggerUIBundle({
                spec: ${jsonEncode(_generateSwaggerSpec())},
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

  static Map<String, dynamic> _generateSwaggerSpec() {
    return {
      "openapi": "3.0.0",
      "info": {
        "title": "ThatLine API",
        "version": "1.0.0",
        "description": "ThatLine 서비스의 API 문서"
      },
      "servers": [
        {
          "url": "http://localhost:8080",
          "description": "로컬 개발 서버"
        }
      ],
      "paths": {
        "/ocr/text": {
          "post": {
            "summary": "이미지에서 텍스트 추출",
            "description": "이미지를 업로드하여 텍스트를 추출합니다.",
            "requestBody": {
              "required": true,
              "content": {
                "image/*": {
                  "schema": {
                    "type": "string",
                    "format": "binary"
                  }
                }
              }
            },
            "responses": {
              "200": {
                "description": "성공적으로 텍스트 추출",
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "array",
                      "items": {
                        "type": "string"
                      }
                    }
                  }
                }
              },
              "500": {
                "description": "서버 오류"
              }
            }
          }
        },
        "/ocr/form": {
          "post": {
            "summary": "이미지에서 텍스트 추출 (폼 데이터)",
            "description": "폼 데이터로 이미지를 업로드하여 텍스트를 추출합니다.",
            "requestBody": {
              "required": true,
              "content": {
                "multipart/form-data": {
                  "schema": {
                    "type": "object",
                    "properties": {
                      "image": {
                        "type": "string",
                        "format": "binary"
                      }
                    }
                  }
                }
              }
            },
            "responses": {
              "200": {
                "description": "성공적으로 텍스트 추출",
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "properties": {
                        "text": {
                          "type": "string"
                        },
                        "imagePath": {
                          "type": "string"
                        }
                      }
                    }
                  }
                }
              },
              "500": {
                "description": "서버 오류"
              }
            }
          }
        },
        "/sentences": {
          "get": {
            "summary": "저장된 문장 목록 조회",
            "description": "저장된 모든 문장을 조회합니다.",
            "responses": {
              "200": {
                "description": "문장 목록",
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "properties": {
                          "id": {
                            "type": "integer"
                          },
                          "sentenceId": {
                            "type": "string"
                          },
                          "text": {
                            "type": "string"
                          },
                          "bookName": {
                            "type": "string"
                          },
                          "bookWriter": {
                            "type": "string"
                          },
                          "date": {
                            "type": "string"
                          },
                          "imageUrl": {
                            "type": "string"
                          },
                          "created_at": {
                            "type": "string"
                          }
                        }
                      }
                    }
                  }
                }
              },
              "500": {
                "description": "서버 오류"
              }
            }
          },
          "post": {
            "summary": "새 문장 저장",
            "description": "새로운 문장을 저장합니다.",
            "requestBody": {
              "required": true,
              "content": {
                "application/json": {
                  "schema": {
                    "type": "object",
                    "required": ["sentenceId", "text", "bookName", "bookWriter", "date"],
                    "properties": {
                      "sentenceId": {
                        "type": "string"
                      },
                      "text": {
                        "type": "string"
                      },
                      "bookName": {
                        "type": "string"
                      },
                      "bookWriter": {
                        "type": "string"
                      },
                      "date": {
                        "type": "string"
                      },
                      "imageUrl": {
                        "type": "string"
                      }
                    }
                  }
                }
              }
            },
            "responses": {
              "200": {
                "description": "성공적으로 저장됨",
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "properties": {
                        "status": {
                          "type": "string"
                        },
                        "sentenceId": {
                          "type": "string"
                        }
                      }
                    }
                  }
                }
              },
              "400": {
                "description": "잘못된 요청"
              },
              "409": {
                "description": "이미 존재하는 문장 ID"
              },
              "500": {
                "description": "서버 오류"
              }
            }
          }
        },
        "/curation/{curationId}": {
          "get": {
            "summary": "큐레이션 상세 정보 조회",
            "description": "특정 큐레이션의 상세 정보를 조회합니다.",
            "parameters": [
              {
                "name": "curationId",
                "in": "path",
                "required": true,
                "schema": {
                  "type": "integer"
                }
              }
            ],
            "responses": {
              "200": {
                "description": "큐레이션 상세 정보",
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "properties": {
                        "id": {
                          "type": "integer"
                        },
                        "title": {
                          "type": "string"
                        },
                        "subtitle": {
                          "type": "string"
                        },
                        "image": {
                          "type": "string"
                        },
                        "description": {
                          "type": "string"
                        },
                        "recommenderTitle": {
                          "type": "string"
                        },
                        "recommenderLocation": {
                          "type": "object",
                          "properties": {
                            "name": {
                              "type": "string"
                            },
                            "latitude": {
                              "type": "number"
                            },
                            "longitude": {
                              "type": "number"
                            }
                          }
                        },
                        "books": {
                          "type": "array",
                          "items": {
                            "type": "object",
                            "properties": {
                              "id": {
                                "type": "integer"
                              },
                              "name": {
                                "type": "string"
                              },
                              "writer": {
                                "type": "string"
                              },
                              "summary": {
                                "type": "string"
                              },
                              "image": {
                                "type": "string"
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              },
              "404": {
                "description": "큐레이션을 찾을 수 없음"
              },
              "500": {
                "description": "서버 오류"
              }
            }
          }
        }
      }
    };
  }
} 