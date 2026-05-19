import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'video_player_screen.dart';

class VideoRecorderHome extends StatefulWidget {
  const VideoRecorderHome({super.key});

  @override
  State<VideoRecorderHome> createState() =>
      _VideoRecorderHomeState();
}

class _VideoRecorderHomeState
    extends State<VideoRecorderHome> {

  final ImagePicker _picker = ImagePicker();

  File? _videoFile;

  // Xin quyền

  Future<void> _requestPermission(
      Permission permission) async {

    if (await permission.isDenied) {

      await permission.request();
    }
  }

  // Chọn video từ Gallery

  Future<void> _pickVideoFromGallery() async {

    await _requestPermission(
      Permission.photos,
    );

    final XFile? pickedFile =
        await _picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {

      setState(() {

        _videoFile = File(
          pickedFile.path,
        );
      });

      _openVideoPlayer();
    }
  }

  // Quay video từ Camera

  Future<void> _recordVideoFromCamera() async {

    await _requestPermission(
      Permission.camera,
    );

    await _requestPermission(
      Permission.microphone,
    );

    final XFile? recordedFile =
        await _picker.pickVideo(
      source: ImageSource.camera,
    );

    if (recordedFile != null) {

      setState(() {

        _videoFile = File(
          recordedFile.path,
        );
      });

      _openVideoPlayer();
    }
  }

  // Mở màn hình phát video

  void _openVideoPlayer() {

    if (_videoFile != null) {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (context) =>
              VideoPlayerScreen(
            videoFile: _videoFile!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Video Recorder',
        ),
      ),

      body: Center(

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.video_collection,
              size: 120,
              color: Colors.purple,
            ),

            const SizedBox(height: 30),

            ElevatedButton(

              onPressed:
                  _pickVideoFromGallery,

              child: const Text(
                'Chọn Video từ Gallery',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(

              onPressed:
                  _recordVideoFromCamera,

              child: const Text(
                'Quay Video từ Camera',
              ),
            ),
          ],
        ),
      ),
    );
  }
}