import 'package:flutter/material.dart';

class AuthSafeInfo extends StatelessWidget {
  const AuthSafeInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 14,
            color: Colors.grey,
          ),
          SizedBox(width: 6),
          Text(
            "Your Info is safely secured",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
