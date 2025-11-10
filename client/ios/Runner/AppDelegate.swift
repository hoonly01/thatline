import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    // Vision OCR Handler 인스턴스
    private let visionOCRHandler = VisionOCRHandler()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Flutter Plugin 등록
        GeneratedPluginRegistrant.register(with: self)

        // Method Channel 설정
        setupMethodChannels()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// Method Channel 설정
    private func setupMethodChannels() {
        guard let window = window,
              let controller = window.rootViewController as? FlutterViewController else {
            print("⚠️ FlutterViewController를 찾을 수 없습니다")
            return
        }

        // OCR Method Channel 생성
        let ocrChannel = FlutterMethodChannel(
            name: "com.thatline/ocr",
            binaryMessenger: controller.binaryMessenger
        )

        // Method Call Handler 설정
        ocrChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }

            switch call.method {
            case "recognizeText":
                self.handleRecognizeText(call: call, result: result)
            case "recognizeTextWithBounds":
                self.handleRecognizeTextWithBounds(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        print("✅ OCR Method Channel 설정 완료")
    }

    /// 기본 텍스트 인식 처리
    /// - Parameters:
    ///   - call: FlutterMethodCall
    ///   - result: FlutterResult
    private func handleRecognizeText(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Arguments 파싱
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "imagePath가 필요합니다",
                details: nil
            ))
            return
        }

        print("🔍 OCR 시작: \(imagePath)")

        // OCR 실행
        visionOCRHandler.recognizeText(imagePath: imagePath) { ocrResult in
            switch ocrResult {
            case .success(let texts):
                print("✅ OCR 성공: \(texts.count)개 텍스트 인식")
                result(texts)

            case .failure(let error):
                print("❌ OCR 실패: \(error.localizedDescription)")
                result(FlutterError(
                    code: "OCR_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }

    /// 위치 정보 포함 텍스트 인식 처리 (고급 기능)
    /// - Parameters:
    ///   - call: FlutterMethodCall
    ///   - result: FlutterResult
    private func handleRecognizeTextWithBounds(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "imagePath가 필요합니다",
                details: nil
            ))
            return
        }

        print("🔍 OCR (with bounds) 시작: \(imagePath)")

        visionOCRHandler.recognizeTextWithBounds(imagePath: imagePath) { ocrResult in
            switch ocrResult {
            case .success(let blocks):
                print("✅ OCR 성공: \(blocks.count)개 텍스트 블록 인식")
                let blockDictionaries = blocks.map { $0.dictionary }
                result(blockDictionaries)

            case .failure(let error):
                print("❌ OCR 실패: \(error.localizedDescription)")
                result(FlutterError(
                    code: "OCR_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }
}
