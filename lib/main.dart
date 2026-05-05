import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/app/app.dart';
import 'package:discovaa/core/constants/feature_flags.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database
  tz.initializeTimeZones();

  // Initialize dependencies
  await configureDependencies();

  // Set feature flags based on current milestone
  // Modify this call when creating milestone branches
  // Current: Full app (Milestone 3)
  FeatureFlags.setMilestone3();

  runApp(const ProviderScope(child: DiscovaaApp()));
}
