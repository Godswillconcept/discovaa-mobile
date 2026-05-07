import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool showServicesTab;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.showServicesTab = true,
  });

  @override
  Widget build(BuildContext context) {
    // Build nav items - all tabs always visible
    final navItems = _buildNavItems();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildNavItem(
            index,
            item.label,
            iconData: item.iconData,
            selectedIconData: item.selectedIconData,
            customIconPath: item.customIconPath,
          );
        }).toList(),
      ),
    );
  }

  List<_NavItemData> _buildNavItems() {
    final items = <_NavItemData>[];

    // Home (always available)
    items.add(
      _NavItemData(label: 'Home', customIconPath: 'assets/icons/home.png'),
    );

    // Dashboard (always visible, shows Coming Soon if disabled)
    items.add(
      _NavItemData(
        label: 'Dashboard',
        iconData: Icons.grid_view,
        selectedIconData: Icons.grid_view,
      ),
    );

    // Bookings (always available)
    items.add(
      _NavItemData(
        label: 'Bookings',
        iconData: Icons.event_outlined,
        selectedIconData: Icons.event,
      ),
    );

    // Messages (always visible, shows Coming Soon if disabled)
    items.add(
      _NavItemData(
        label: 'Messages',
        iconData: Icons.mail_outline,
        selectedIconData: Icons.mail,
      ),
    );

    // Services (provider only)
    if (showServicesTab) {
      items.add(
        _NavItemData(
          label: 'Services',
          iconData: Icons.work_outline,
          selectedIconData: Icons.work,
        ),
      );
    }

    return items;
  }

  Widget _buildNavItem(
    int index,
    String label, {
    IconData? iconData,
    IconData? selectedIconData,
    String? customIconPath,
  }) {
    final bool isSelected = selectedIndex == index;
    final Color iconColor = isSelected ? Colors.white : const Color(0xFFB0B0B0);
    final size = 24.0.sp;

    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          customIconPath != null
              ? Image.asset(
                  customIconPath,
                  width: size,
                  height: size,
                  color: iconColor,
                )
              : Icon(
                  isSelected ? selectedIconData : iconData,
                  color: iconColor,
                  size: size,
                ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 10.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: EdgeInsets.only(top: 4.h),
              width: 30.w,
              height: 2.h,
              color: Colors.white,
            ),
        ],
      ),
    );
  }
}

/// Helper class for navigation item data
class _NavItemData {
  final String label;
  final IconData? iconData;
  final IconData? selectedIconData;
  final String? customIconPath;

  _NavItemData({
    required this.label,
    this.iconData,
    this.selectedIconData,
    this.customIconPath,
  });
}
