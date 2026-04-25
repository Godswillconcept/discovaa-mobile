import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/profile_connectivity_provider.dart';
import 'package:discovaa/features/profile/presentation/widgets/tabs/user_info_tab.dart';
import 'package:discovaa/features/profile/presentation/widgets/tabs/provider_profile_tab.dart';
import 'package:discovaa/features/profile/presentation/widgets/tabs/availability_tab.dart';
import 'package:discovaa/features/profile/presentation/widgets/tabs/payouts_tab.dart';
import 'package:discovaa/features/profile/presentation/widgets/tabs/login_security_tab.dart';
import 'package:discovaa/features/profile/presentation/widgets/privacy_tab.dart';
import 'package:discovaa/shared/presentation/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User Profile Page - Main profile management screen
/// Features: User Info, Provider Profile, Availability, Payouts, Login & Security, Privacy
class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  int _selectedTabIndex = 0;

  List<_TabConfig> _getTabs(bool isProvider) {
    return [
      const _TabConfig(
        label: 'User Info',
        icon: Icons.person_outline,
        widget: UserInfoTab(),
      ),
      if (isProvider) ...[
        const _TabConfig(
          label: 'Provider',
          icon: Icons.business_outlined,
          widget: ProviderProfileTab(),
        ),
        const _TabConfig(
          label: 'Availability',
          icon: Icons.schedule_outlined,
          widget: AvailabilityTab(),
        ),
        const _TabConfig(
          label: 'Payouts',
          icon: Icons.account_balance_wallet_outlined,
          widget: PayoutsTab(),
        ),
      ],
      const _TabConfig(
        label: 'Security',
        icon: Icons.security_outlined,
        widget: LoginSecurityTab(),
      ),
      const _TabConfig(
        label: 'Privacy',
        icon: Icons.privacy_tip_outlined,
        widget: PrivacyTab(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final connectivityState = ref.watch(profileConnectivityProvider);

    final isProvider = profileState.profile?.isProvider ?? false;
    final tabs = _getTabs(isProvider);
    final safeTabIndex = _selectedTabIndex < tabs.length
        ? _selectedTabIndex
        : 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Column(
          children: [
            // Header
            const MainHeader(),

            // Connectivity Indicator
            ProfileConnectivityIndicator(
              state: connectivityState,
              onRetry: () => ref
                  .read(profileConnectivityProvider.notifier)
                  .checkConnection(),
            ),

            // Tab Switcher
            _buildTabSwitcher(tabs, safeTabIndex),

            const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),

            // Cache Banner (shown when using cached data)
            if (profileState.isFromCache)
              _buildCacheBanner(profileState.cacheTimestamp),

            // Tab Content
            Expanded(child: _buildContent(profileState, tabs, safeTabIndex)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ProfileState state,
    List<_TabConfig> tabs,
    int safeTabIndex,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF111827)),
      );
    }

    if (state.errorMessage != null) {
      return _buildErrorState(state.errorMessage!);
    }

    if (state.profile == null) {
      return const Center(child: Text('No profile data available'));
    }

    return tabs[safeTabIndex].widget;
  }

  Widget _buildCacheBanner(DateTime? timestamp) {
    final timeText = timestamp != null
        ? 'Last updated: ${_formatTimeAgo(timestamp)}'
        : 'Offline mode';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          Icon(Icons.offline_bolt, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Showing cached data',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  timeText,
                  style: TextStyle(color: Colors.orange.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(userProfileProvider.notifier).refreshProfile();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher(List<_TabConfig> tabs, int safeTabIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomHeader(title: 'Your Profile'),

          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final config = entry.value;
                final isSelected = safeTabIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF111827)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            config.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            config.label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab configuration helper class
class _TabConfig {
  final String label;
  final IconData icon;
  final Widget widget;

  const _TabConfig({
    required this.label,
    required this.icon,
    required this.widget,
  });
}
