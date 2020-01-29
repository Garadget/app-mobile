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
  final String header;
  final String message;
  final IconData icon;
  ErrorScreen(this.message, {this.header, this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon ?? Icons.error_outline,
              size: 54,
            ),
            const SizedBox(height: 15),
            Text(
              header ?? 'Error',
              style: Theme.of(context).textTheme.title,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.body2,
            ),
          ],
        ),
      ),
    ),
      ),
    );
  }
}
