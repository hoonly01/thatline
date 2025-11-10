//
//  VisionOCRHandler.swift
//  Runner
//
//  Created by ThatLine Team
//  On-device OCR using Apple Vision Framework
//

import Foundation
import Vision
import UIKit

/// OCR 처리를 위한 에러 타입
enum OCRError: Error {
    case invalidImage
    case noTextFound
    case processingFailed(String)

    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "유효하지 않은 이미지입니다"
        case .noTextFound:
            return "이미지에서 텍스트를 찾을 수 없습니다"
        case .processingFailed(let message):
            return "OCR 처리 실패: \(message)"
        }
    }
}

/// Apple Vision Framework를 사용한 OCR 핸들러
class VisionOCRHandler {

    /// 이미지 경로에서 텍스트를 인식합니다
    /// - Parameters:
    ///   - imagePath: 로컬 이미지 파일 경로
    ///   - completion: 인식 결과 콜백 (성공: [String], 실패: Error)
    func recognizeText(
        imagePath: String,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        // 이미지 로드
        guard let image = UIImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }

        // Vision Request 생성
        let request = VNRecognizeTextRequest { [weak self] request, error in
            self?.handleRecognitionResult(request: request, error: error, completion: completion)
        }

        // OCR 설정
        configureRequest(request)

        // Vision Request 실행
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            completion(.failure(OCRError.processingFailed(error.localizedDescription)))
        }
    }

    /// Vision Request 설정
    /// - Parameter request: VNRecognizeTextRequest
    private func configureRequest(_ request: VNRecognizeTextRequest) {
        // 고정밀 인식 모드 (더 정확하지만 약간 느림)
        request.recognitionLevel = .accurate

        // 한국어를 최우선으로, 영어를 보조로 설정
        request.recognitionLanguages = ["ko-KR", "en-US"]

        // 언어 기반 자동 교정 활성화
        request.usesLanguageCorrection = true

        // 최소 텍스트 높이 설정 (너무 작은 텍스트는 무시)
        // 0.0 (모든 크기) ~ 1.0 (이미지 높이와 동일)
        request.minimumTextHeight = 0.015

        // 커스텀 단어 (자주 나오는 책 제목/작가명 등)
        // 필요시 추가 가능
        // request.customWords = ["채식주의자", "한강", "김영하"]
    }

    /// Vision Request 결과 처리
    /// - Parameters:
    ///   - request: VNRequest
    ///   - error: 발생한 에러 (있는 경우)
    ///   - completion: 결과 콜백
    private func handleRecognitionResult(
        request: VNRequest,
        error: Error?,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        // 에러 처리
        if let error = error {
            DispatchQueue.main.async {
                completion(.failure(OCRError.processingFailed(error.localizedDescription)))
            }
            return
        }

        // 결과 추출
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            DispatchQueue.main.async {
                completion(.failure(OCRError.noTextFound))
            }
            return
        }

        // 빈 결과 체크
        if observations.isEmpty {
            DispatchQueue.main.async {
                completion(.failure(OCRError.noTextFound))
            }
            return
        }

        // 각 관찰 결과에서 텍스트 추출
        let recognizedTexts = observations.compactMap { observation -> String? in
            // 가장 신뢰도 높은 후보 1개 선택
            guard let topCandidate = observation.topCandidates(1).first else {
                return nil
            }

            // 신뢰도가 너무 낮으면 제외 (0.0 ~ 1.0)
            guard topCandidate.confidence > 0.3 else {
                return nil
            }

            return topCandidate.string
        }

        // 결과가 없으면 에러
        if recognizedTexts.isEmpty {
            DispatchQueue.main.async {
                completion(.failure(OCRError.noTextFound))
            }
            return
        }

        // 성공 - 메인 스레드에서 콜백 호출
        DispatchQueue.main.async {
            completion(.success(recognizedTexts))
        }
    }

    /// 이미지에서 텍스트와 위치 정보를 함께 인식합니다 (고급 기능)
    /// - Parameters:
    ///   - imagePath: 로컬 이미지 파일 경로
    ///   - completion: 인식 결과 콜백
    func recognizeTextWithBounds(
        imagePath: String,
        completion: @escaping (Result<[RecognizedTextBlock], Error>) -> Void
    ) {
        guard let image = UIImage(contentsOfFile: imagePath),
              let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                completion(.failure(OCRError.invalidImage))
            }
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(OCRError.processingFailed(error.localizedDescription)))
                }
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation],
                  !observations.isEmpty else {
                DispatchQueue.main.async {
                    completion(.failure(OCRError.noTextFound))
                }
                return
            }

            let blocks = observations.compactMap { observation -> RecognizedTextBlock? in
                guard let topCandidate = observation.topCandidates(1).first,
                      topCandidate.confidence > 0.3 else {
                    return nil
                }

                // Bounding box 변환 (Vision 좌표계 → UIKit 좌표계)
                let boundingBox = observation.boundingBox
                let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                let rect = VNImageRectForNormalizedRect(boundingBox, Int(imageSize.width), Int(imageSize.height))

                return RecognizedTextBlock(
                    text: topCandidate.string,
                    confidence: topCandidate.confidence,
                    boundingBox: rect
                )
            }

            if blocks.isEmpty {
                DispatchQueue.main.async {
                    completion(.failure(OCRError.noTextFound))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.success(blocks))
                }
            }
        }

        configureRequest(request)

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            DispatchQueue.main.async {
                completion(.failure(OCRError.processingFailed(error.localizedDescription)))
            }
        }
    }
}

/// 인식된 텍스트 블록 (텍스트 + 위치 정보)
struct RecognizedTextBlock {
    let text: String
    let confidence: Float
    let boundingBox: CGRect

    /// Flutter로 전달할 딕셔너리 형태
    var dictionary: [String: Any] {
        return [
            "text": text,
            "confidence": confidence,
            "boundingBox": [
                "x": boundingBox.origin.x,
                "y": boundingBox.origin.y,
                "width": boundingBox.size.width,
                "height": boundingBox.size.height
            ]
        ]
    }
}
