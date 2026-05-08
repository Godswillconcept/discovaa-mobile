import 'package:flutter/foundation.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/notifications/domain/entities/email_preferences.dart';
import 'package:discovaa/features/notifications/domain/repositories/email_repository.dart';

/// Implementation of EmailRepository
class EmailRepositoryImpl implements EmailRepository {
  final DioClient _dioClient;
  final HiveService _hiveService;

  static const String _preferencesKey = 'email_preferences';

  EmailRepositoryImpl({
    required DioClient dioClient,
    required HiveService hiveService,
  }) : _dioClient = dioClient,
       _hiveService = hiveService;

  @override
  Future<EmailPreferences> getEmailPreferences() async {
    try {
      // Try to get from cache first
      final cachedJson = _hiveService.getMap(_preferencesKey);
      final preferences = cachedJson != null
          ? _parseEmailPreferences(cachedJson)
          : null;
      if (preferences != null) return preferences;

      // Fetch from API
      final response = await _dioClient.get('/api/email/preferences/');

      if (response.statusCode == 200) {
        final data = response.data;
        final preferences = _parseEmailPreferences(data);

        // Cache the preferences
        await _hiveService.setMap(
          _preferencesKey,
          _emailPreferencesToJson(preferences),
        );

        return preferences;
      } else {
        throw Exception('Failed to fetch email preferences');
      }
    } catch (e) {
      // Return default preferences on error
      return EmailPreferences();
    }
  }

  @override
  Future<EmailPreferences> updateEmailPreferences(
    EmailPreferences preferences,
  ) async {
    try {
      final data = _emailPreferencesToJson(preferences);

      final response = await _dioClient.patch(
        '/api/email/preferences/',
        data: data,
      );

      if (response.statusCode == 200) {
        final updatedData = response.data;
        final updatedPreferences = _parseEmailPreferences(updatedData);

        // Update cache
        await _hiveService.setMap(
          _preferencesKey,
          _emailPreferencesToJson(updatedPreferences),
        );

        return updatedPreferences;
      } else {
        throw Exception('Failed to update email preferences');
      }
    } catch (e) {
      // Cache locally even if API fails
      await _hiveService.setMap(
        _preferencesKey,
        _emailPreferencesToJson(preferences),
      );
      return preferences;
    }
  }

  @override
  Future<void> sendTransactionalEmail({
    required String type,
    required Map<String, dynamic> context,
  }) async {
    try {
      final data = {'type': type, 'context': context};

      final response = await _dioClient.post(
        '/api/email/transactional/',
        data: data,
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send transactional email');
      }
    } catch (e) {
      // Log error but don't throw - emails are non-critical
      debugPrint('Failed to send transactional email: $e');
    }
  }

  @override
  Future<EmailDeliveryStatus> getEmailDeliveryStatus(
    String notificationId,
  ) async {
    try {
      final response = await _dioClient.get(
        '/api/email/delivery-status/$notificationId/',
      );

      if (response.statusCode == 200) {
        final status = response.data['status'] as String?;
        return _parseDeliveryStatus(status);
      } else {
        return EmailDeliveryStatus.pending;
      }
    } catch (e) {
      return EmailDeliveryStatus.pending;
    }
  }

  @override
  Future<void> setEmailSubscription({
    required bool subscribed,
    String? category,
  }) async {
    try {
      final data = {
        'subscribed': subscribed,
        if (category != null) 'category': category,
      };

      final response = await _dioClient.post(
        '/api/email/subscription/',
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update email subscription');
      }
    } catch (e) {
      // Log error but don't throw
      debugPrint('Failed to update email subscription: $e');
    }
  }

  @override
  Future<List<EmailHistoryItem>> getEmailHistory({
    int page = 1,
    int pageSize = 20,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (category != null) 'category': category,
      };

      final response = await _dioClient.get(
        '/api/email/history/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final results = data['results'] as List<dynamic>?;

        return results?.map((item) => _parseEmailHistoryItem(item)).toList() ??
            [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Helper methods

  EmailPreferences _parseEmailPreferences(Map<String, dynamic> data) {
    final enabled = data['enabled'] as bool? ?? true;
    final frequencyStr = data['frequency'] as String?;
    final frequency = _parseEmailFrequency(frequencyStr);

    final categoryData = data['category_preferences'] as Map<String, dynamic>?;
    final categoryPreferences = <EmailCategory, bool>{};

    if (categoryData != null) {
      for (final category in EmailCategory.values) {
        categoryPreferences[category] =
            categoryData[category.name] as bool? ?? true;
      }
    }

    return EmailPreferences(
      enabled: enabled,
      categoryPreferences: categoryPreferences,
      frequency: frequency,
      lastUpdated: DateTime.tryParse(data['last_updated'] ?? ''),
    );
  }

  Map<String, dynamic> _emailPreferencesToJson(EmailPreferences preferences) {
    return {
      'enabled': preferences.enabled,
      'frequency': preferences.frequency.name,
      'category_preferences': {
        for (final category in EmailCategory.values)
          category.name: preferences.categoryPreferences[category] ?? true,
      },
    };
  }

  EmailFrequency _parseEmailFrequency(String? frequencyStr) {
    if (frequencyStr == null) return EmailFrequency.immediate;

    for (final frequency in EmailFrequency.values) {
      if (frequency.name == frequencyStr) {
        return frequency;
      }
    }

    return EmailFrequency.immediate;
  }

  EmailDeliveryStatus _parseDeliveryStatus(String? statusStr) {
    if (statusStr == null) return EmailDeliveryStatus.pending;

    for (final status in EmailDeliveryStatus.values) {
      if (status.name == statusStr) {
        return status;
      }
    }

    return EmailDeliveryStatus.pending;
  }

  EmailHistoryItem _parseEmailHistoryItem(Map<String, dynamic> data) {
    return EmailHistoryItem(
      id: data['id'] as String,
      subject: data['subject'] as String,
      category: data['category'] as String,
      sentAt: DateTime.parse(data['sent_at'] as String),
      status: _parseDeliveryStatus(data['status'] as String?),
      opened: data['opened'] as bool? ?? false,
      openedAt: data['opened_at'] != null
          ? DateTime.parse(data['opened_at'] as String)
          : null,
      clicked: data['clicked'] as bool? ?? false,
      clickedAt: data['clicked_at'] != null
          ? DateTime.parse(data['clicked_at'] as String)
          : null,
    );
  }

  /// Clear cached email preferences
  Future<void> clearCache() async {
    await _hiveService.remove(_preferencesKey);
  }
}
