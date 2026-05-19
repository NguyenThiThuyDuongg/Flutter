import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class MediaPickerHome extends StatefulWidget {
  const MediaPickerHome({super.key});

  @override
  State<MediaPickerHome> createState() => _MediaPickerHomeState();
}

class _MediaPickerHomeState extends State<MediaPickerHome> {
  File? _mediaFile; // Lưu trữ file media (ảnh hoặc video)
  VideoPlayerController? _videoController; // Điều khiển phát video
  final ImagePicker _picker = ImagePicker(); // Khởi tạo ImagePicker

  // Kiểm tra và yêu cầu quyền truy cập
  Future<void> _requestPermission(Permission permission) async {
    if (await permission.isDenied) {
      await permission.request();
    }
  }

  // Chọn ảnh hoặc video từ Gallery
  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    // Yêu cầu quyền truy cập
    await _requestPermission(
      isVideo ? Permission.storage : Permission.photos,
    );

    // Chọn file
    final XFile? pickedFile = isVideo
        ? await _picker.pickVideo(
            source: source,
          )
        : await _picker.pickImage(
            source: source,
            imageQuality: 100,
            maxWidth: 1920,
            maxHeight: 1080,
          );

    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);

        if (isVideo || _mediaFile!.path.toLowerCase().endsWith('.mp4')) {
          // Nếu là video
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(_mediaFile!);

          _videoController!.initialize().then((_) {
            if (mounted) {
              setState(() {});
              _videoController!.play();
            }
          });
        } else {
          // Nếu là ảnh
          _videoController?.dispose();
          _videoController = null;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No media selected'),
        ),
      );
    }
  }

  // Chụp ảnh hoặc quay video từ Camera
  Future<void> _captureMedia(bool isVideo) async {
    // Yêu cầu quyền Camera
    await _requestPermission(Permission.camera);

    // Nếu quay video thì cần Microphone
    if (isVideo) {
      await _requestPermission(Permission.microphone);
    }

    // Chụp ảnh hoặc quay video
    final XFile? capturedFile = isVideo
        ? await _picker.pickVideo(
            source: ImageSource.camera,
          )
        : await _picker.pickImage(
            source: ImageSource.camera,
          );

    if (capturedFile != null) {
      setState(() {
        _mediaFile = File(capturedFile.path);

        if (isVideo) {
          // Nếu là video
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(_mediaFile!);

          _videoController!.initialize().then((_) {
            if (mounted) {
              setState(() {});
              _videoController!.play();
            }
          });
        } else {
          // Nếu là ảnh
          _videoController?.dispose();
          _videoController = null;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No media captured'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Picker App'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Hiển thị ảnh hoặc video
            _mediaFile == null
                ? const Text('Chưa chọn ảnh hoặc video.')
                : _videoController != null &&
                        _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio:
                            _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : Image.file(
                        _mediaFile!,
                        height: 300,
                      ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () =>
                  _pickMedia(ImageSource.gallery, false),
              child: const Text('Chọn ảnh từ Gallery'),
            ),

            ElevatedButton(
              onPressed: () => _captureMedia(false),
              child: const Text('Chụp ảnh từ Camera'),
            ),

            ElevatedButton(
              onPressed: () =>
                  _pickMedia(ImageSource.gallery, true),
              child: const Text('Chọn video từ Gallery'),
            ),

            ElevatedButton(
              onPressed: () => _captureMedia(true),
              child: const Text('Quay video từ Camera'),
            ),
          ],
        ),
      ),
    );
  }
}