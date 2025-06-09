import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:thatline_client/screens/main_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isFlashOn = false;
  bool _isBackCamera = true;
  bool _isSimulator = false;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // 카메라 초기화
  Future<void> _initializeCamera() async {
    try {
      List<CameraDescription> cameras;

      try {
        cameras = await availableCameras();
      } catch (e) {
        debugPrint('Error getting cameras, running in simulator mode: $e');
        if (mounted) {
          setState(() {
            _isSimulator = true;
          });
        }
        return;
      }

      if (cameras.isEmpty) {
        debugPrint('No cameras found, running in simulator mode');
        if (mounted) {
          setState(() {
            _isSimulator = true;
          });
        }
        return;
      }

      CameraDescription camera = cameras.first;

      try {
        if (_isBackCamera) {
          camera = cameras
              .firstWhere((c) => c.lensDirection == CameraLensDirection.back);
        } else {
          camera = cameras
              .firstWhere((c) => c.lensDirection == CameraLensDirection.front);
        }
      } catch (e) {
        debugPrint('Preferred camera not found, using default camera');
      }

      await _controller?.dispose();

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isSimulator = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isSimulator = true;
        });
      }
    }
  }

  // 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      _showErrorDialog('이미지 선택 중 오류가 발생했습니다.');
    }
  }

  // 플래시 토글
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      if (mounted) {
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  // 카메라 전환
  Future<void> _switchCamera() async {
    if (_controller == null) return;

    setState(() {
      _isBackCamera = !_isBackCamera;
    });

    await _initializeCamera();
  }

  // 사진 촬영
  Future<void> _takePicture() async {
    if (_isSimulator) {
      await _pickImage();
      return;
    }

    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final XFile image = await _controller!.takePicture();
      if (!mounted) return;

      await _uploadImage(File(image.path));
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (!mounted) return;
      _showErrorDialog('사진 촬영 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 이미지 서버 전송 및 첫 번째 문장 저장
  Future<void> _uploadImage(File imageFile) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. OCR API로 이미지 전송
      const String ocrApiUrl = 'http://localhost:8080/ocr/text';
      final ocrRequest = http.MultipartRequest('POST', Uri.parse(ocrApiUrl));
      ocrRequest.files.add(http.MultipartFile.fromBytes(
        'image',
        await imageFile.readAsBytes(),
        filename: path.basename(imageFile.path),
      ));

      debugPrint('Sending image to OCR endpoint...');
      final ocrResponse = await ocrRequest.send();
      final ocrResponseData = await ocrResponse.stream.bytesToString();
      debugPrint('OCR Response (${ocrResponse.statusCode}): $ocrResponseData');

      if (ocrResponse.statusCode != 200) {
        throw Exception('OCR 처리 중 오류가 발생했습니다: ${ocrResponse.statusCode}\n$ocrResponseData');
      }

      // 2. OCR 응답에서 텍스트 추출
      dynamic ocrData;
      try {
        ocrData = jsonDecode(ocrResponseData);
      } catch (e) {
        throw Exception('OCR 응답을 파싱하는 중 오류가 발생했습니다: $e\nResponse: $ocrResponseData');
      }
      
      if (ocrData == null) {
        throw Exception('OCR 응답이 비어 있습니다');
      }
      
      final String? extractedText = ocrData['text']?.toString();
      
      if (extractedText == null || extractedText.isEmpty) {
        throw Exception('인식된 텍스트가 없습니다. 더 선명한 이미지로 다시 시도해 주세요.\n\nOCR 응답: $ocrData');
      }

      // 3. 첫 번째 문장 추출 (마침표, 물음표, 느낌표로 문장 구분)
      final sentences = extractedText.split(RegExp(r'[.?!]'));
      if (sentences.isEmpty) {
        throw Exception('인식된 문장이 없습니다.');
      }
      
      final firstSentence = sentences[0].trim();
      if (firstSentence.isEmpty) {
        throw Exception('인식된 문장이 비어 있습니다.');
      }

      // 4. 문장 저장 API 호출
      final saveResponse = await http.post(
        Uri.parse('http://localhost:8080/sentences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': firstSentence,
          'book_name': '카메라로 촬영한 문장',
          'book_writer': '사용자',
          'image_url': '', // 이미지 URL이 필요한 경우 여기에 추가
        }),
      );

      if (saveResponse.statusCode != 200 && saveResponse.statusCode != 201) {
        throw Exception('문장 저장 중 오류가 발생했습니다: ${saveResponse.statusCode}');
      }

      debugPrint('First sentence saved successfully: $firstSentence');
      if (!mounted) return;
      _showSuccessDialog('문장이 성공적으로 저장되었습니다.\n\n"$firstSentence"');
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (!mounted) return;
      _showErrorDialog('이미지 업로드 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 성공 다이얼로그 표시
  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장 완료'),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 저장 후 북마크 페이지로 이동
              if (mounted) {
                // 현재 화면을 모두 닫고 메인 화면의 북마크 탭으로 이동
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(initialTabIndex: 3),
                  ),
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: const Text('저장 목록 보기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문서 스캔'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      if (_controller != null &&
                          _controller!.value.isInitialized)
                        CameraPreview(_controller!)
                      else
                        Container(
                          color: Colors.black,
                          child: Center(
                            child: Text(
                              _isSimulator
                                  ? '시뮬레이터에서는 카메라를 사용할 수 없습니다. 갤러리에서 이미지를 선택해주세요.'
                                  : '카메라를 불러오는 중...',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (_controller != null &&
                          _controller!.value.isInitialized)
                        Positioned(
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            width: MediaQuery.of(context).size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isFlashOn
                                        ? Icons.flash_on
                                        : Icons.flash_off,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: _toggleFlash,
                                ),
                                GestureDetector(
                                  onTap: _takePicture,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(35),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(35),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cameraswitch,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: _switchCamera,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('갤러리에서 선택'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onPressed: _pickImage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
