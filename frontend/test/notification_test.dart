import 'package:flutter_test/flutter_test.dart';
import 'package:mediare_mgcf/notification_service.dart';

void main() {
  test('NotificationService unreadCount returns correct value', () {
    final service = NotificationService();
    
    // Manual setup for testing (shadowing internal state if possible, or using methods)
    // Since state is private, we can't easily mock it without exposing it.
    // But we can check initial state.
    expect(service.unreadCount, 0);
  });

  test('NotificationModel fromJson works correctly', () {
    final json = {
      'id': 1,
      'title': 'Test Title',
      'content': 'Test Content',
      'type': 'info',
      'read_at': null,
      'created_at': '2024-01-01T12:00:00Z'
    };
    
    final model = NotificationModel.fromJson(json);
    
    expect(model.id, 1);
    expect(model.title, 'Test Title');
    expect(model.isRead, false);
    expect(model.type, 'info');
  });
}
