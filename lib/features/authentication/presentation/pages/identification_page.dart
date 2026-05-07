import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/core/constants/app_theme.dart' as app_theme;
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/identification_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/registration_flow_provider.dart';
import 'package:discovaa/shared/presentation/widgets/main_header.dart';
import 'package:discovaa/features/home/presentation/providers/image_upload_provider.dart';
import 'package:discovaa/features/home/presentation/providers/verification_provider.dart';
import 'package:discovaa/features/home/presentation/widgets/verification_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Revamped Identification Page
///
/// Features:
/// - ID number input with form validation (max 30 chars, alphanumeric)
/// - Connectivity state management
/// - File upload integration (maintains existing mechanism)
/// - UI matching the provided design
class IdentificationPage extends ConsumerStatefulWidget {
  const IdentificationPage({super.key});

  @override
  ConsumerState<IdentificationPage> createState() => _IdentificationPageState();
}

class _IdentificationPageState extends ConsumerState<IdentificationPage> {
  late TextEditingController _idNumberController;
  late FocusNode _idNumberFocusNode;

  @override
  void initState() {
    super.initState();
    _idNumberController = TextEditingController();
    _idNumberFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    _idNumberFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identificationState = ref.watch(identificationProvider);
    final isProvider = _effectiveRole.isProvider;

    // Listen to image upload state
    final imageUploadState = ref.watch(imageUploadProvider);

    // Sync uploaded images with identification state
    _syncUploadedImages(imageUploadState);

    final idVerified = identificationState.identification.isIdVerified;
    final businessVerified =
        identificationState.identification.isBusinessVerified;
    final allVerified = isProvider
        ? (idVerified && businessVerified)
        : idVerified;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Header Section
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Verification Section
                    _buildAccountVerificationSection(
                      context,
                      identificationState,
                      isProvider,
                      idVerified,
                      businessVerified,
                    ),
                    SizedBox(height: 24.h),

                    // Error Message (if any)
                    if (identificationState.errorMessage != null)
                      _buildErrorMessage(identificationState.errorMessage!),

                    // Connectivity Warning
                    if (identificationState.connectivityState ==
                        ConnectivityState.disconnected)
                      _buildConnectivityWarning(),

                    SizedBox(height: 32.h),

                    // Action Buttons
                    _buildActionButtons(
                      context,
                      allVerified,
                      identificationState.isLoading,
                      isProvider,
                      identificationState,
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  UserRole get _effectiveRole {
    final authRole = ref.watch(authProvider).value?.userRole;
    if (authRole != null) return authRole;

    final registrationRole = ref.watch(registrationFlowProvider).selectedRole;
    return registrationRole ?? UserRole.user;
  }

  /// Sync uploaded images from imageUploadProvider to identificationProvider
  void _syncUploadedImages(ImageUploadState imageUploadState) {
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (imageUploadState.frontImagePath != null &&
          imageUploadState.frontUploadStatus == UploadStatus.success) {
        ref
            .read(identificationProvider.notifier)
            .updateFrontImage(imageUploadState.frontImagePath!);
      }
      if (imageUploadState.backImagePath != null &&
          imageUploadState.backUploadStatus == UploadStatus.success) {
        ref
            .read(identificationProvider.notifier)
            .updateBackImage(imageUploadState.backImagePath!);
      }
    });
  }

  /// Build the header section using shared MainHeader widget
  Widget _buildHeader(BuildContext context) {
    return const MainHeader();
  }

