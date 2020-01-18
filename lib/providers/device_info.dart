import 'package:flutter/material.dart';

class ProviderDeviceInfo with ChangeNotifier {

  update() {
    notifyListeners();
  }

}