import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovaa/shared/presentation/widgets/bottom_nav_bar.dart';
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

    // If session isn't initialized yet (during auth check), show loading indicator
    // to prevent UI flicker before role is determined
    if (!session.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
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
