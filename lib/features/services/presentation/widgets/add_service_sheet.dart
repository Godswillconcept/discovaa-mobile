import 'dart:io' as io;
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/services/data/models/service_api_models.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/services/presentation/providers/services_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Modal bottom sheet for creating or editing a service.
/// Pass [existing] to pre-populate fields for editing.
class AddServiceSheet extends ConsumerStatefulWidget {
  final ServiceModel? existing;

  const AddServiceSheet({super.key, this.existing});

  @override
  ConsumerState<AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends ConsumerState<AddServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _minAmountCtrl;
  late final TextEditingController _maxAmountCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _currencyCtrl;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _amountCtrl = TextEditingController(
      text: s?.amount?.toStringAsFixed(0) ?? '',
    );
    _minAmountCtrl = TextEditingController(
      text: s?.priceMinAmount?.toStringAsFixed(0) ?? '',
    );
    _maxAmountCtrl = TextEditingController(
      text: s?.priceMaxAmount?.toStringAsFixed(0) ?? '',
    );
    _durationCtrl = TextEditingController(
      text: s?.durationMinutes?.toString() ?? '',
    );
    _currencyCtrl = TextEditingController(text: s?.currency ?? 'NGN');

    // Load categories from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serviceCategoriesProvider.notifier).loadCategories();

