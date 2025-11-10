import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:thatline_client/screens/main_screen.dart';
import 'package:thatline_client/services/on_device_ocr_service.dart';

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
  final OnDeviceOCRService _ocrService = OnDeviceOCRService();
  final Uuid _uuid = const Uuid();
  String _loadingMessage = '처리 중...';

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

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) =>
            c.lensDirection ==
            (_isBackCamera
                ? CameraLensDirection.back
                : CameraLensDirection.front),
        orElse: () => cameras.first,
      );

      _controller =
          CameraController(camera, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();

      if (mounted) setState(() => _isSimulator = false);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _isSimulator = true);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      _showErrorDialog('이미지 선택 중 오류 발생: $e');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    if (!mounted) return;

    try {
      // 1️⃣ OCR 시작 - 로딩 표시
      setState(() {
        _isLoading = true;
        _loadingMessage = '책 속 문장을 읽고 있어요...';
      });

      // 2️⃣ On-device OCR 실행
      List<String> recognizedTexts;

      if (OnDeviceOCRService.isSupported) {
        // iOS: Vision Framework 사용
        debugPrint('📱 On-device OCR 시작');
        recognizedTexts = await _ocrService.recognizeText(imageFile.path);
        debugPrint('✅ OCR 성공: ${recognizedTexts.length}개 텍스트 인식');
      } else {
        // Android or 기타: 서버 OCR Fallback
        debugPrint('🌐 서버 OCR Fallback 사용');
        recognizedTexts = await _performServerOCR(imageFile);
      }

      // 3️⃣ 결과 확인
      if (recognizedTexts.isEmpty) {
        throw OCRException(
          '이미지에서 텍스트를 찾을 수 없습니다.\n다른 이미지를 선택해주세요',
          code: 'NO_TEXT_FOUND',
        );
      }

      // 4️⃣ OCR 결과를 하나의 문장으로 결합
      final extractedText = _ocrService.joinTexts(recognizedTexts);
      debugPrint('📝 추출된 텍스트: $extractedText');

      // 로딩 해제
      if (mounted) {
        setState(() => _isLoading = false);
      }

      // 5️⃣ 편집 다이얼로그 표시
      final editedData = await _showEditDialog(extractedText);

      // 사용자가 취소한 경우
      if (editedData == null) {
        debugPrint('❌ 사용자가 저장을 취소했습니다');
        return;
      }

      // 6️⃣ 서버에 문장 저장
      setState(() {
        _isLoading = true;
        _loadingMessage = '문장을 저장하는 중...';
      });

      await _saveSentenceToServer(editedData);

      // 7️⃣ 성공 메시지 표시
      if (mounted) {
        _showSuccessDialog('문장이 저장되었습니다!', editedData['text'] as String);
      }
    } on OCRException catch (e) {
      debugPrint('❌ OCR 에러: ${e.message}');
      if (mounted) {
        _showErrorDialog(e.userFriendlyMessage);
      }
    } catch (e) {
      debugPrint('❌ 예상치 못한 에러: $e');
      if (mounted) {
        _showErrorDialog('오류가 발생했습니다.\n다시 시도해주세요');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 서버 OCR 실행 (Fallback)
  Future<List<String>> _performServerOCR(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:8080/ocr/text'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('서버 OCR 실패: ${response.statusCode}');
    }

    final responseBody = await response.stream.bytesToString();
    final List<dynamic> result = jsonDecode(responseBody);

    return List<String>.from(result);
  }

  /// 문장 편집 다이얼로그 표시
  Future<Map<String, String>?> _showEditDialog(String initialText) async {
    final textController = TextEditingController(text: initialText);
    final bookNameController = TextEditingController();
    final bookWriterController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('문장 정보 입력'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '인식된 문장',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '문장을 수정하세요',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '책 제목',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bookNameController,
                decoration: const InputDecoration(
                  hintText: '예: 채식주의자',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '작가',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bookWriterController,
                decoration: const InputDecoration(
                  hintText: '예: 한강',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              final bookName = bookNameController.text.trim();
              final bookWriter = bookWriterController.text.trim();

              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('문장을 입력해주세요')),
                );
                return;
              }

              Navigator.pop(context, {
                'text': text,
                'bookName': bookName.isEmpty ? '제목 미상' : bookName,
                'bookWriter': bookWriter.isEmpty ? '작가 미상' : bookWriter,
              });
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  /// 서버에 문장 저장
  Future<void> _saveSentenceToServer(Map<String, String> data) async {
    final sentenceData = {
      'sentenceId': _uuid.v4(),
      'text': data['text']!,
      'bookName': data['bookName']!,
      'bookWriter': data['bookWriter']!,
      'date': DateTime.now().toIso8601String(),
      'imageUrl': '',
    };

    final response = await http.post(
      Uri.parse('http://localhost:8080/sentences'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sentenceData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('문장 저장 실패: ${response.statusCode}');
    }
  }

  void _showSuccessDialog(String message, String savedText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('저장 완료'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$savedText"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const MainScreen(initialTabIndex: 3)),
                (route) => false,
              );
            },
            child: const Text('저장 목록 보기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
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
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _controller != null && _controller!.value.isInitialized
                    ? CameraPreview(_controller!)
                    : const Center(
                        child: Text('시뮬레이터에서는 카메라를 사용할 수 없습니다.')),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('갤러리에서 선택'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
          // 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