  /// Build the account verification section with ID input
  Widget _buildAccountVerificationSection(
    BuildContext context,
    IdentificationPageState state,
    bool isProvider,
    bool idVerified,
    bool businessVerified,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          // Title and description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar placeholder
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.grey.shade400,
                  size: 32.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account verification',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Only show this prompt if not already verified
                    if (!idVerified)
                      Text(
                        'Upload a valid ID to verify your account. You can skip this step and complete it later.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),

          // Account Verification Status Header
          Text(
            'Account Verification Status',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20.h),

          // ID Number Input Field
          _buildIdNumberInput(state),
          SizedBox(height: 16.h),

          // ID Verification Card
          _buildVerificationCard(
            title: 'ID Verification',
            subtitle: 'Passport, national ID card, driver\'s license',
            isCompleted: idVerified,
            onUpload: () => _showVerificationModal(context, false),
          ),

          // Business Verification (for providers)
          if (isProvider) ...[
            SizedBox(height: 16.h),
            _buildVerificationCard(
              title: 'Business Verification',
              subtitle: 'Business Registration Certificate',
              isCompleted: businessVerified,
              onUpload: () => _showVerificationModal(context, true),
            ),
          ],

          // Back link
          SizedBox(height: 16.h),
          TextButton(
            onPressed: () {
              // Check if we can pop to avoid "nothing to pop" error
              if (GoRouter.of(context).canPop()) {
                context.pop();
              } else {
                // Fallback: navigate to complete profile page if nothing to pop
                context.go(RouteNames.completeProfile);
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Back',
              style: TextStyle(color: Colors.blue, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  /// Build ID number input field with validation
  Widget _buildIdNumberInput(IdentificationPageState state) {
    final hasError = state.hasIdNumberError;
    final errorMessage = state.idNumberErrorMessage;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID number',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _idNumberController,
            focusNode: _idNumberFocusNode,
            onChanged: (value) {
              ref.read(identificationProvider.notifier).updateIdNumber(value);
            },
            maxLength: 30,
            decoration: InputDecoration(
              hintText:
                  'Enter ID number (max 30 characters, letters & numbers)',
              hintStyle: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : app_theme.AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              counterText: '',
            ),
            inputFormatters: [
              // Only allow alphanumeric characters and spaces
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
              LengthLimitingTextInputFormatter(30),
            ],
          ),
          SizedBox(height: 8.h),
          // Helper text
          Text(
            'ID number and document are required for verification. Max 30 characters, alphanumeric only.',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
          ),
          // Error message
          if (hasError && errorMessage != null) ...[
            SizedBox(height: 4.h),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 12.sp, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  /// Build verification card for ID or Business verification
  Widget _buildVerificationCard({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onUpload,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey.shade400,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (!isCompleted)
            ElevatedButton(
              onPressed: onUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Upload',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.green.shade600, size: 16.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build error message widget
  Widget _buildErrorMessage(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade600, fontSize: 13.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build connectivity warning
  Widget _buildConnectivityWarning() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange.shade600, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'No internet connection. Please check your network.',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build action buttons (Skip for now and Continue)
  Widget _buildActionButtons(
    BuildContext context,
    bool allVerified,
    bool isLoading,
    bool isProvider,
    IdentificationPageState state,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          // Skip for now button
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Permanently skip verification (persist to storage)
                      await ref
                          .read(identificationProvider.notifier)
                          .permanentlySkipVerification();
                      // Update auth state to allow navigation to home
                      ref.read(authProvider.notifier).skipVerification();
                      if (context.mounted) {
                        context.go(RouteNames.home);
                      }
                    },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          // Continue button
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => _handleContinue(context, state, allVerified),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle continue button press
  Future<void> _handleContinue(
    BuildContext context,
    IdentificationPageState state,
    bool allVerified,
  ) async {
    // Mark form as submitted to show validation errors
    ref.read(identificationProvider.notifier).markFormSubmitted();

    // If already verified, just navigate home
    if (allVerified) {
      ref.read(authProvider.notifier).markIdentityVerified();
      context.go(RouteNames.home);
      return;
    }

    // Validate and submit
    final success = await ref.read(identificationProvider.notifier).submit();

    if (!mounted) return;

    if (success) {
      ref.read(authProvider.notifier).markIdentityVerified();
      // ignore: use_build_context_synchronously
      context.go(RouteNames.home);
    }
  }

  /// Show verification modal dialog
  void _showVerificationModal(BuildContext context, bool isBusiness) {
    ref.read(imageUploadProvider.notifier).reset();

    // Set the correct verification step
    if (isBusiness) {
      ref.read(verificationProvider.notifier).startBusinessVerification();
    } else {
      ref.read(verificationProvider.notifier).startIdVerification();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VerificationFlowDialog(),
    ).then((_) {
      // After dialog closes, check if verification was successful
      final verificationState = ref.read(verificationProvider);

      if (verificationState.idVerified && !isBusiness) {
        ref.read(identificationProvider.notifier).markIdVerified();
      }

      if (verificationState.businessVerified && isBusiness) {
        ref.read(identificationProvider.notifier).markBusinessVerified();
      }
    });
  }
}
