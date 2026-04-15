import 'package:flutter/material.dart';

class HeaderClipper extends StatelessWidget {
  const HeaderClipper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.23,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(80)),
      ),
      child: Stack(children: [child]),
    );
  }
}

class BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // An organic blob-like shape approximation
    Path path = Path();
    path.moveTo(size.width * 0.2, 0);
    path.quadraticBezierTo(
      size.width * 0.8,
      -20,
      size.width,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 1.1,
      size.height * 0.7,
      size.width * 0.6,
      size.height * 0.9,
    );
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 1.05,
      0,
      size.height * 0.6,
    );
    path.quadraticBezierTo(-20, size.height * 0.2, size.width * 0.2, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
