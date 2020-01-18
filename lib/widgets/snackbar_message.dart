import 'package:flutter/material.dart';

void showSnackbarMessage(
  BuildContext context,
  String message, {
  IconData icon,
}) {
  Scaffold.of(context).showSnackBar(
    SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(icon ?? Icons.error),
          SizedBox(
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
      ),
    ),
  );
}
