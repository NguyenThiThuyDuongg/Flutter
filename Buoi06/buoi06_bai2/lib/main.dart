import 'package:flutter/material.dart';
import 'photo_capture_home.dart';

void main() {
  runApp(PhotoCaptureApp());
}

class PhotoCaptureApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Capture & Preview',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: PhotoCaptureHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}