import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
  final String message;
  final IconData icon;

  ErrorMessage(
    this.message, {
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SnackBar(
        content: Row(
      children: <Widget>[
        Icon(this.icon ?? Icons.error),
        SizedBox(
          width: 5,
        ),
        Text(message),
      ],
    ));
  }
}

Widget errorDialog(BuildContext context, String title, String message) {
  return AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: <Widget>[
      RaisedButton(
        child: Text('Dismiss'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ],
  );
}

Future showErrorDialog(BuildContext context, String title, String message) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return errorDialog(ctx, title, message);
    },
  );
}

class ErrorScreen extends StatelessWidget {
  final String message;
  ErrorScreen(this.message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ErrorMessage(message),
      ),
    );
  }
}
