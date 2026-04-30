import 'package:discovaa/features/profile/presentation/providers/artisan_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A draggable bottom sheet for advanced filtering of service providers
/// Can be shown from the home page
class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  /// Helper method to show the bottom sheet from anywhere
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  String _providerType = 'All';
  bool _isVerified = false;
  bool _nearMe = false;
  String _distance = '10 km';

  final List<String> _providerTypes = ['All', 'Individual', 'Business'];
  final List<String> _distances = ['5 km', '10 km', '25 km', '50 km'];

  @override
  void initState() {
    super.initState();
    _loadCurrentFilters();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _loadCurrentFilters() {
    final filter = ref.read(artisanFilterProvider);
    _nameController.text = filter.searchQuery;
    _areaController.text = filter.location ?? '';
    _isVerified = filter.minRating != null && filter.minRating! >= 4.0;
    _nearMe = filter.isAvailableOnly;
  }

  void _applyFilters() {
    ref
        .read(artisanFilterProvider.notifier)
        .setSearchQuery(_nameController.text);
    ref
        .read(artisanFilterProvider.notifier)
        .setLocation(
          _areaController.text.trim().isEmpty
              ? null
              : _areaController.text.trim(),
        );
    ref
        .read(artisanFilterProvider.notifier)
        .setMinRating(_isVerified ? 4.0 : null);
    ref.read(artisanFilterProvider.notifier).setAvailableOnly(_nearMe);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _nameController.clear();
      _areaController.clear();
      _providerType = 'All';
      _isVerified = false;
      _nearMe = false;
      _distance = '10 km';
    });
    // Also clear provider state immediately
    ref.read(artisanFilterProvider.notifier).clearAdvancedFilters();
    ref.read(artisanFilterProvider.notifier).setSearchQuery('');
    ref.read(artisanFilterProvider.notifier).setLocation(null);
    ref.read(artisanFilterProvider.notifier).setCategory(null);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              _buildHeader(),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Browse artisan by name
                    _buildLabel('Browse artisan by name'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'e.g. John',
                    ),
                    const SizedBox(height: 20),
                    // Area
                    _buildLabel('Area'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _areaController,
                      hintText: 'Google Maps not configured',
                    ),
                    const SizedBox(height: 20),
                    // Provider type
                    _buildLabel('Provider type'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _providerType,
                      items: _providerTypes,
                      onChanged: (value) =>
                          setState(() => _providerType = value!),
                    ),
                    const SizedBox(height: 20),
                    // Verified
                    _buildCheckbox(
                      label: 'Verified',
                      value: _isVerified,
                      onChanged: (value) =>
                          setState(() => _isVerified = value!),
                    ),
                    const SizedBox(height: 20),
                    // Near me
                    _buildLabel('Near me'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildToggle(
                            label: 'Enabled',
                            value: _nearMe,
                            onChanged: (value) =>
                                setState(() => _nearMe = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            value: _distance,
                            items: _distances,
                            onChanged: _nearMe
                                ? (value) => setState(() => _distance = value!)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.black,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.black,
              activeTrackColor: Colors.grey.shade400,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearFilters,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Clear',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
