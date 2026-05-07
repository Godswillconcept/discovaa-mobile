import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactInfoCard extends StatelessWidget {
  const ContactInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark card
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Contact Information",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Say something to start a live chat!",
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
          SizedBox(height: 32.h),
          _buildInfoRow(Icons.phone_in_talk, "+1012 3456 789"),
          SizedBox(height: 20.h),
          _buildInfoRow(Icons.email, "discovaa@gmail.com"),
          SizedBox(height: 48.h),
          Text(
            "Join Our Newsletter",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.h),
          _buildNewsletterSection(),
          SizedBox(height: 12.h),
          Text(
            "* Will send you weekly updates for your better tool management.",
            style: TextStyle(color: Colors.grey, fontSize: 11.sp),
          ),
          SizedBox(height: 48.h),
          _buildSocialIcons(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20.sp),
        SizedBox(width: 16.w),
        Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
      ],
    );
  }

  Widget _buildNewsletterSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                bottomLeft: Radius.circular(8.r),
              ),
            ),
            child: Center(
              child: TextField(
                style: TextStyle(color: Colors.white, fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: "Your email address",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13.sp),
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        Container(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8.r),
              bottomRight: Radius.circular(8.r),
            ),
          ),
          child: Center(
            child: Text(
              "Subscribe",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FaIcon(FontAwesomeIcons.twitter, color: Colors.white, size: 20.sp),
        SizedBox(width: 24.w),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            FontAwesomeIcons.instagram,
            color: Colors.black,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 24.w),
        FaIcon(FontAwesomeIcons.discord, color: Colors.white, size: 20.sp),
      ],
    );
  }
}
