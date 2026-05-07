import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SystemUpdateWidget extends StatefulWidget {
  const SystemUpdateWidget({super.key});

  @override
  State<SystemUpdateWidget> createState() => _SystemUpdateWidgetState();
}

class _SystemUpdateWidgetState extends State<SystemUpdateWidget> {
  bool _automaticUpdates = false;
  bool _installOnceDownloaded = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildSwitchTile(
          'Automatic Updates',
          _automaticUpdates,
          (value) => setState(() => _automaticUpdates = value),
        ),
        SizedBox(height: 16.h),
        Text(
          'This update provides bug fixes for your system including:',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
        ),
        SizedBox(height: 16.h),
        ...List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    'This update provides bug fixes for your system including',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Download in progress',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.downloading, size: 20.sp),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Text(
                'System has has started downloading an update automatically. Once completed, system will attempt to install the update later.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 32.h),
        _buildSwitchTile(
          'Install once downloaded',
          _installOnceDownloaded,
          (value) => setState(() => _installOnceDownloaded = value),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.black,
        ),
      ],
    );
  }
}
