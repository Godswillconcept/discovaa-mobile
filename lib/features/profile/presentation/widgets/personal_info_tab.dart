import 'package:country_picker/country_picker.dart';
import 'package:discovaa/core/widgets/custom_buttons.dart';
import 'package:discovaa/features/authentication/presentation/providers/signup_provider.dart';
import 'package:discovaa/features/profile/domain/entities/user_profile.dart';
import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class PersonalInfoTab extends ConsumerWidget {
  final UserProfile profile;
  const PersonalInfoTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signupState = ref.watch(signupProvider);
    final isProvider = signupState.selectedRole.isProvider;
    final isBSV = signupState.selectedRole == UserRole.businessProvider;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  image: const DecorationImage(
                    image: AssetImage(
                      'assets/images/placeholders/user_avatar.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildEditableField(context, ref, profile, 'Name', profile.fullName),
          _buildEditableField(
            context,
            ref,
            profile,
            'Gender',
            profile.gender ?? 'N/A',
          ),
          _buildEditableField(
            context,
            ref,
            profile,
            'Country',
            profile.country ?? 'N/A',
            flag: '🇪🇪',
          ),
          _buildEditableField(
            context,
            ref,
            profile,
            'Time zone',
            profile.timezone ?? 'N/A',
          ),
          _buildEditableField(
            context,
            ref,
            profile,
            'Pronouns',
            profile.pronouns ?? 'N/A',
          ),
          _buildEditableField(
            context,
            ref,
            profile,
            'Languages spoken',
            profile.languagesSpoken ?? 'N/A',
          ),
          if (isProvider)
            _buildEditableField(
              context,
              ref,
              profile,
              'Services offered',
              profile.servicesOffered ?? 'N/A',
              isDropdown: isBSV,
            ),
          if (isBSV) ...[
            _buildPriceField(
              'Hourly rate',
              '${profile.hourlyRate ?? '€0'}/hour',
            ),
            _buildPriceField(
              'Price range for a project',
              profile.priceRange ?? 'N/A',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    String label,
    String value, {
    String? flag,
    bool isPhone = false,
    bool isDropdown = false,
  }) {
    final signupState = ref.watch(signupProvider);
    final isBSV = signupState.selectedRole == UserRole.businessProvider;
    final bool isServiceEdit = label == 'Services offered';
    final bool isBlackButton = isServiceEdit && isBSV;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (flag != null) ...[
                if (isPhone)
                  Row(
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      const Text(
                        '+372',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFB0B0B0),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                else ...[
                  Text(flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                ],
              ],
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: isServiceEdit && value.contains(':')
                          ? RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontFamily: 'Inter',
                                ),
                                children: [
                                  TextSpan(
                                    text: '${value.split(':')[0]}:',
                                    style: const TextStyle(
                                      color: Color(0xFF999999),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  TextSpan(
                                    text: value.split(':')[1],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              value,
                              style: TextStyle(
                                fontSize: 17,
                                color: isServiceEdit
                                    ? const Color(0xFF666666)
                                    : const Color(0xFF999999),
                                fontWeight: isServiceEdit
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    if (isDropdown || isServiceEdit) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () =>
                      _showEditor(context, ref, profile, label, value, isPhone),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isBlackButton
                          ? Colors.black
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    backgroundColor: isBlackButton
                        ? Colors.black
                        : Colors.white,
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: isBlackButton ? Colors.white : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 0.5),
        ],
      ),
    );
  }

  void _showEditor(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    String label,
    String value,
    bool isPhone,
  ) {
    if (label == 'Country' && !isPhone) {
      showCountryPicker(
        context: context,
        showPhoneCode: false,
        onSelect: (Country country) {
          final updatedProfile = profile.copyWith(country: country.name);
          ref.read(userProfileProvider.notifier).updateProfile(updatedProfile);
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
                color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
      );
    } else if (isPhone) {
      String currentPhone = value;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Phone Number',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  IntlPhoneField(
                    initialValue: value.replaceAll(RegExp(r'[^0-9]'), ''),
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    initialCountryCode: 'EE',
                    onChanged: (phone) => currentPhone = phone.completeNumber,
                    dropdownIconPosition: IconPosition.trailing,
                    flagsButtonPadding: const EdgeInsets.only(left: 8),
                    showDropdownIcon: true,
                    dropdownTextStyle: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    onPressed: () {
                      final updatedProfile = profile.copyWith(
                        phone: currentPhone,
                      );
                      ref
                          .read(userProfileProvider.notifier)
                          .updateProfile(updatedProfile);
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (label == 'Services offered') {
      final categories = ref.read(categoriesProvider);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select Service Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = value.contains(category.name);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      title: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.black)
                          : null,
                      onTap: () {
                        final updatedProfile = profile.copyWith(
                          servicesOffered: category.name,
                        );
                        ref
                            .read(userProfileProvider.notifier)
                            .updateProfile(updatedProfile);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    } else {
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
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update $label',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter $label',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppPrimaryButton(
                  onPressed: () {
                    UserProfile updatedProfile = profile;
                    final newVal = controller.text;
                    if (label == 'Name') {
                      // Parse full name into first and last name
                      final nameParts = newVal.split(' ');
                      updatedProfile = profile.copyWith(
                        firstName: nameParts.first,
                        lastName: nameParts.length > 1
                            ? nameParts.sublist(1).join(' ')
                            : null,
                      );
                    } else if (label == 'Gender') {
                      updatedProfile = profile.copyWith(gender: newVal);
                    } else if (label == 'Time zone') {
                      updatedProfile = profile.copyWith(timezone: newVal);
                    } else if (label == 'Pronouns') {
                      updatedProfile = profile.copyWith(pronouns: newVal);
                    } else if (label == 'Languages spoken') {
                      updatedProfile = profile.copyWith(
                        languagesSpoken: newVal,
                      );
                    } else if (label == 'Services offered') {
                      updatedProfile = profile.copyWith(
                        servicesOffered: newVal,
                      );
                    } else if (label == 'Hourly rate') {
                      updatedProfile = profile.copyWith(hourlyRate: newVal);
                    } else if (label == 'Price range for a project') {
                      updatedProfile = profile.copyWith(priceRange: newVal);
                    }
                    ref
                        .read(userProfileProvider.notifier)
                        .updateProfile(updatedProfile);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    }
  }
}
