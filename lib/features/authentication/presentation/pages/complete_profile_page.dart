import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_initializer_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_field_label.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_header.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_safe_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/features/authentication/presentation/providers/session_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/signup_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/widgets/custom_buttons.dart';
import 'package:country_picker/country_picker.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  final bool fromLogin;
  const CompleteProfilePage({super.key, this.fromLogin = false});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessDescriptionController =
      TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String? _selectedCountry;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Load existing user data when coming from login
    if (widget.fromLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingUserData();
      });
    }
  }

  /// Load existing user data for the form when fromLogin is true
  Future<void> _loadExistingUserData() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // First get data from authProvider (basic user info from login)
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user != null) {
      _displayNameController.text = user.displayName;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _selectedCountry = user.country;
      if (user.country != null) {
        _countryController.text = user.country!;
      }
    }

    // Then try to get more complete data from userProfileProvider
    // Trigger userProfileProvider to load full profile data in background
    try {
      await ref.read(userProfileProvider.notifier).refresh();

      // Get updated profile data if available
      final profileState = ref.read(userProfileProvider);
      final profile = profileState.profile;

      if (profile != null) {
        // Prefer profile data over auth data if available
        if (profile.displayName != null && profile.displayName!.isNotEmpty) {
          _displayNameController.text = profile.displayName!;
        }
        if (profile.phone != null && profile.phone!.isNotEmpty) {
          _phoneController.text = profile.phone!;
        }
        if (profile.country != null) {
          _selectedCountry = profile.country;
          _countryController.text = profile.country!;
        }
        // Provider-specific data from locations
        if (profile.locations.isNotEmpty) {
          final primaryLocation = profile.locations.first;
          if (primaryLocation.address != null) {
            _addressController.text = primaryLocation.address!;
          }
        }
      }
    } catch (e) {
      // If profile fetch fails, continue with auth user data only
      debugPrint('[_CompleteProfilePageState] Error loading profile: $e');
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        if (widget.fromLogin) {
          // Resumed registration flow - update profile via API
          final success = await ref
              .read(authProvider.notifier)
              .updateProfile(
                displayName: _displayNameController.text,
                phone: _phoneController.text,
                address: _addressController.text,
                country: _selectedCountry,
                businessName: _businessNameController.text,
                businessDescription: _businessDescriptionController.text,
              );

          if (!success) {
            if (mounted) {
              final error = ref.read(authProvider).errorMessage;
              _showErrorSnackBar(
                error ?? 'Failed to update profile. Please try again.',
              );
            }
            return;
          }

          // Set up session after profile completion
          final authState = ref.read(authProvider);
          final user = authState.user;
          if (user != null) {
            UserRole userRole;
            switch (user.role) {
              case 'provider':
                userRole = UserRole.individualProvider;
                break;
              case 'business':
                userRole = UserRole.businessProvider;
                break;
              default:
                userRole = UserRole.user;
            }
            ref.read(sessionProvider.notifier).signIn(userRole);

            // Persist auth state
            final storage = ref.read(secureTokenStorageProvider);
            final accessToken = storage.getAccessToken();
            final sessionToken = storage.getSessionToken();
            final refreshToken = storage.getRefreshToken();

            await ref
                .read(authInitializerProvider.notifier)
                .setAuthenticated(
                  accessToken: accessToken ?? '',
                  sessionToken: sessionToken,
                  refreshToken: refreshToken,
                  role: user.role,
                  user: user,
                );

            // Register device token after successful profile completion
            await _registerDeviceToken();
          }

          if (mounted) {
            // Navigate based on user role from auth provider
            // (signupProvider role isn't set in resumed flow)
            final user = ref.read(authProvider).user;
            final isProvider =
                user != null &&
                (user.role == 'provider' || user.role == 'business');
            if (isProvider) {
              context.go(RouteNames.identification);
            } else {
              context.go(RouteNames.home);
            }
          }
        } else {
          // Normal registration flow - save to local state and navigate to login
          final notifier = ref.read(signupProvider.notifier);
          final state = ref.read(signupProvider);

          notifier.updateProfileInfo(
            displayName: _displayNameController.text,
            phone: _phoneController.text,
            address: _addressController.text,
            businessName: _businessNameController.text,
            businessDescription: _businessDescriptionController.text,
            country: _selectedCountry,
          );
          // Persist the registered role into session
          ref
              .read(sessionProvider.notifier)
              .completeRegistration(state.selectedRole);
          // Navigate to login
          context.push(
            '/login',
            extra: {'fromOnboarding': false, 'fromRegistration': true},
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Failed to save profile. Please try again.');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  /// Register device token for push notifications
  /// This is a best-effort operation - failures don't block flow
  Future<void> _registerDeviceToken() async {
    try {
      // Get FCM token - for now use a placeholder
      // In production, this should come from FirebaseMessaging.instance.getToken()
      const String? fcmToken = null; // TODO: Integrate with Firebase Messaging

      if (fcmToken == null || fcmToken.isEmpty) {
        // No FCM token available, skip registration
        return;
      }

      // Register device token via provider
      await ref
          .read(authProvider.notifier)
          .registerDeviceToken(token: fcmToken);
    } catch (e) {
      // Device registration is best-effort, don't block flow
      debugPrint(
        '[_CompleteProfilePageState] Device token registration failed: $e',
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(signupProvider.notifier).goToOtp();
        context.pop();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                AuthHeader(
                  title: "Complete Your Profile!",
                  step: "03/03",
                  onBack: () {
                    ref.read(signupProvider.notifier).goToOtp();
                    context.pop();
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "For the purpose of industry regulation, your details are required.",
                          style: TextStyle(
                            color: Colors.grey,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        const Divider(height: 40),

                        // Display Name Field
                        const AuthFieldLabel(label: "Display name"),
                        TextFormField(
                          controller: _displayNameController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => value == null || value.isEmpty
                              ? "Display name is required"
                              : null,
                          decoration: InputDecoration(
                            hintText: "Enter your display name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const AuthFieldLabel(label: "Phone number"),
                        IntlPhoneField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            hintText: '09091234567',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          initialCountryCode: 'NG',
                          onChanged: (phone) {
                            // phone.completeNumber
                          },
                          dropdownIconPosition: IconPosition.trailing,
                          flagsButtonPadding: const EdgeInsets.only(left: 8),
                          showDropdownIcon: true,
                          dropdownTextStyle: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),

                        const AuthFieldLabel(label: "Your address"),
                        TextFormField(
                          controller: _addressController,
                          validator: (value) => value == null || value.isEmpty
                              ? "Required"
                              : null,
                          decoration: InputDecoration(
                            hintText: "Please enter full address",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // DYNAMIC FIELDS FOR PROVIDERS
                        if (state.selectedRole.isProvider) ...[
                          const SizedBox(height: 20),
                          AuthFieldLabel(
                            label:
                                state.selectedRole == UserRole.businessProvider
                                ? "Business Name"
                                : "Professional Name",
                          ),
                          TextFormField(
                            controller: _businessNameController,
                            validator: (value) => value == null || value.isEmpty
                                ? "Required"
                                : null,
                            decoration: InputDecoration(
                              hintText:
                                  state.selectedRole ==
                                      UserRole.businessProvider
                                  ? "Enter business name"
                                  : "Enter your professional name",
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AuthFieldLabel(
                            label:
                                state.selectedRole == UserRole.businessProvider
                                ? "Business Description"
                                : "Service Bio",
                          ),
                          TextFormField(
                            controller: _businessDescriptionController,
                            validator: (value) => value == null || value.isEmpty
                                ? "Required"
                                : null,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  state.selectedRole ==
                                      UserRole.businessProvider
                                  ? "Enter business description"
                                  : "Enter your service bio/description",
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        const AuthFieldLabel(label: "Country of residence"),
                        TextFormField(
                          readOnly: true,
                          controller: _countryController,
                          onTap: () {
                            showCountryPicker(
                              context: context,
                              showPhoneCode: false,
                              onSelect: (Country country) {
                                setState(() {
                                  _selectedCountry = country.name;
                                  _countryController.text = country.name;
                                });
                              },
                              countryListTheme: CountryListThemeData(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(40.0),
                                  topRight: Radius.circular(40.0),
                                ),
                                inputDecoration: InputDecoration(
                                  labelText: 'Search',
                                  hintText: 'Start typing to search',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: const Color(
                                        0xFF8C98A8,
                                      ).withValues(alpha: 0.2),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? "Required"
                              : null,
                          decoration: InputDecoration(
                            hintText: "Please select",
                            suffixIcon: const Icon(Icons.keyboard_arrow_down),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),
                        AppPrimaryButton(
                          onPressed: _isLoading ? null : _saveAndContinue,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text("Save & Continue"),
                        ),
                        const SizedBox(height: 20),
                        const AuthSafeInfo(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
