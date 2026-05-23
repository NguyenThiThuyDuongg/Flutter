import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SmsAnalyzerApp());
}

/// =======================
/// APP ROOT
/// =======================
class SmsAnalyzerApp extends StatelessWidget {
  const SmsAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const SmsAnalyzerScreen(),
    );
  }
}

/// =======================
/// ENUM TYPE
/// =======================
enum SmsType {
  normal,
  advertisement,
  otp,
}

/// =======================
/// MODEL PHÂN TÍCH SMS
/// =======================
class SmsItem {
  final SmsMessage message;
  final SmsType type;
  final String? otpCode;

  SmsItem({
    required this.message,
    required this.type,
    this.otpCode,
  });

  factory SmsItem.fromMessage(SmsMessage sms) {
    final body = sms.body ?? '';

    // [QC] => quảng cáo
    if (body.startsWith('[QC]')) {
      return SmsItem(
        message: sms,
        type: SmsType.advertisement,
      );
    }

    // [OTP]123456 hoặc [OTP] 123456
    final otpRegex = RegExp(r'^\[OTP\]\s*(\d{6})');
    final match = otpRegex.firstMatch(body);

    if (match != null) {
      return SmsItem(
        message: sms,
        type: SmsType.otp,
        otpCode: match.group(1),
      );
    }

    return SmsItem(
      message: sms,
      type: SmsType.normal,
    );
  }

  String get sender => message.address ?? 'Unknown';

  String get body => message.body ?? '';

  DateTime get date =>
      message.date ?? DateTime.fromMillisecondsSinceEpoch(0);
}

/// =======================
/// MAIN SCREEN
/// =======================
class SmsAnalyzerScreen extends StatefulWidget {
  const SmsAnalyzerScreen({super.key});

  @override
  State<SmsAnalyzerScreen> createState() =>
      _SmsAnalyzerScreenState();
}

