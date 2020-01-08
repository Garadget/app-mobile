import 'package:flutter/material.dart';

class ProviderStatus with ChangeNotifier {

  update() {
    notifyListeners();
  }

}