import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/services/presentation/pages/service_detail_page.dart';
import 'package:flutter/material.dart';

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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: service.imagePath != null
                        ? _buildServiceImage(service.imagePath!)
                        : _ImageFallback(),
                  ),

                  // Active / inactive badge (top-left)
                  if (isProvider)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: service.isActive
                              ? AppColors.success
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          service.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Action button (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
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
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.pricingModel.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.category != null && service.category!.isNotEmpty)
                    Text(
                      service.category!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.formattedPrice,
                    style: const TextStyle(
                      fontSize: 13,
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
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16),
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
      child: const Center(
        child: Icon(Icons.image_outlined, size: 32, color: Colors.black26),
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
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, size: 16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 8),
              Text('Edit', style: TextStyle(fontSize: 13)),
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
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Deactivate' : 'Activate',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: AppColors.primaryRed),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(fontSize: 13, color: AppColors.primaryRed),
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
