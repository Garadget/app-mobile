import 'package:flutter/material.dart';

void showSnackbarMessage(
  BuildContext context,
  String message, {
  IconData icon,
}) {
  Scaffold.of(context).showSnackBar(
    SnackBar(
      content: _ErrorMessage(message, icon: icon),
    ),
  );
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  final IconData icon;

  _ErrorMessage(
    this.message, {
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Icon(icon ?? Icons.error),
        const SizedBox(
          width: 5,
        ),
        Expanded(
          child: Text(
            message,
            softWrap: true,
            maxLines: 5,
          ),
        ),
      ],
    );
  }
}

class FooterErrorMessaage extends StatelessWidget {
  final String message;
  final IconData icon;

  FooterErrorMessaage(
    this.message, {
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.0,
          color: const Color(0xFFFF0000),
        ),
        color: const Color(0xFFFFE0E0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: _ErrorMessage(message, icon: icon),
    );
  }
}