      if (s != null) {
        final form = ref.read(addServiceFormProvider.notifier);
        form.updateTitle(s.title);
        // Set category with both name and ID (ID from categoryId field, name from category field)
        form.updateCategory(name: s.category ?? '', id: s.categoryId ?? '');
        form.updateDescription(s.description);
        form.updatePricingModel(s.pricingModel);
        form.updatePriceType(s.priceType);
        form.updateCurrency(s.currency);
        form.updateAmount(
          s.priceType == PriceType.variable
              ? ''
              : s.amount?.toStringAsFixed(0) ?? '',
        );
        form.updateMinAmount(s.priceMinAmount?.toStringAsFixed(0) ?? '');
        form.updateMaxAmount(s.priceMaxAmount?.toStringAsFixed(0) ?? '');
        form.updateDuration(s.durationMinutes?.toString() ?? '');
        form.updateIsActive(s.isActive);
        // Note: weeklySchedule is now managed at provider profile level, not per-service

        ref
            .read(servicesProvider.notifier)
            .loadServiceMediaForService(s.id)
            .then((media) {
              if (!mounted) return;
              ref.read(addServiceFormProvider.notifier).setExistingMedia(media);
            });
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _minAmountCtrl.dispose();
    _maxAmountCtrl.dispose();
    _durationCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final formNotifier = ref.read(addServiceFormProvider.notifier);
    final form = ref.read(addServiceFormProvider);
    if (!form.canAddMoreMedia) return;

    final remaining = AddServiceFormState.maxMediaCount - form.totalMediaCount;
    final images = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;

    for (final image in images.take(remaining)) {
      formNotifier.addPendingMedia(image.path);
    }

    if (!mounted) return;
    if (images.length > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only $remaining more image${remaining == 1 ? '' : 's'} can be added.',
          ),
        ),
      );
    }
  }

  Future<void> _captureWithCamera() async {
    final formNotifier = ref.read(addServiceFormProvider.notifier);
    final form = ref.read(addServiceFormProvider);
    if (!form.canAddMoreMedia) return;

    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;

    formNotifier.addPendingMedia(image.path);
  }

  Future<void> _showMediaSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Select from gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _captureWithCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _uploadPendingMedia(String serviceId, List<String> paths) async {
    final servicesNotifier = ref.read(servicesProvider.notifier);
    var allSucceeded = true;
    for (final path in paths) {
      final uploaded = await servicesNotifier.uploadMedia(
        serviceId: serviceId,
        filePath: path,
      );
      if (!uploaded) {
        allSucceeded = false;
      }
    }
    return allSucceeded;
  }

  Future<void> _deleteExistingMedia(ServiceMediaDto media) async {
    final deleted = await ref
        .read(servicesProvider.notifier)
        .deleteMedia(media.id);
    if (!mounted) return;

    if (deleted) {
      ref.read(addServiceFormProvider.notifier).removeExistingMedia(media.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media deleted successfully.')),
      );
      return;
    }

    final error =
        ref.read(mediaUploadErrorProvider) ?? 'Failed to delete media.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _submit() async {
    final form = ref.read(addServiceFormProvider);
    ref.read(addServiceFormProvider.notifier).markSubmitted();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final amount =
        form.priceType == PriceType.fixed && form.amountRaw.isNotEmpty
        ? double.tryParse(form.amountRaw)
        : null;
    final minAmount =
        form.priceType == PriceType.variable && form.minAmountRaw.isNotEmpty
        ? double.tryParse(form.minAmountRaw)
        : null;
    final maxAmount =
        form.priceType == PriceType.variable && form.maxAmountRaw.isNotEmpty
        ? double.tryParse(form.maxAmountRaw)
        : null;
    final duration = form.durationRaw.isNotEmpty
        ? int.tryParse(form.durationRaw)
        : null;

    ServiceModel? savedService;
    if (widget.existing != null) {
      savedService = await ref
          .read(servicesProvider.notifier)
          .updateService(
            widget.existing!.copyWith(
              title: form.title,
              category: form.category.isEmpty ? null : form.category,
              categoryId: form.categoryId.isEmpty ? null : form.categoryId,
              description: form.description,
              pricingModel: form.pricingModel,
              priceType: form.priceType,
              currency: form.currency,
              amount: amount,
              priceMinAmount: minAmount,
              priceMaxAmount: maxAmount,
              durationMinutes: duration,
              isActive: form.isActive,
            ),
          );
    } else {
      savedService = await ref
          .read(servicesProvider.notifier)
          .addService(
            title: form.title,
            category: form.category.isEmpty ? null : form.category,
            categoryId: form.categoryId.isEmpty ? null : form.categoryId,
            description: form.description,
            pricingModel: form.pricingModel,
            priceType: form.priceType,
            currency: form.currency,
            amount: amount,
            priceMinAmount: minAmount,
            priceMaxAmount: maxAmount,
            durationMinutes: duration,
            isActive: form.isActive,
          );
    }

    if (savedService == null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        final error =
            ref.read(servicesProvider).errorMessage ??
            'Failed to save service. Please try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    if (form.pendingMediaPaths.isNotEmpty) {
      final uploadedAll = await _uploadPendingMedia(
        savedService.id,
        form.pendingMediaPaths,
      );
      if (!uploadedAll && mounted) {
        final error =
            ref.read(mediaUploadErrorProvider) ??
            'Some media failed to upload.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }

    ref.read(addServiceFormProvider.notifier).reset();
    setState(() => _isSubmitting = false);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(addServiceFormProvider);
    final isEdit = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              children: [
                Text(
                  isEdit ? 'Edit service' : 'Add service',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ref.read(addServiceFormProvider.notifier).reset();
                    Navigator.of(context).pop();
                  },
                  child: Icon(Icons.close, size: 22.r),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable form body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    _FieldLabel('Title'),
                    SizedBox(height: 6.h),
                    _InputField(
                      controller: _titleCtrl,
                      hint: 'e.g. Haircut + Beard Trim',
                      onChanged: ref
                          .read(addServiceFormProvider.notifier)
                          .updateTitle,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    SizedBox(height: 16.h),

                    // Category
                    _FieldLabel('Category'),
                    SizedBox(height: 6.h),
                    Consumer(
                      builder: (context, ref, child) {
                        final categoriesState = ref.watch(
                          serviceCategoriesProvider,
                        );

                        if (categoriesState.status == ServicesStatus.loading) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16.w,
                                  height: 16.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'Loading categories...',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Build category items: null option + API categories
                        final categoryItems = <ServiceCategoryDto?>[
                          null, // Represents "No category"
                          ...categoriesState.categories,
                        ];

                        // Find current value
                        ServiceCategoryDto? currentValue;
                        if (form.categoryId.isNotEmpty) {
                          try {
                            currentValue = categoriesState.categories
                                .firstWhere((c) => c.id == form.categoryId);
                          } catch (_) {
                            currentValue = null;
                          }
                        }

                        return _DropdownField<ServiceCategoryDto?>(
                          value: currentValue,
                          items: categoryItems,
                          labelOf: (c) => c?.name ?? 'No category',
                          onChanged: (v) {
                            ref
                                .read(addServiceFormProvider.notifier)
                                .updateCategory(
                                  name: v?.name ?? '',
                                  id: v?.id ?? '',
                                );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Description
                    _FieldLabel('Description'),
                    SizedBox(height: 6.h),
                    _InputField(
                      controller: _descCtrl,
                      hint:
                          'Describe what\'s included, requirements, and expectations.',
                      onChanged: ref
                          .read(addServiceFormProvider.notifier)
                          .updateDescription,
                      maxLines: 4,
                    ),
                    SizedBox(height: 20.h),

                    // Service images
                    _FieldLabel('Service images'),
                    SizedBox(height: 6.h),
                    _MediaSection(
                      existingMedia: form.existingMedia,
                      pendingMediaPaths: form.pendingMediaPaths,
                      canAddMore: form.canAddMoreMedia,
                      onAddMedia: _showMediaSourceSheet,
                      onRemovePending: (index) {
                        ref
                            .read(addServiceFormProvider.notifier)
                            .removePendingMedia(index);
                      },
                      onRemoveExisting: _deleteExistingMedia,
                    ),
                    SizedBox(height: 20.h),

                    // Pricing section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pricing',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 14.h),

                          // Pricing model
                          _FieldLabel('Pricing model'),
                          SizedBox(height: 6.h),
                          _DropdownField<PricingModel>(
                            value: form.pricingModel,
                            items: PricingModel.values,
                            labelOf: (m) => m.displayName,
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(addServiceFormProvider.notifier)
                                    .updatePricingModel(v);
                              }
                            },
                          ),
                          SizedBox(height: 14.h),

                          // Price type
                          _FieldLabel('Price type'),
                          SizedBox(height: 6.h),
                          _DropdownField<PriceType>(
                            value: form.priceType,
                            items: PriceType.values,
                            labelOf: (t) => t.displayName,
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(addServiceFormProvider.notifier)
                                    .updatePriceType(v);
                              }
                            },
                          ),
                          SizedBox(height: 14.h),

                          // Currency
                          _FieldLabel('Currency'),
                          SizedBox(height: 6.h),
                          _InputField(
                            controller: _currencyCtrl,
                            hint: 'NGN',
                            onChanged: ref
                                .read(addServiceFormProvider.notifier)
                                .updateCurrency,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z]'),
                              ),
                              LengthLimitingTextInputFormatter(3),
                            ],
                            textCapitalization: TextCapitalization.characters,
                          ),
                          SizedBox(height: 14.h),

                          // Amount or range
                          if (form.priceType == PriceType.fixed) ...[
                            _FieldLabel('Amount'),
                            SizedBox(height: 6.h),
                            _InputField(
                              controller: _amountCtrl,
                              hint: form.pricingModel == PricingModel.hourly
                                  ? 'Rate per hour e.g. 5000'
                                  : 'e.g. 5000',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              onChanged: ref
                                  .read(addServiceFormProvider.notifier)
                                  .updateAmount,
                              validator: (v) {
                                if (v != null &&
                                    v.isNotEmpty &&
                                    double.tryParse(v) == null) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),
                          ] else ...[
                            _FieldLabel('Min amount'),
                            SizedBox(height: 6.h),
                            _InputField(
                              controller: _minAmountCtrl,
                              hint: 'e.g. 3000',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              onChanged: ref
                                  .read(addServiceFormProvider.notifier)
                                  .updateMinAmount,
                              validator: (v) {
                                final bothEmpty =
                                    (v == null || v.isEmpty) &&
                                    _maxAmountCtrl.text.isEmpty;
                                if (bothEmpty) return 'Enter min or max';
                                if (v != null &&
                                    v.isNotEmpty &&
                                    double.tryParse(v) == null) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10.h),
                            _FieldLabel('Max amount'),
                            SizedBox(height: 6.h),
                            _InputField(
                              controller: _maxAmountCtrl,
                              hint: 'e.g. 8000',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              onChanged: ref
                                  .read(addServiceFormProvider.notifier)
                                  .updateMaxAmount,
                              validator: (v) {
                                final bothEmpty =
                                    (v == null || v.isEmpty) &&
                                    _minAmountCtrl.text.isEmpty;
                                if (bothEmpty) return 'Enter min or max';
                                if (v != null &&
                                    v.isNotEmpty &&
                                    double.tryParse(v) == null) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),
                          ],

                          // Duration
                          _FieldLabel(
                            form.pricingModel == PricingModel.package
                                ? 'Package duration (minutes)'
                                : form.pricingModel == PricingModel.hourly
                                ? 'Typical session duration (minutes)'
                                : 'Duration (minutes)',
                          ),
                          SizedBox(height: 6.h),
                          _InputField(
                            controller: _durationCtrl,
                            hint: 'e.g. 45',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: ref
                                .read(addServiceFormProvider.notifier)
                                .updateDuration,
                            validator: (v) {
                              if (v != null &&
                                  v.isNotEmpty &&
                                  int.tryParse(v) == null) {
                                return 'Enter a valid duration';
                              }
                              if (form.pricingModel == PricingModel.package &&
                                  (v == null || v.isEmpty)) {
                                return 'Duration required for package';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 14.h),

                          // Active checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: form.isActive,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                onChanged: (v) {
                                  if (v != null) {
                                    ref
                                        .read(addServiceFormProvider.notifier)
                                        .updateIsActive(v);
                                  }
                                },
                              ),
                              Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Note: Availability is now managed at provider profile level
                    // Service availability inherits from provider's global schedule
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ),
          // Footer actions
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(addServiceFormProvider.notifier).reset();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black87, fontSize: 14.sp),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 18.w,
                            height: 18.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? 'Update' : 'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared local helper widgets
// ---------------------------------------------------------------------------

class _MediaSection extends StatelessWidget {
  final List<ServiceMediaDto> existingMedia;
  final List<String> pendingMediaPaths;
  final bool canAddMore;
  final VoidCallback onAddMedia;
  final ValueChanged<int> onRemovePending;
  final ValueChanged<ServiceMediaDto> onRemoveExisting;

  const _MediaSection({
    required this.existingMedia,
    required this.pendingMediaPaths,
    required this.canAddMore,
    required this.onAddMedia,
    required this.onRemovePending,
    required this.onRemoveExisting,
  });

  @override
  Widget build(BuildContext context) {
    final hasMedia = existingMedia.isNotEmpty || pendingMediaPaths.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMedia)
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                ...existingMedia.map(
                  (media) => _MediaThumbnail(
                    imagePath: media.url,
                    isNetwork: true,
                    onRemove: () => onRemoveExisting(media),
                  ),
                ),
                ...pendingMediaPaths.asMap().entries.map(
                  (entry) => _MediaThumbnail(
                    imagePath: entry.value,
                    onRemove: () => onRemovePending(entry.key),
                  ),
                ),
              ],
            )
          else
            Text(
              'Add up to ${AddServiceFormState.maxMediaCount} images for this service.',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
            ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canAddMore ? onAddMedia : null,
              icon: Icon(Icons.photo_library_outlined, size: 18.r),
              label: Text(canAddMore ? 'Add image' : 'Maximum images reached'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final String imagePath;
  final bool isNetwork;
  final VoidCallback? onRemove;

  const _MediaThumbnail({
    required this.imagePath,
    this.isNetwork = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            width: 84.w,
            height: 84.h,
            color: Colors.grey.shade100,
            child: isNetwork
                ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image_outlined);
                    },
                  )
                : Image(
                    image: FileImage(io.File(imagePath)),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_outlined);
                    },
                  ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4.h,
            right: 4.w,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22.w,
                height: 22.h,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 14.r, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextCapitalization textCapitalization;

  const _InputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.validator,
    this.textCapitalization = TextCapitalization.sentences,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      textCapitalization: textCapitalization,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 20.r),
          style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelOf(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
