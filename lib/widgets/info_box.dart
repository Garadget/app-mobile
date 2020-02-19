import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  final Widget child;

  const InfoBox(
    this.child, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.0,
            color: const Color(0xFFFF0000),
          ),
          color: const Color(0xFFFFE0E0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: child,
      ),

      //Text('Please try submitting WiFi credentials again, while double checking the password.\nIf the issue persists, please visit the troubleshooting guide or contact our tecnical support.'),
    );
  }
}
