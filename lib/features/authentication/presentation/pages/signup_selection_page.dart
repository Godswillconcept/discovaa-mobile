import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/authentication/presentation/providers/registration_flow_provider.dart';
import 'package:discovaa/core/utils/clippers.dart';

/// Simple state provider for managing the two-level selection UI
final _selectionLevelProvider = StateProvider<bool>((ref) => true);

class SignupSelectionPage extends ConsumerWidget {
  const SignupSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationState = ref.watch(registrationFlowProvider);
    final isInitialLevel = ref.watch(_selectionLevelProvider);
    final selectedRole = registrationState.selectedRole;

    return PopScope(
      canPop: isInitialLevel,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!isInitialLevel) {
          ref.read(_selectionLevelProvider.notifier).state = true;
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              HeaderClipper(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/images/logos/logo.png',
                        width: 160,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: InkWell(
                        onTap: () {
                          if (isInitialLevel) {
                            // Check if we can pop to avoid "nothing to pop" error
                            if (GoRouter.of(context).canPop()) {
                              context.pop();
                            } else {
                              context.go(RouteNames.onboarding);
                            }
                          } else {
                            ref.read(_selectionLevelProvider.notifier).state =
                                true;
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Back",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  // Image Blob Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Image.asset(
                        'assets/images/illustrations/mechanic.png',
                        height: 250,
                        width: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          width: 250,
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, size: 100),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Join Us!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "To begin this journey, tell us what type of account you'd be opening.",
                          style: TextStyle(
                            color: Colors.grey,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Option 1
                        _buildOption(
                          context,
                          role: isInitialLevel
                              ? UserRole.user
                              : UserRole.individualProvider,
                          isSelected: isInitialLevel
                              ? selectedRole == UserRole.user
                              : selectedRole == UserRole.individualProvider,
                          icon: Icons.person_outline,
                          title: isInitialLevel
                              ? "User"
                              : "Individual Service Provider",
                          subtitle:
                              "Service provider but don't have a registered business? This is for you.",
                          onTap: () {
                            if (isInitialLevel) {
                              // Just select the role, arrow handles navigation
                              ref
                                  .read(registrationFlowProvider.notifier)
                                  .setRole(UserRole.user);
                            } else {
                              if (selectedRole == UserRole.individualProvider) {
                                context.push(
                                  RouteNames.register,
                                  extra: UserRole.individualProvider.name,
                                );
                              } else {
                                ref
                                    .read(registrationFlowProvider.notifier)
                                    .setRole(UserRole.individualProvider);
                              }
                            }
                          },
                          onArrowTap: () {
                            if (isInitialLevel) {
                              // User selected → navigate directly to register
                              ref
                                  .read(registrationFlowProvider.notifier)
                                  .setRole(UserRole.user);
                              context.push(
                                RouteNames.register,
                                extra: UserRole.user.name,
                              );
                            } else {
                              ref
                                  .read(registrationFlowProvider.notifier)
                                  .setRole(UserRole.individualProvider);
                              context.push(
                                RouteNames.register,
                                extra: UserRole.individualProvider.name,
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // Option 2
                        _buildOption(
                          context,
                          role: isInitialLevel
                              ? UserRole.individualProvider
                              : UserRole.businessProvider,
                          isSelected: isInitialLevel
                              ? (selectedRole == UserRole.individualProvider ||
                                    selectedRole == UserRole.businessProvider)
                              : selectedRole == UserRole.businessProvider,
                          icon: Icons.business_center_outlined,
                          title: isInitialLevel
                              ? "Service Provider"
                              : "Business Service Provider",
                          subtitle:
                              "Own or belong to a company? This is for you.",
                          onTap: () {
                            if (isInitialLevel) {
                              // Show provider sub-selection
                              ref.read(_selectionLevelProvider.notifier).state =
                                  false;
                              ref
                                  .read(registrationFlowProvider.notifier)
                                  .setRole(UserRole.individualProvider);
                            } else {
                              if (selectedRole == UserRole.businessProvider) {
                                context.push(
                                  RouteNames.register,
                                  extra: UserRole.businessProvider.name,
                                );
                              } else {
                                ref
                                    .read(registrationFlowProvider.notifier)
                                    .setRole(UserRole.businessProvider);
                              }
                            }
                          },
                          onArrowTap: () {
                            if (isInitialLevel) {
                              // Service Provider selected → show provider sub-selection
                              ref.read(_selectionLevelProvider.notifier).state =
                                  false;
                              ref
                                  .read(registrationFlowProvider.notifier)
                                  .setRole(UserRole.individualProvider);
                            } else {
                              ref
                                  .read(registrationFlowProvider.notifier)
                                  .setRole(UserRole.businessProvider);
                              context.push(
                                RouteNames.register,
                                extra: UserRole.businessProvider.name,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: "Sign In",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.push(RouteNames.login);
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required UserRole role,
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required VoidCallback onArrowTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Icon(icon, size: 24, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onArrowTap,
              icon: const Icon(Icons.arrow_forward, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
