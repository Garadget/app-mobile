import 'package:flutter/material.dart';
import 'dart:async';

class BusyMessage extends StatelessWidget {
  final String message;
  final Completer onDisplayed;
  BusyMessage(this.message, {this.onDisplayed});

  @override
  createElement() {
    StatelessElement result = super.createElement();
    if (this.onDisplayed != null) {
      this.onDisplayed.complete();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final DialogTheme dialogTheme = DialogTheme.of(context);

    return AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets +
            const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        duration: const Duration(milliseconds: 100),
        curve: Curves.decelerate,
        child: MediaQuery.removeViewInsets(
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          context: context,
          child: Center(
            child: Material(
              color: dialogTheme.backgroundColor ??
                  Theme.of(context).dialogBackgroundColor,
              elevation: dialogTheme.elevation ?? 24,
              shape: dialogTheme.shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
              type: MaterialType.card,
              child: Container(
//                width: 150,
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 30),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.body2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

Future showBusyMessage(BuildContext context, String message) {
  Completer onDisplayed = new Completer();
  showDialog(
    context: context,
    builder: (_) {
      return BusyMessage(message, onDisplayed: onDisplayed);
    },
    barrierDismissible: false,
  );
  return onDisplayed.future;
}

class BusyScreen extends StatelessWidget {
  final String message;
  BusyScreen(this.message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: BusyMessage(message),
    ));
  }
}
