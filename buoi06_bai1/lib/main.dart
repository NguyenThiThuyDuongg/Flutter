import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'media_picker_home.dart';
void main() {
runApp(MediaPickerApp());
}
class MediaPickerApp extends StatelessWidget {
const MediaPickerApp({super.key});
@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Media Picker App',
theme: ThemeData(primarySwatch: Colors.blue),
home: MediaPickerHome(),
);
}
}