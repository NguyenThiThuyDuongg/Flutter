import 'package:flutter/material.dart';
import 'video_recorder_home.dart';

void main() {
  runApp(const VideoRecorderApp());
}

class VideoRecorderApp extends StatelessWidget {
  const VideoRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Recorder & Playback',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const VideoRecorderHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}