import 'package:country_picker/country_picker.dart';
import 'package:discovaa/features/profile/domain/entities/user_profile.dart';
import 'package:discovaa/features/profile/domain/entities/profile_enums.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:discovaa/features/profile/presentation/widgets/shared/status_badge.dart';
import 'package:discovaa/features/profile/presentation/widgets/shared/profile_field_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:discovaa/features/profile/presentation/providers/profile_connectivity_provider.dart';

/// User Info Tab - Main profile information with identity verification
class UserInfoTab extends ConsumerWidget {
  const UserInfoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.profile;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          _ProfileHeaderCard(profile: profile),
          const SizedBox(height: 24),

          // Personal Information Section
          ProfileSectionCard(
            title: 'Personal Information',
            subtitle: 'Your account details and preferences',
            children: [
              ProfileFieldRow(
                label: 'Display name',
                value: profile.displayName ?? '',
                placeholder: 'Not set',
                onEdit: () => _showEditDisplayNameDialog(context, ref, profile),
              ),
              ProfileFieldRow(
                label: 'First name',
                value: profile.firstName ?? '',
                placeholder: 'Not set',
                onEdit: () => _showEditFirstNameDialog(context, ref, profile),
              ),
              ProfileFieldRow(
                label: 'Last name',
                value: profile.lastName ?? '',
                placeholder: 'Not set',
                onEdit: () => _showEditLastNameDialog(context, ref, profile),
              ),
              ProfileFieldRow(
                label: 'Phone number',
                value: profile.formattedPhone,
                onEdit: () => _showEditPhoneDialog(context, ref, profile),
              ),
              ProfileFieldRow(
                label: 'Country',
                value: profile.country ?? '',
                placeholder: 'Not set',
                onEdit: () => _showCountryPicker(context, ref, profile),
              ),
              ProfileFieldRow(
                label: 'Account type',
                value: profile.accountType.displayName,
                isEditable: false,
              ),
              if (profile.providerTypeRaw != null)
                ProfileFieldRow(
                  label: 'Provider type',
                  value: profile.providerTypeRaw!,
                  isEditable: false,
                  showDivider: false,
                ),
            ],
          ),

