import 'package:flutter/material.dart';

class InputTheme {
  static InputDecoration of(BuildContext context) {
    final inputNormalBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).primaryColor,
        width: 1.0,
      ),
    );
    final inputErrorBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).errorColor,
        width: 1.0,
      ),
    );
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
      border: inputNormalBorder,
      enabledBorder: inputNormalBorder,
      focusedBorder: inputNormalBorder,
      errorBorder: inputErrorBorder,
      focusedErrorBorder: inputErrorBorder,
    );
  }
}
