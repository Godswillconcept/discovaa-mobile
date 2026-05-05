import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovaa/shared/presentation/widgets/bottom_nav_bar.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/session_provider.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainNavigationPage({super.key, required this.navigationShell});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will update the selected index based on route, though we might need
    // to do this in build if Provider changes dynamically.
  }

  @override
  Widget build(BuildContext context) {
    // Use the effective user role provider to ensure consistent role state
    // This prevents race conditions between session state and user entity
    final isProvider = ref.watch(isServiceProvider);
    final session = ref.watch(sessionProvider);
    final authState = ref.watch(authProvider);

    // Check if auth is still loading (initial app start check)
    final isAuthLoading =
        authState.isLoading ||
        (authState.valueOrNull?.isInitial ?? true) && authState.isLoading;

    // Get the current user if authenticated
    final user = authState.valueOrNull?.user;
    final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;

    // If auth is still loading, show loading indicator
    // But if we have an authenticated user, proceed to show content
    // (session will be synced by effectiveUserRoleProvider)
    if (isAuthLoading && !isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If session isn't initialized but we have an authenticated user,
    // sync the session state now to prevent blocking the UI
    if (!session.isInitialized && isAuthenticated && user != null) {
      final userRole = authState.valueOrNull?.userRole;
      if (userRole != null) {
        // Schedule the session update for next frame to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(sessionProvider.notifier).restoreSession(userRole);
          }
        });
      }
    }

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          // Tab count is now fixed, so index maps directly to branch index
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        showServicesTab: isProvider,
      ),
    );
  }
}
