import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CvService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _cloudName = 'dfa3ihj5u';
  static const _uploadPreset = 'cv_unsigned';

  Future<String?> uploadCvBytes(
      String uid, Uint8List bytes, String fileName) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/raw/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'cvs/$uid'
      // KHÔNG thêm access_mode hay resource_type — unsigned preset không cho phép
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      throw Exception(
          'Cloudinary upload failed: ${json['error']?['message'] ?? body}');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String;
    final publicId = json['public_id'] as String;

    await _db.collection('users').doc(uid).update({
      'cvUrl': url,
      'cvName': fileName,
      'cvPath': publicId,
      'cvUploadedAt': FieldValue.serverTimestamp(),
    });

    return url;
  }

  Future<void> deleteCv(String uid, String cvPath) async {
    try {
      await _db.collection('users').doc(uid).update({
        'cvUrl': FieldValue.delete(),
        'cvName': FieldValue.delete(),
        'cvPath': FieldValue.delete(),
        'cvUploadedAt': FieldValue.delete(),
      });
    } catch (_) {}
  }

  Future<Map<String, String?>> getCvInfo(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return {
      'cvUrl': doc.data()?['cvUrl'],
      'cvName': doc.data()?['cvName'],
      'cvPath': doc.data()?['cvPath'],
    };
  }
}