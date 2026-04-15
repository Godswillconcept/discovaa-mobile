import 'package:discovaa/features/authentication/presentation/widgets/auth_field_label.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_header.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_safe_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/features/authentication/presentation/providers/session_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/signup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/widgets/custom_buttons.dart';
import 'package:country_picker/country_picker.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

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

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        // Simulate API call
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
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
