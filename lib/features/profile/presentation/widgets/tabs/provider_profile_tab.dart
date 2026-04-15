import 'package:discovaa/features/profile/domain/entities/business_registration.dart';
import 'package:discovaa/features/profile/domain/entities/location.dart'
    as location;
import 'package:discovaa/features/profile/domain/entities/user_profile.dart';
import 'package:discovaa/features/profile/domain/entities/profile_enums.dart';
import 'package:discovaa/features/profile/domain/entities/location.dart';
import 'package:discovaa/features/profile/domain/entities/certification.dart';
import 'package:discovaa/features/profile/presentation/providers/profile_connectivity_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:discovaa/features/profile/presentation/widgets/shared/profile_field_row.dart';
import 'package:discovaa/features/profile/presentation/widgets/shared/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider Profile Tab - Provider-specific information
class ProviderProfileTab extends ConsumerWidget {
  const ProviderProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.profile;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!profile.isProvider) {
      return _NotProviderView(
        onBecomeProvider: () {
          // NOTE: Provider registration flow to be implemented in Phase 4
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Information Card
          _ProviderInfoCard(profile: profile),
          const SizedBox(height: 24),

          // Provider Information Section
          ProfileSectionCard(
            title: 'Provider Information',
            subtitle: 'Your public profile details',
            children: [
              ProfileFieldRow(
                label: 'Phone',
                value: profile.formattedPhone,
                onEdit: () => _showEditPhoneDialog(context, ref, profile),
              ),
              ProfileFieldRow(
                label: 'Summary',
                value: profile.summary ?? '',
                placeholder: 'N/A',
                maxLines: 3,
                showDivider: false,
                onEdit: () => _showEditSummaryDialog(context, ref, profile),
              ),
            ],
          ),

          // Locations Section
          ProfileSectionCard(
            title: 'Locations',
            subtitle: 'Where you provide services',
            action: TextButton.icon(
              onPressed: () => _showAddLocationDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
              ),
            ),
            children: profile.locations.isEmpty
                ? [_buildEmptyLocations()]
                : profile.locations
                      .map(
                        (location) => _buildLocationRow(context, ref, location),
                      )
                      .toList(),
          ),

          // Business Registration Section
          ProfileSectionCard(
            title: 'Business Registration',
            subtitle: 'Your business verification details',
            action: StatusBadge.verification(
              profile.businessRegistration?.verificationStatus ??
                  VerificationStatus.unverified,
            ),
            children: [
              ProfileFieldRow(
                label: 'Registration Number',
                value: profile.businessRegistration?.registrationNumber ?? '',
                placeholder: 'Not registered',
                onEdit: () =>
                    _showEditRegistrationDialog(context, ref, profile),
              ),
              const SizedBox(height: 16),
              _buildDocumentUploadRow(
                label: 'Registration Document',
                hasDocument: profile.businessRegistration?.hasDocument ?? false,
                onUpload: () =>
                    _showUploadDialog(context, 'Registration Document'),
              ),
            ],
          ),

          // Certifications Section
          ProfileSectionCard(
            title: 'Certifications',
            subtitle: 'Your professional credentials and licenses',
            action: TextButton.icon(
              onPressed: () => _showAddCertificationDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
              ),
            ),
            children: profile.certifications.isEmpty
                ? [_buildEmptyCertifications()]
                : profile.certifications
                      .map((cert) => _buildCertificationRow(context, ref, cert))
                      .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLocations() {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.location_off_outlined, size: 48, color: Color(0xFF9CA3AF)),
          SizedBox(height: 12),
          Text(
            'No locations added yet',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCertifications() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.card_membership_outlined,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 12),
          Text(
            'No certifications added yet',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Add your professional credentials to build trust with clients',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context,
    WidgetRef ref,
    ServiceLocation location,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: location.isPrimary
              ? const Color(0xFF10B981)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: location.isPrimary
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on,
              size: 20,
              color: location.isPrimary
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (location.isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (location.formattedAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    location.formattedAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditLocationDialog(context, ref, location),
            icon: const Icon(Icons.edit, size: 18),
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadRow({
    required String label,
    required bool hasDocument,
    required VoidCallback onUpload,
  }) {
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
                  hasDocument ? 'Document uploaded' : 'Choose file...',
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
          if (hasDocument)
            IconButton(
              onPressed: () {
                // NOTE: Document viewer to be implemented with file preview
              },
              icon: const Icon(Icons.visibility, size: 20),
              color: const Color(0xFF6B7280),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasDocument ? Icons.refresh : Icons.upload,
              size: 20,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationRow(
    BuildContext context,
    WidgetRef ref,
    Certification cert,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.card_membership,
              size: 20,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                if (cert.issuingOrganization != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    cert.issuingOrganization!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge.verification(cert.verificationStatus),
                    if (cert.isExpired) ...[
                      const SizedBox(width: 8),
                      StatusBadge.error('Expired'),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditCertificationDialog(context, ref, cert),
            icon: const Icon(Icons.edit, size: 18),
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final controller = TextEditingController(text: profile.phone ?? '');
    final connectivityState = ref.read(profileConnectivityProvider);
    final isConnected = connectivityState == ProfileConnectivityState.connected;

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
              const Text(
                'Update Phone',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your business phone number',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+1234567890',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (!isConnected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No internet connection. Changes will be saved locally.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final phone = controller.text.trim();
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a phone number'),
                        ),
                      );
                      return;
                    }

                    final success = await ref
                        .read(userProfileProvider.notifier)
                        .updateFields(phone: phone);

                    if (context.mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phone updated successfully'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update phone'),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSummaryDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final controller = TextEditingController(text: profile.summary ?? '');

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
              const Text(
                'Update Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Briefly describe your services...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref
                        .read(userProfileProvider.notifier)
                        .updateProfile(
                          profile.copyWith(summary: controller.text.trim()),
                        );
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
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context, WidgetRef ref) {
    _showLocationDialog(context, ref, null);
  }

  void _showEditLocationDialog(
    BuildContext context,
    WidgetRef ref,
    ServiceLocation location,
  ) {
    _showLocationDialog(context, ref, location);
  }

  void _showLocationDialog(
    BuildContext context,
    WidgetRef ref,
    ServiceLocation? existingLocation,
  ) {
    final isEditing = existingLocation != null;
    final nameController = TextEditingController(
      text: existingLocation?.name ?? '',
    );
    final addressController = TextEditingController(
      text: existingLocation?.address ?? '',
    );
    final cityController = TextEditingController(
      text: existingLocation?.city ?? '',
    );
    final radiusController = TextEditingController(
      text: existingLocation?.serviceRadius?.toString() ?? '50',
    );
    bool isPrimary = existingLocation?.isPrimary ?? false;

    final connectivityState = ref.read(profileConnectivityProvider);
    final isConnected = connectivityState == ProfileConnectivityState.connected;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Location' : 'Add Location',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your service location details',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Location Name',
                      hintText: 'e.g., Main Office',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      hintText: 'Street address',
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      hintText: 'City name',
                      prefixIcon: const Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: radiusController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Service Radius (km)',
                      hintText: '50',
                      prefixIcon: const Icon(Icons.radar_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Primary Location'),
                    subtitle: const Text('Set as your main service location'),
                    value: isPrimary,
                    onChanged: (value) => setState(() => isPrimary = value),
                    activeThumbColor: const Color(0xFF111827),
                  ),
                  if (!isConnected) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wifi_off,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No internet connection. Changes will be saved locally.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final address = addressController.text.trim();
                        final city = cityController.text.trim();
                        final radius =
                            int.tryParse(radiusController.text.trim()) ?? 50;

                        if (name.isEmpty || address.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter name and address'),
                            ),
                          );
                          return;
                        }

                        final profile = ref.read(userProfileProvider).profile;
                        if (profile == null) return;

                        final newLocation = location.ServiceLocation(
                          id:
                              existingLocation?.id ??
                              'loc_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          address: address,
                          city: city,
                          country: profile.country,
                          isPrimary: isPrimary,
                          serviceRadius: radius.toDouble(),
                        );

                        final success = await ref
                            .read(userProfileProvider.notifier)
                            .saveLocation(newLocation);

                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Location updated'
                                      : 'Location added',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to save location'),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isEditing ? 'Update' : 'Add'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCertificationDialog(BuildContext context, WidgetRef ref) {
    _showCertificationDialog(context, ref, null);
  }

  void _showEditCertificationDialog(
    BuildContext context,
    WidgetRef ref,
    Certification cert,
  ) {
    _showCertificationDialog(context, ref, cert);
  }

  void _showCertificationDialog(
    BuildContext context,
    WidgetRef ref,
    Certification? existingCert,
  ) {
    final isEditing = existingCert != null;
    final nameController = TextEditingController(
      text: existingCert?.name ?? '',
    );
    final issuerController = TextEditingController(
      text: existingCert?.issuingOrganization ?? '',
    );
    final yearController = TextEditingController(
      text: existingCert?.issueDate?.year.toString() ?? '',
    );

    final connectivityState = ref.read(profileConnectivityProvider);
    final isConnected = connectivityState == ProfileConnectivityState.connected;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Certification' : 'Add Certification',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter certification details',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Certification Title',
                    hintText: 'e.g., Master Plumber',
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: issuerController,
                  decoration: InputDecoration(
                    labelText: 'Issuing Organization',
                    hintText: 'e.g., Plumbing Association',
                    prefixIcon: const Icon(Icons.business_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: yearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Year Obtained',
                    hintText: '2020',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (!isConnected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No internet connection. Changes will be saved locally.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (isEditing)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final success = await ref
                                .read(userProfileProvider.notifier)
                                .deleteCertification(existingCert.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Certification deleted'),
                                  ),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                    if (isEditing) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final title = nameController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a certification title',
                                ),
                              ),
                            );
                            return;
                          }

                          final year = int.tryParse(yearController.text.trim());
                          final cert = Certification(
                            id:
                                existingCert?.id ??
                                'cert_${DateTime.now().millisecondsSinceEpoch}',
                            name: title,
                            issuingOrganization: issuerController.text.trim(),
                            issueDate: year != null ? DateTime(year) : null,
                            verificationStatus:
                                existingCert?.verificationStatus ??
                                VerificationStatus.unverified,
                          );

                          final success = await ref
                              .read(userProfileProvider.notifier)
                              .saveCertification(cert);

                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'Certification updated'
                                        : 'Certification added',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isEditing ? 'Update' : 'Add'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditRegistrationDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final controller = TextEditingController(
      text: profile.businessRegistration?.registrationNumber ?? '',
    );

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
              const Text(
                'Business Registration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final regNumber = controller.text.trim();
                    final currentReg =
                        profile.businessRegistration ??
                        BusinessRegistration(
                          businessName: profile.displayName ?? '',
                          registrationNumber: '',
                          businessType: '',
                          registrationDate: DateTime.now(),
                        );

                    final success = await ref
                        .read(userProfileProvider.notifier)
                        .updateBusinessRegistration(
                          currentReg.copyWith(registrationNumber: regNumber),
                        );

                    if (context.mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registration updated')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context, String label) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload $label',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a source for your document',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                // NOTE: Camera capture to be implemented with image_picker package
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                // NOTE: Gallery picker to be implemented with image_picker package
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Files'),
              onTap: () {
                Navigator.pop(context);
                // NOTE: File picker to be implemented with file_picker package
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Provider Info Card - Header card showing provider status
class _ProviderInfoCard extends StatelessWidget {
  final UserProfile profile;

  const _ProviderInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1F2937), const Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.accountType.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const Text(
                      'Provider Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.location_on,
                value: '${profile.locations.length}',
                label: 'Locations',
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.card_membership,
                value: '${profile.certifications.length}',
                label: 'Certs',
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.verified,
                value: profile.verificationStatus.displayName,
                label: 'Status',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}

/// View shown when user is not a provider
class _NotProviderView extends StatelessWidget {
  final VoidCallback onBecomeProvider;

  const _NotProviderView({required this.onBecomeProvider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_center_outlined,
                size: 64,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Become a Provider',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Register as a service provider to offer your services and reach more clients on Discovaa.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBecomeProvider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Register as Provider',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
