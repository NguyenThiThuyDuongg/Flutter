import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../viewmodels/auth_viewmodel.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIcon(String type) {
    switch (type) {
      case 'accepted': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'applied': return Icons.send;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      case 'applied': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final notifService = NotificationService();
    final uid = auth.userModel!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () => notifService.markAllAsRead(uid),
            child: const Text('Đọc tất cả',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: notifService.getMyNotifications(uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifs = snap.data!;
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Chưa có thông báo nào',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (_, i) {
              final n = notifs[i];
              final isRead = n['isRead'] ?? false;
              final type = n['type'] ?? 'general';
              final createdAt = (n['createdAt'] as dynamic)
                  ?.toDate()
                  .toString()
                  .substring(0, 16) ?? '';

              return InkWell(
                onTap: () => notifService.markAsRead(n['id']),
                child: Container(
                  color: isRead ? null : Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _getColor(type).withValues(alpha: 0.15),
                        child: Icon(_getIcon(type),
                            color: _getColor(type), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['title'] ?? '',
                                style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(n['body'] ?? '',
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(createdAt,
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E88E5),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
