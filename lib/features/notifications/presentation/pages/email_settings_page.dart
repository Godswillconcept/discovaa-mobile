import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/features/notifications/domain/entities/email_preferences.dart';
import 'package:discovaa/features/notifications/domain/repositories/email_repository.dart';
import 'package:discovaa/features/notifications/presentation/providers/email_preferences_provider.dart';

class EmailSettingsPage extends ConsumerStatefulWidget {
  const EmailSettingsPage({super.key});

  @override
  ConsumerState<EmailSettingsPage> createState() => _EmailSettingsPageState();
}

class _EmailSettingsPageState extends ConsumerState<EmailSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final preferencesState = ref.watch(emailPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Builder(
        builder: (context) {
          switch (preferencesState.status) {
            case EmailPreferencesLoadStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case EmailPreferencesLoadStatus.failure:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load email preferences',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (preferencesState.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        preferencesState.errorMessage!,
                        style: TextStyle(color: Colors.red[400], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(emailPreferencesProvider.notifier).retry(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            case EmailPreferencesLoadStatus.success:
            case EmailPreferencesLoadStatus.idle:
              return _buildContent(preferencesState.preferences);
          }
        },
      ),
    );
  }

  Widget _buildContent(EmailPreferences preferences) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMasterToggle(preferences),
          const SizedBox(height: 8),
          if (preferences.enabled) ...[
            _buildFrequencySelector(preferences),
            const SizedBox(height: 8),
            _buildCategoryToggles(preferences),
          ],
          const SizedBox(height: 16),
          _buildEmailHistorySection(),
        ],
      ),
    );
  }

  Widget _buildMasterToggle(EmailPreferences preferences) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            preferences.enabled ? Icons.email : Icons.email_outlined,
            color: preferences.enabled ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preferences.enabled
                      ? 'You\'ll receive email notifications'
                      : 'Email notifications are disabled',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Switch(
            value: preferences.enabled,
            onChanged: (value) =>
                _updatePreferences(preferences.toggleAllEmails()),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySelector(EmailPreferences preferences) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Text(
                'Email Frequency',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: EmailFrequency.values.map((frequency) {
              return RadioListTile<EmailFrequency>(
                title: Text(frequency.displayName),
                subtitle: Text(
                  frequency.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                value: frequency,
                onChanged: (EmailFrequency? value) {
                  if (value != null) {
                    _updatePreferences(preferences.copyWith(frequency: value));
                  }
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryToggles(EmailPreferences preferences) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: Colors.purple[700], size: 20),
              const SizedBox(width: 12),
              Text(
                'Email Categories',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    _updatePreferences(preferences.enableAllCategories()),
                child: const Text('Enable All'),
              ),
              TextButton(
                onPressed: () =>
                    _updatePreferences(preferences.disableAllCategories()),
                child: const Text('Disable All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...EmailCategory.values.map((category) {
            final isEnabled = preferences.isCategoryEnabled(category);
            return SwitchListTile(
              title: Row(
                children: [
                  Text(category.icon),
                  const SizedBox(width: 12),
                  Text(category.displayName),
                ],
              ),
              subtitle: Text(
                category.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              value: isEnabled,
              onChanged: (value) {
                _updatePreferences(preferences.toggleCategory(category));
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmailHistorySection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.orange[700], size: 20),
              const SizedBox(width: 12),
              Text(
                'Recent Emails',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showEmailHistory(),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'View your recent email notifications and their delivery status',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _updatePreferences(EmailPreferences newPreferences) {
    ref
        .read(emailPreferencesProvider.notifier)
        .updatePreferences(newPreferences);
  }

  void _showEmailHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const EmailHistoryPage()));
  }
}

class EmailHistoryPage extends ConsumerWidget {
  const EmailHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<EmailHistoryItem>>(
        future: ref.read(emailRepositoryProvider).getEmailHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load email history',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final emails = snapshot.data ?? [];

          if (emails.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No emails sent yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: emails.length,
            itemBuilder: (context, index) {
              final email = emails[index];
              return _buildEmailTile(email);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmailTile(EmailHistoryItem email) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  email.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildStatusChip(email.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                email.category,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const Spacer(),
              Text(
                _formatDate(email.sentAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          if (email.opened || email.clicked) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (email.opened) ...[
                  Icon(Icons.visibility, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Opened',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
                if (email.opened && email.clicked) const SizedBox(width: 16),
                if (email.clicked) ...[
                  Icon(Icons.link, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Clicked',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(EmailDeliveryStatus status) {
    Color color;
    String label;

    switch (status) {
      case EmailDeliveryStatus.delivered:
        color = Colors.green;
        label = 'Delivered';
        break;
      case EmailDeliveryStatus.opened:
        color = Colors.blue;
        label = 'Opened';
        break;
      case EmailDeliveryStatus.clicked:
        color = Colors.purple;
        label = 'Clicked';
        break;
      case EmailDeliveryStatus.bounced:
        color = Colors.red;
        label = 'Bounced';
        break;
      case EmailDeliveryStatus.failed:
        color = Colors.red;
        label = 'Failed';
        break;
      case EmailDeliveryStatus.pending:
      default:
        color = Colors.orange;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