          // Identity Verification Section
          ProfileSectionCard(
            title: 'Identity Verification',
            subtitle: 'Upload documents to verify your identity',
            action: StatusBadge.verification(
              profile.identityVerification?.status ??
                  VerificationStatus.unverified,
            ),
            children: [
              ProfileFieldRow(
                label: 'ID Number',
                value: profile.identityVerification?.idNumber ?? '',
                placeholder: 'Not set',
                onEdit: () => _showEditIdNumberDialog(context, ref, profile),
              ),
              const SizedBox(height: 16),
              _IdUploadRow(
                label: 'Front of ID',
                hasDocument:
                    profile.identityVerification?.hasFrontImage ?? false,
                onUpload: () => _UserInfoTabHelper.showUploadDialog(
                  context,
                  ref,
                  'Front of ID',
                  'idFront',
                ),
              ),
              const SizedBox(height: 12),
              _IdUploadRow(
                label: 'Back of ID',
                hasDocument:
                    profile.identityVerification?.hasBackImage ?? false,
                onUpload: () => _UserInfoTabHelper.showUploadDialog(
                  context,
                  ref,
                  'Back of ID',
                  'idBack',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDisplayNameDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    _showEditDialog(
      context: context,
      title: 'Display Name',
      value: profile.displayName ?? '',
      hint: 'Enter display name',
      maxLength: 50,
      onSave: (value) {
        ref.read(userProfileProvider.notifier).updateFields(displayName: value);
      },
    );
  }

  void _showEditFirstNameDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    _showEditDialog(
      context: context,
      title: 'First Name',
      value: profile.firstName ?? '',
      hint: 'Enter first name',
      keyboardType: TextInputType.name,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
      ],
      onSave: (value) {
        ref.read(userProfileProvider.notifier).updateFields(firstName: value);
      },
    );
  }

  void _showEditLastNameDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    _showEditDialog(
      context: context,
      title: 'Last Name',
      value: profile.lastName ?? '',
      hint: 'Enter last name',
      keyboardType: TextInputType.name,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
      ],
      onSave: (value) {
        ref.read(userProfileProvider.notifier).updateFields(lastName: value);
      },
    );
  }

  void _showEditIdNumberDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    _showEditDialog(
      context: context,
      title: 'ID Number',
      value: profile.identityVerification?.idNumber ?? '',
      hint: 'Enter ID number',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onSave: (value) {
        ref
            .read(userProfileProvider.notifier)
            .updateIdentityVerification(idNumber: value);
      },
    );
  }

  void _showEditPhoneDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PhoneEditSheet(
        initialValue: profile.phone ?? '',
        onSave: (phone) {
          ref.read(userProfileProvider.notifier).updateFields(phone: phone);
        },
      ),
    );
  }

  void _showCountryPicker(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        ref
            .read(userProfileProvider.notifier)
            .updateFields(country: country.name);
      },
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required String value,
    required String hint,
    required ValueChanged<String> onSave,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    final controller = TextEditingController(text: value);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update $title',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: keyboardType ?? TextInputType.text,
                inputFormatters: inputFormatters,
                maxLength: maxLength,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF111827),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onSave(controller.text.trim());
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class to handle image picking and cropping for UserInfoTab
class _UserInfoTabHelper {
  static Future<void> pickAndCropImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
    String type,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    CroppedFile? croppedFile;
    try {
      croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF111827),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: type == 'avatar',
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: type == 'avatar',
          ),
        ],
      );
    } on PlatformException catch (e) {
      debugPrint('Image cropper platform error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image cropping is not available on this device.'),
          ),
        );
      }
      return;
    }

    if (croppedFile == null) return;

    // Check connection
    final connectivityState = ref.read(profileConnectivityProvider);
    if (connectivityState != ProfileConnectivityState.connected &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Cannot upload image.'),
        ),
      );
      return;
    }

    if (type == 'avatar') {
      await ref
          .read(userProfileProvider.notifier)
          .uploadAccountProfilePhoto(croppedFile.path);
    } else if (type == 'idFront') {
      await ref
          .read(userProfileProvider.notifier)
          .updateIdentityVerification(
            idNumber:
                ref
                    .read(userProfileProvider)
                    .profile
                    ?.identityVerification
                    ?.idNumber ??
                '',
            idFrontImageUrl: croppedFile.path,
          );
    } else if (type == 'idBack') {
      await ref
          .read(userProfileProvider.notifier)
          .updateIdentityVerification(
            idNumber:
                ref
                    .read(userProfileProvider)
                    .profile
                    ?.identityVerification
                    ?.idNumber ??
                '',
            idBackImageUrl: croppedFile.path,
          );
    }
  }

  static void showUploadDialog(
    BuildContext context,
    WidgetRef ref,
    String label,
    String type,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload $label',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                pickAndCropImage(context, ref, ImageSource.camera, type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                pickAndCropImage(context, ref, ImageSource.gallery, type);
              },
            ),
            if (type != 'avatar')
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Upload File'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final connectivityState = ref.read(
                      profileConnectivityProvider,
                    );
                    if (connectivityState !=
                            ProfileConnectivityState.connected &&
                        context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No internet connection. Cannot upload document.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (type == 'idFront') {
                      await ref
                          .read(userProfileProvider.notifier)
                          .updateIdentityVerification(
                            idNumber:
                                ref
                                    .read(userProfileProvider)
                                    .profile
                                    ?.identityVerification
                                    ?.idNumber ??
                                '',
                            idFrontImageUrl: result.files.single.path!,
                          );
                    } else if (type == 'idBack') {
                      await ref
                          .read(userProfileProvider.notifier)
                          .updateIdentityVerification(
                            idNumber:
                                ref
                                    .read(userProfileProvider)
                                    .profile
                                    ?.identityVerification
                                    ?.idNumber ??
                                '',
                            idBackImageUrl: result.files.single.path!,
                          );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Profile Header Card with Avatar, Name, Email, and Status
class _ProfileHeaderCard extends ConsumerWidget {
  final UserProfile profile;

  const _ProfileHeaderCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF374151), const Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar with Camera Icon
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Update Profile Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Take Photo'),
                        onTap: () {
                          Navigator.pop(context);
                          _UserInfoTabHelper.pickAndCropImage(
                            context,
                            ref,
                            ImageSource.camera,
                            'avatar',
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Choose from Gallery'),
                        onTap: () {
                          Navigator.pop(context);
                          _UserInfoTabHelper.pickAndCropImage(
                            context,
                            ref,
                            ImageSource.gallery,
                            'avatar',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child:
                      profile.profileImage != null &&
                          profile.profileImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: profile.profileImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildInitials(),
                        )
                      : _buildInitials(),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Name and Email
          Text(
            profile.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Status Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              StatusBadge.verification(profile.verificationStatus),
              if (profile.isProvider)
                StatusBadge.accountType(profile.accountType),
            ],
          ),
          const SizedBox(height: 20),

          // Edit Profile Button
          SizedBox(
            width: 140,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to full profile edit
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        profile.initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// ID Document Upload Row
class _IdUploadRow extends StatelessWidget {
  final String label;
  final bool hasDocument;
  final VoidCallback onUpload;

  const _IdUploadRow({
    required this.label,
    required this.hasDocument,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDocument ? 'Document uploaded' : 'No document uploaded',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasDocument
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: onUpload,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                ),
                child: const Text('Choose file'),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.upload,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Phone Edit Bottom Sheet
class _PhoneEditSheet extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSave;

  const _PhoneEditSheet({required this.initialValue, required this.onSave});

  @override
  State<_PhoneEditSheet> createState() => _PhoneEditSheetState();
}

class _PhoneEditSheetState extends State<_PhoneEditSheet> {
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _phoneNumber = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Phone Number',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 24),
            IntlPhoneField(
              initialValue: _phoneNumber.replaceAll(RegExp(r'^\+'), ''),
              decoration: InputDecoration(
                hintText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF111827),
                    width: 2,
                  ),
                ),
              ),
              initialCountryCode: 'NG',
              onChanged: (phone) => _phoneNumber = phone.completeNumber,
              dropdownIconPosition: IconPosition.trailing,
              flagsButtonPadding: const EdgeInsets.only(left: 8),
              showDropdownIcon: true,
              dropdownTextStyle: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(_phoneNumber);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final List<Widget> children;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}
