import 'package:flutter/material.dart';
import 'api_service.dart';

class NotificationModel {
  final int id;
  final String title;
  final String content;
  final String type;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  bool get isRead => readAt != null;
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> res = await ApiService.get('/notifications');
      _notifications = res.map((n) => NotificationModel.fromJson(n)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar notificações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await ApiService.post('/notifications/$id/read', {});
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          content: _notifications[index].content,
          type: _notifications[index].type,
          createdAt: _notifications[index].createdAt,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao marcar como lida: $e');
    }
  }
}
