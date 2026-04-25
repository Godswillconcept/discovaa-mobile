import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/notifications/presentation/widgets/notification_bottom_sheet.dart';
import 'package:discovaa/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/router/route_names.dart';

class MainHeader extends ConsumerWidget {
  const MainHeader({super.key});

  void _openFavorites(BuildContext context) {
    context.push(RouteNames.favorites);
  }

  void _openNotifications(BuildContext context) {
    NotificationBottomSheet.show(context);
  }

  void _openUserProfile(BuildContext context) {
    context.push(RouteNames.userProfile);
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(authProvider.notifier).logout();

      if (success && context.mounted) {
        context.go(RouteNames.login);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to logout'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        20,
        30,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A), // Lighter black
            Color(0xFF0F0F0F), // Darker black
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/images/logos/logo.png',
                height: 35,
                errorBuilder: (context, error, stackTrace) => const Text(
                  'DISCOVAA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          // Right-side actions
          Row(
            children: [
              NotificationBellBadge(onTap: () => _openNotifications(context)),
              // Favorites icon with badge
              Consumer(
                builder: (context, ref, child) {
                  final favoriteCount = ref
                      .watch(favoriteArtisansProvider)
                      .length;
                  final hasFavorites = favoriteCount > 0;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: () => _openFavorites(context),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.favorite_outline,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      if (hasFavorites)
                        Positioned(
                          top: -2,
                          right: 2,
                          child: Container(
                            height: 18,
                            width: favoriteCount > 99 ? 28 : 18,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE91E63,
                              ), // Pink/red for favorites
                              shape: favoriteCount > 99
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: favoriteCount > 99
                                  ? BorderRadius.circular(9)
                                  : null,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                favoriteCount > 99
                                    ? '99+'
                                    : favoriteCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: favoriteCount > 99 ? 9 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // Logout icon
              InkWell(
                onTap: () => _handleLogout(context, ref),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.logout, color: Colors.white, size: 26),
                ),
              ),

              Consumer(
                builder: (context, ref, child) {
                  final userEntity = ref.watch(currentUserProvider);

                  // Determine profile image URL and initials from UserEntity
                  String? profileImageUrl;
                  String? initials;

                  if (userEntity != null) {
                    profileImageUrl = userEntity.photoUrl;
                    // Extract initials from displayName
                    final displayName = userEntity.displayName;
                    if (displayName.isNotEmpty) {
                      final parts = displayName.trim().split(RegExp(r'\s+'));
                      if (parts.length > 1 &&
                          parts[0].isNotEmpty &&
                          parts[1].isNotEmpty) {
                        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
                        initials = parts[0][0].toUpperCase();
                      }
                    }
                    // If still no initials, use email first character
                    if (initials == null || initials.isEmpty) {
                      initials = userEntity.email.isNotEmpty
                          ? userEntity.email[0].toUpperCase()
                          : '?';
                    }
                  }

                  // Show profile image if available, otherwise show initials
                  final hasProfileImage =
                      profileImageUrl != null &&
                      profileImageUrl.isNotEmpty &&
                      profileImageUrl != 'null';

                  String? resolvedImageUrl = profileImageUrl;
                  if (hasProfileImage && resolvedImageUrl != null) {
                    if (resolvedImageUrl.startsWith('/')) {
                      resolvedImageUrl =
                          '${ApiEndpoints.baseUrl}$resolvedImageUrl';
                    }
                  }

                  return InkWell(
                    onTap: () => _openUserProfile(context),
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      backgroundImage:
                          hasProfileImage && resolvedImageUrl != null
                          ? CachedNetworkImageProvider(resolvedImageUrl)
                          : null,
                      onBackgroundImageError: hasProfileImage
                          ? (exception, stackTrace) {
                              debugPrint(
                                'Failed to load profile image: $exception',
                              );
                            }
                          : null,
                      child: hasProfileImage
                          ? null
                          : Text(
                              initials ?? '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
