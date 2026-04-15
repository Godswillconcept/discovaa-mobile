import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/features/notifications/data/models/notification_api_model.dart';
import 'package:discovaa/features/notifications/domain/entities/notification_entity.dart';
import 'package:discovaa/features/notifications/domain/repositories/notification_repository.dart';

class RemoteNotificationRepository implements NotificationRepository {
  final DioClient _dioClient;

  RemoteNotificationRepository({required DioClient dioClient})
    : _dioClient = dioClient;

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    final response = await _dioClient.get(ApiEndpoints.notificationsV1);
    final envelope = decodeListEnvelope(
      response,
      (item) => NotificationDto.fromJson(item),
    );
    return envelope.data.map(mapNotificationDto).toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    await _dioClient.post(ApiEndpoints.notificationMarkRead(id));
  }

  @override
  Future<void> markAllAsRead() async {
    await _dioClient.post(ApiEndpoints.notificationsMarkAllRead);
  }
}
