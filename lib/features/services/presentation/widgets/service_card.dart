import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/services/presentation/pages/service_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card widget to display a single service in the grid.
/// Provides edit / toggle / delete callbacks for provider view.
class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final bool isProvider;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isProvider,
    this.onEdit,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ServiceDetailPage(service: service)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / banner area
            Expanded(
              child: Stack(
                children: [
                  // Cover image — handles both network URLs and local assets
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                    child: service.imagePath != null
                        ? _buildServiceImage(service.imagePath!)
                        : _ImageFallback(),
                  ),

                  // Active / inactive badge (top-left)
                  if (isProvider)
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: service.isActive
                              ? AppColors.success
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          service.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Action button (top-right)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: isProvider
                        ? _ActionMenu(
                            onEdit: onEdit,
                            onToggleStatus: onToggleStatus,
                            isActive: service.isActive,
                            onDelete: onDelete,
                          )
                        : _IconButton(icon: Icons.favorite_border, onTap: null),
                  ),

                  // Pricing model chip (bottom-right)
                  Positioned(
                    bottom: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        service.pricingModel.displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info area
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.category != null && service.category!.isNotEmpty)
                    Text(
                      service.category!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 2.h),
                  Text(
                    service.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    service.formattedPrice,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds service image widget, handling both network URLs and local assets
  Widget _buildServiceImage(String imagePath) {
    final isNetworkUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    if (isNetworkUrl) {
      return Image.network(
        imagePath,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _ImageFallback(),
      );
    }
    return Image.asset(
      imagePath,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => _ImageFallback(),
    );
  }
}

// ---------------------------------------------------------------------------
// Local helper widgets
// ---------------------------------------------------------------------------

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(6.r),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16.r),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Icon(Icons.image_outlined, size: 32.r, color: Colors.black26),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;
  final bool isActive;

  const _ActionMenu({
    this.onEdit,
    this.onToggleStatus,
    this.onDelete,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Container(
        padding: EdgeInsets.all(6.r),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_vert, size: 16.r),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16.r),
              SizedBox(width: 8.w),
              Text('Edit', style: TextStyle(fontSize: 13.sp)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Text(
                isActive ? 'Deactivate' : 'Activate',
                style: TextStyle(fontSize: 13.sp),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 16.r,
                color: AppColors.primaryRed,
              ),
              SizedBox(width: 8.w),
              Text(
                'Delete',
                style: TextStyle(fontSize: 13.sp, color: AppColors.primaryRed),
              ),
            ],
          ),
        ),
      ],
      onSelected: (v) {
        switch (v) {
          case 'edit':
            onEdit?.call();
            break;
          case 'toggle':
            onToggleStatus?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
    );
  }
}
