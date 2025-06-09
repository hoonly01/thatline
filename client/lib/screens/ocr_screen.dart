import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isFlashOn = false;
  bool _isBackCamera = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = _isBackCamera 
        ? cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back)
        : cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
    
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleFlash() async {
    if (_isFlashOn) {
      await _controller.setFlashMode(FlashMode.off);
    } else {
      await _controller.setFlashMode(FlashMode.torch);
    }
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  Future<void> _switchCamera() async {
    setState(() {
      _isBackCamera = !_isBackCamera;
    });
    await _controller.dispose();
    await _initializeCamera();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller.takePicture();
      
      if (!mounted) return;

      // TODO: 이미지 처리 및 다음 화면으로 전달
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ImagePreviewScreen(imagePath: image.path),
      //   ),
      // );
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),
                // 상단 바
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 뒤로 가기 버튼
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        // 플래시 버튼
                        IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ],
                    ),
                  ),
                ),
                // 하단 컨트롤 바
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // 갤러리 미리보기 (임시)
                      Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.white, size: 30),
                        ),
                      ),
                      // 촬영 버튼
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 70,
                          height: 70,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 카메라 전환 버튼
                      IconButton(
                        icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
        },
      ),
    );
  }
}

// 이미지 미리보기 화면 (추후 구현)
// class ImagePreviewScreen extends StatelessWidget {
//   final String imagePath;

//   const ImagePreviewScreen({super.key, required this.imagePath});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Image.file(File(imagePath), fit: BoxFit.cover),
//           ),
//           Positioned(
//             top: MediaQuery.of(context).padding.top + 16,
//             left: 16,
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//           Positioned(
//             bottom: 40,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // 재촬영 버튼
//                 _buildControlButton(Icons.refresh, '다시찍기', () {
//                   Navigator.pop(context);
//                 }),
//                 // 확인 버튼
//                 _buildControlButton(Icons.check, '사용하기', () {
//                   // TODO: 이미지 처리 및 다음 화면으로 전달
//                 }),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }


//   Widget _buildControlButton(IconData icon, String label, VoidCallback onPressed) {
//     return Column(
//       children: [
//         Container(
//           width: 60,
//           height: 60,
//           decoration: BoxDecoration(
//             color: Colors.black54,
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: Colors.white, size: 30),
//         ),
//         const SizedBox(height: 8),
//         Text(label, style: const TextStyle(color: Colors.white)),
//       ],
//     );
//   }
// }

class OcrScreen extends StatelessWidget {
  const OcrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraScreen();
  }
}
