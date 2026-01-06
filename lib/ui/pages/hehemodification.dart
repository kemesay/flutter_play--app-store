import 'package:oda_black_car_service/utils/constants.dart';
import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final double height;

  const HeaderWidget({super.key, required this.height});
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: MyCustomClipper(),
      child: Container(
        height: height,
        color: const Color.fromARGB(255, 33, 188, 87),
        child: Center(
          child: SizedBox(
            width: 200,
            child: Image.asset(
              Constatnts.logo,
              height: 100,
            ),
          ),
        ),
      ),
    );
  }
}

class NoLogoHeaderWidget extends StatelessWidget {
  final double height;

  const NoLogoHeaderWidget({super.key, required this.height});
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: MyCustomClipper(),
      child: Container(
        height: height,
        color: const Color(0xff2dbb54),
        child: Center(
          child: Container(
            width: 200,
          ),
        ),
      ),
    );
  }
}

class MyCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 150);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 150);
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return false;
  }
}
