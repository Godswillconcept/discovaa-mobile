import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/notifications/presentation/widgets/notification_bottom_sheet.dart';
import 'package:discovaa/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:discovaa/features/profile/presentation/providers/saved_services_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
              // Favorites icon with badge
              Consumer(
                builder: (context, ref, child) {
                  final savedCount = ref.watch(savedServicesCountProvider);
                  final hasSavedItems = savedCount > 0;

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
                      if (hasSavedItems)
                        Positioned(
                          top: -2,
                          right: 2,
                          child: Container(
                            height: 18,
                            width: savedCount > 99 ? 28 : 18,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE91E63,
                              ), // Pink/red for favorites
                              shape: savedCount > 99
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: savedCount > 99
                                  ? BorderRadius.circular(9)
                                  : null,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                savedCount > 99 ? '99+' : savedCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: savedCount > 99 ? 9 : 10,
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
              NotificationBellBadge(onTap: () => _openNotifications(context)),
              InkWell(
                onTap: () => _openUserProfile(context),
                borderRadius: BorderRadius.circular(20),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  backgroundImage: AssetImage(
                    'assets/images/placeholders/user_avatar.png',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
