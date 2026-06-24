import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class CvViewerScreen extends StatefulWidget {
  final String cvUrl;
  final String cvName;

  const CvViewerScreen({
    super.key,
    required this.cvUrl,
    required this.cvName,
  });

  @override
  State<CvViewerScreen> createState() => _CvViewerScreenState();
}

class _CvViewerScreenState extends State<CvViewerScreen> {
  String? _localPath;
  bool _loading = true;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndLoad();
  }

  Future<void> _downloadAndLoad() async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${widget.cvName}';
      final file = File(filePath);

      if (!file.existsSync()) {
        debugPrint('>>> CV URL: ${widget.cvUrl}');
        final response = await http.get(Uri.parse(widget.cvUrl));
        debugPrint('>>> HTTP STATUS: ${response.statusCode}');
        if (response.statusCode != 200) {
          debugPrint('>>> RESPONSE BODY: ${response.body}');
          throw Exception('Lỗi ${response.statusCode} khi tải CV');
        }
        await file.writeAsBytes(response.bodyBytes);
      }

      if (!mounted) return;
      setState(() {
        _localPath = filePath;
        _loading = false;
      });
    } catch (e) {
      // Xóa file lỗi để lần sau thử lại được
      try {
        final dir = await getTemporaryDirectory();
        final badFile = File('${dir.path}/${widget.cvName}');
        if (badFile.existsSync()) badFile.deleteSync();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _error = 'Không tải được CV: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cvName, overflow: TextOverflow.ellipsis),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải CV...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _downloadAndLoad();
              },
            ),
          ],
        ),
      );
    }

    if (_localPath == null) return const SizedBox();

    if (!widget.cvName.toLowerCase().endsWith('.pdf')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.blue.shade300),
            const SizedBox(height: 12),
            Text(
              'File Word không xem được trong app.\nVui lòng dùng file PDF.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      onRender: (pages) {
        if (mounted) setState(() => _totalPages = pages ?? 0);
      },
      onPageChanged: (page, total) {
        if (mounted) setState(() => _currentPage = page ?? 0);
      },
      onError: (error) {
        if (mounted) setState(() => _error = 'Lỗi hiển thị PDF: $error');
      },
    );
  }
}