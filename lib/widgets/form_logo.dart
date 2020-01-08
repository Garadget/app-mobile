import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FormLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 25),
      child: SvgPicture.asset(
        'assets/images/logo-boxed.svg',
        color: Theme.of(context).primaryColor,
        fit: BoxFit.scaleDown,
        height: 80.0,
        width: 80.0,
        allowDrawingOutsideViewBox: true,
        semanticsLabel: 'Logo',
      ),
    );
  }
}
