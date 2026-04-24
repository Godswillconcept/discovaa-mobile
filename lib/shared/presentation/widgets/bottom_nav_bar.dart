import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, 'Home', customIconPath: 'assets/icons/home.png'),
          _buildNavItem(
            1,
            'Dashboard',
            iconData: Icons.grid_view,
            selectedIconData: Icons.grid_view,
          ),
          _buildNavItem(
            2,
            'Bookings',
            iconData: Icons.event_outlined,
            selectedIconData: Icons.event,
          ),
          _buildNavItem(
            3,
            'Messages',
            iconData: Icons.mail_outline,
            selectedIconData: Icons.mail,
          ),
          if (showServicesTab)
            _buildNavItem(
              4,
              'Services',
              iconData: Icons.work_outline,
              selectedIconData: Icons.work,
            ),
        ],
      ),
    );
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
    const double size = 24.0;

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
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 30,
              height: 2,
              color: Colors.white,
            ),
        ],
      ),
    );
  }
}
