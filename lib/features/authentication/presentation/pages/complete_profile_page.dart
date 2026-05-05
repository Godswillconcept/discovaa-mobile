import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/registration_flow_provider.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_field_label.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_header.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_safe_info.dart';
import 'package:discovaa/core/widgets/custom_buttons.dart';
import 'package:discovaa/core/widgets/app_alert_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
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
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessDescriptionController =
      TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String? _selectedCountryIso2;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _completePhoneNumber;

  /// Determine the effective role based on context
  /// Prefer authenticated profile data, then fall back to registration state.
  UserRole? get _effectiveRole {
    final authRole = ref.read(authProvider).value?.userRole;
    if (authRole != null) return authRole;

    final registrationRole = ref.read(registrationFlowProvider).selectedRole;
    return registrationRole;
  }

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

    // Get data from authProvider
    final authState = ref.read(authProvider);
    final user = authState.value?.user;
    if (user != null) {
      _displayNameController.text = user.displayName;
      _phoneController.text = user.phone ?? '';
      _completePhoneNumber = user.phone;
      _addressController.text = user.address ?? '';
      if (user.country != null) {
        _countryController.text = user.country!;
        _selectedCountryIso2 = user.country;
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call updateProfile API
      final success = await ref
          .read(authProvider.notifier)
          .updateProfile(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            displayName: _displayNameController.text,
            phone: _completePhoneNumber ?? _phoneController.text,
            address: _addressController.text,
            countryIso2: _selectedCountryIso2,
            businessName: _businessNameController.text,
            businessDescription: _businessDescriptionController.text,
          );

      if (mounted) {
        if (success) {
          // Clear registration flow state if coming from registration
          if (!widget.fromLogin) {
            ref.read(registrationFlowProvider.notifier).clear();
          }

          // Navigate to identification page for ALL users (identity verification required)
          context.go(RouteNames.identification);
        } else {
          // Show error message
          final errorMessage =
              ref.read(authProvider).value?.errorMessage ??
              'Failed to save profile. Please try again.';
          _showErrorSnackBar(errorMessage);
        }
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
    _firstNameController.dispose();
    _lastNameController.dispose();
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
    final authState = ref.watch(authProvider);
    final errorMessage = authState.value?.errorMessage;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(registrationFlowProvider.notifier).reset();
        // Check if we can pop to avoid "nothing to pop" error
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          // Fallback: navigate to register page if nothing to pop
          context.go(RouteNames.register);
        }
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
                    ref.read(registrationFlowProvider.notifier).reset();
                    // Check if we can pop to avoid "nothing to pop" error
                    if (GoRouter.of(context).canPop()) {
                      context.pop();
                    } else {
                      // Fallback: navigate to register page if nothing to pop
                      context.go(RouteNames.register);
                    }
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

                        // First Name Field
                        const AuthFieldLabel(label: "First name"),
                        TextFormField(
                          controller: _firstNameController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => value == null || value.isEmpty
                              ? "First name is required"
                              : null,
                          decoration: InputDecoration(
                            hintText: "Enter your first name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Last Name Field
                        const AuthFieldLabel(label: "Last name"),
                        TextFormField(
                          controller: _lastNameController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => value == null || value.isEmpty
                              ? "Last name is required"
                              : null,
                          decoration: InputDecoration(
                            hintText: "Enter your last name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

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

                        // Phone Number Field
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
                            setState(() {
                              _completePhoneNumber = phone.completeNumber;
                            });
                          },
                          dropdownIconPosition: IconPosition.trailing,
                          flagsButtonPadding: const EdgeInsets.only(left: 8),
                          showDropdownIcon: true,
                          dropdownTextStyle: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),

                        // Address Field
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

                        // Dynamic Fields for Providers
                        if (_effectiveRole?.isProvider ?? false) ...[
                          const SizedBox(height: 20),
                          AuthFieldLabel(
                            label: _effectiveRole == UserRole.businessProvider
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
                                  _effectiveRole == UserRole.businessProvider
                                  ? "Enter business name"
                                  : "Enter your professional name",
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AuthFieldLabel(
                            label: _effectiveRole == UserRole.businessProvider
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
                                  _effectiveRole == UserRole.businessProvider
                                  ? "Enter business description"
                                  : "Enter your service bio/description",
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Country Field
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
                                  _selectedCountryIso2 = country.countryCode;
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

                        const SizedBox(height: 20),

                        // Show error message if profile update failed
                        if (authState.hasError || errorMessage != null)
                          Builder(
                            builder: (context) {
                              return AppAlertMessage(
                                type: AlertType.error,
                                message:
                                    errorMessage ??
                                    'Failed to save profile. Please try again.',
                                onDismiss: () {
                                  ref.read(authProvider.notifier).clearError();
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 40),

                        // Save & Continue Button
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
