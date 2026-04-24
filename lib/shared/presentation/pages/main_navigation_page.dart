import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovaa/shared/presentation/widgets/bottom_nav_bar.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:discovaa/core/constants/feature_flags.dart';

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

  /// Map visual nav index to actual shell branch index
  /// This is needed because feature flags change the number of nav items
  int _mapNavIndexToBranchIndex(int navIndex) {
    final profileState = ref.read(userProfileProvider);
    final isProvider = profileState.profile?.isProvider ?? false;

    // Build the list of enabled branches in order
    final enabledBranches = <int>[];
    int branchIndex = 0;

    // Home (always enabled)
    enabledBranches.add(branchIndex++);

    // Dashboard (M3)
    if (FeatureFlags.enableDashboard) {
      enabledBranches.add(branchIndex++);
    }

    // Bookings (always enabled)
    enabledBranches.add(branchIndex++);

    // Messages (M2)
    if (FeatureFlags.enableMessaging) {
      enabledBranches.add(branchIndex++);
    }

    // Services (M1 - provider only)
    if (isProvider) {
      enabledBranches.add(branchIndex++);
    }

    // Return the actual branch index for the given nav index
    if (navIndex < enabledBranches.length) {
      return enabledBranches[navIndex];
    }
    return 0; // Default to home
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
          final branchIndex = _mapNavIndexToBranchIndex(index);
          widget.navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == widget.navigationShell.currentIndex,
          );
        },
        showServicesTab: isProvider,
      ),
    );
  }
}
