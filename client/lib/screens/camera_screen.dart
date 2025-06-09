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
    setState(() => _isLoading = true);

    try {
      // OCR API에 이미지 전송 (결과는 사용하지 않음)
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8080/ocr/text'),
      );
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      final ocrResponse = await request.send();

      if (ocrResponse.statusCode != 200) {
        debugPrint('OCR 요청 실패 (무시하고 진행): ${ocrResponse.statusCode}');
      }

      final dummyData = {
        'sentenceId': 'dummy-id-${DateTime.now().millisecondsSinceEpoch}',
        'text': '시를 잘 쓰는 사람이 아니라 시를 잘 쓰고 싶은 사람이고픈 마음이 있었을 뿐이다.',
        'bookName': '갤러리에서 선택한 문장',
        'bookWriter': '사용자',
        'date': DateTime.now().toIso8601String(),
        'imageUrl': '', // 필요시 imageFile.path 또는 업로드 URL 추가 가능
      };

      final saveResponse = await http.post(
        Uri.parse('http://localhost:8080/sentences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dummyData),
      );

      if (saveResponse.statusCode == 200 || saveResponse.statusCode == 201) {
        _showSuccessDialog('성공적으로 저장되었습니다.');
      } else {
        throw Exception('문장 저장 실패: ${saveResponse.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('이미지 업로드 중 오류: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장 완료'),
        content: Text(message),
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
          TextButton(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _controller != null && _controller!.value.isInitialized
                      ? CameraPreview(_controller!)
                      : const Center(child: Text('시뮬레이터에서는 카메라를 사용할 수 없습니다.')),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('갤러리에서 선택'),
                  ),
                ),
              ],
            ),
    );
  }
}
