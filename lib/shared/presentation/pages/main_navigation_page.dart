import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovaa/shared/presentation/widgets/bottom_nav_bar.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';

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
    final profileState = ref.watch(userProfileProvider);
    final isProvider = profileState.profile?.isProvider ?? false;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
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