class _SmsAnalyzerScreenState
    extends State<SmsAnalyzerScreen> {
  final SmsQuery _query = SmsQuery();

  List<SmsItem> _allMessages = [];
  List<SmsItem> _filteredMessages = [];

  bool _isLoading = false;

  final TextEditingController _phoneController =
      TextEditingController();

  String _selectedFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// =======================
  /// LOAD SMS
  /// =======================
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    final status = await Permission.sms.request();

    if (!status.isGranted) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn chưa cấp quyền đọc SMS'),
          ),
        );
      }
      return;
    }

    try {
      final messages = await _query.getAllSms;

      _allMessages = messages
          .map((sms) => SmsItem.fromMessage(sms))
          .toList();

      _applyFilter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đọc SMS: $e'),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// =======================
  /// APPLY FILTER
  /// =======================
  void _applyFilter() {
    List<SmsItem> temp = List.from(_allMessages);

    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      temp = temp
          .where((item) => item.sender.contains(phone))
          .toList();
    }

    switch (_selectedFilter) {
      case 'Quảng cáo':
        temp = temp
            .where(
              (item) =>
                  item.type == SmsType.advertisement,
            )
            .toList();
        break;

      case 'OTP':
        temp = temp
            .where(
              (item) => item.type == SmsType.otp,
            )
            .toList();
        break;
    }

    setState(() {
      _filteredMessages = temp;
    });
  }

  /// =======================
  /// STATISTICS BY DAY
  /// =======================
  Map<String, int> _statisticsByDay() {
    final Map<String, int> stats = {};

    for (final item in _allMessages) {
      final key =
          DateFormat('dd/MM/yyyy').format(item.date);
      stats[key] = (stats[key] ?? 0) + 1;
    }

    return stats;
  }

  /// =======================
  /// STATISTICS BY MONTH
  /// =======================
  Map<String, int> _statisticsByMonth() {
    final Map<String, int> stats = {};

    for (final item in _allMessages) {
      final key =
          DateFormat('MM/yyyy').format(item.date);
      stats[key] = (stats[key] ?? 0) + 1;
    }

    return stats;
  }

  /// =======================
  /// SHOW OTP
  /// =======================
  void _showOtpDialog(String otp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.security,
              color: Colors.green,
            ),
            SizedBox(width: 8),
            Text('Mã OTP'),
          ],
        ),
        content: Center(
          child: SelectableText(
            otp,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.red,
              letterSpacing: 6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// STAT CARD
  /// =======================
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 8,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// =======================
  /// SMS TYPE STYLE
  /// =======================
  IconData _iconForType(SmsType type) {
    switch (type) {
      case SmsType.advertisement:
        return Icons.campaign;
      case SmsType.otp:
        return Icons.security;
      case SmsType.normal:
        return Icons.message;
    }
  }

  Color _colorForType(SmsType type) {
    switch (type) {
      case SmsType.advertisement:
        return Colors.orange;
      case SmsType.otp:
        return Colors.green;
      case SmsType.normal:
        return Colors.indigo;
    }
  }

  String _labelForType(SmsType type) {
    switch (type) {
      case SmsType.advertisement:
        return 'QC';
      case SmsType.otp:
        return 'OTP';
      case SmsType.normal:
        return 'SMS';
    }
  }

  /// =======================
  /// BUILD UI
  /// =======================
  @override
  Widget build(BuildContext context) {
    final dayStats = _statisticsByDay();
    final monthStats = _statisticsByMonth();

    final otpCount = _allMessages
        .where((item) => item.type == SmsType.otp)
        .length;

    final adCount = _allMessages
        .where(
          (item) => item.type == SmsType.advertisement,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Analyzer'),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4F46E5),
                Color(0xFF7C3AED),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // =======================
                // STATISTICS
                // =======================
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.mail,
                        color: Colors.indigo,
                        title: 'Tổng',
                        value:
                            '${_allMessages.length}',
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        icon: Icons.campaign,
                        color: Colors.orange,
                        title: 'QC',
                        value: '$adCount',
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        icon: Icons.security,
                        color: Colors.green,
                        title: 'OTP',
                        value: '$otpCount',
                      ),
                    ],
                  ),
                ),

                // =======================
                // FILTER PANEL
                // =======================
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller:
                              _phoneController,
                          decoration:
                              InputDecoration(
                            labelText:
                                'Lọc theo số điện thoại',
                            prefixIcon:
                                const Icon(
                              Icons.phone,
                            ),
                            suffixIcon:
                                IconButton(
                              onPressed: () {
                                _phoneController
                                    .clear();
                                _applyFilter();
                              },
                              icon: const Icon(
                                Icons.clear,
                              ),
                            ),
                          ),
                          onChanged: (_) =>
                              _applyFilter(),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<
                            String>(
                          value:
                              _selectedFilter,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Nhóm tin nhắn',
                            prefixIcon:
                                Icon(
                              Icons.filter_list,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Tất cả',
                              child:
                                  Text('Tất cả'),
                            ),
                            DropdownMenuItem(
                              value:
                                  'Quảng cáo',
                              child:
                                  Text(
                                      'Quảng cáo'),
                            ),
                            DropdownMenuItem(
                              value: 'OTP',
                              child:
                                  Text('OTP'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _selectedFilter =
                                  value;
                              _applyFilter();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // =======================
                // STATISTICS DETAILS
                // =======================
                ExpansionTile(
                  title: const Text(
                    'Thống kê theo ngày',
                  ),
                  children: dayStats.entries
                      .take(10)
                      .map(
                        (e) => ListTile(
                          dense: true,
                          title: Text(e.key),
                          trailing:
                              Text('${e.value}'),
                        ),
                      )
                      .toList(),
                ),

                ExpansionTile(
                  title: const Text(
                    'Thống kê theo tháng',
                  ),
                  children: monthStats.entries
                      .map(
                        (e) => ListTile(
                          dense: true,
                          title: Text(e.key),
                          trailing:
                              Text('${e.value}'),
                        ),
                      )
                      .toList(),
                ),

                // =======================
                // SMS LIST
                // =======================
                Expanded(
                  child:
                      _filteredMessages
                              .isEmpty
                          ? const Center(
                              child: Text(
                                'Không có dữ liệu',
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.only(
                                left: 12,
                                right: 12,
                                bottom: 12,
                              ),
                              itemCount:
                                  _filteredMessages
                                      .length,
                              itemBuilder:
                                  (
                                    context,
                                    index,
                                  ) {
                                final item =
                                    _filteredMessages[
                                        index];

                                final color =
                                    _colorForType(
                                  item.type,
                                );

                                return Card(
                                  margin:
                                      const EdgeInsets.only(
                                    bottom: 8,
                                  ),
                                  child:
                                      ListTile(
                                    contentPadding:
                                        const EdgeInsets.all(
                                      12,
                                    ),
                                    leading:
                                        CircleAvatar(
                                      backgroundColor:
                                          color.withOpacity(
                                        0.15,
                                      ),
                                      child: Icon(
                                        _iconForType(
                                          item.type,
                                        ),
                                        color:
                                            color,
                                      ),
                                    ),
                                    title: Text(
                                      item
                                          .sender,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    subtitle:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Text(
                                          item
                                              .body,
                                          maxLines:
                                              2,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                        ),
                                        const SizedBox(
                                          height: 6,
                                        ),
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy HH:mm',
                                          ).format(
                                            item
                                                .date,
                                          ),
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                12,
                                            color:
                                                Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing:
                                        Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [
                                        Chip(
                                          label:
                                              Text(
                                            _labelForType(
                                              item
                                                  .type,
                                            ),
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  11,
                                            ),
                                          ),
                                          backgroundColor:
                                              color.withOpacity(
                                            0.12,
                                          ),
                                        ),
                                        if (item.type ==
                                            SmsType
                                                .otp)
                                          Text(
                                            item.otpCode ??
                                                '',
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              color:
                                                  Colors.green,
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      if (item
                                              .type ==
                                          SmsType
                                              .otp) {
                                        _showOtpDialog(
                                          item.otpCode ??
                                              '',
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}