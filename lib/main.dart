import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/app/app.dart';
import 'package:discovaa/core/constants/feature_flags.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await configureDependencies();

  // Set feature flags based on current milestone
  // Modify this call when creating milestone branches
  // Current: Milestone 1 (Board Presentation)
  FeatureFlags.setMilestone1();

  runApp(const ProviderScope(child: DiscovaaApp()));
}
