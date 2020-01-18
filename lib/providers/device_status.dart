import 'package:flutter/material.dart';

class ProviderDeviceStatus with ChangeNotifier {

  update() {
    notifyListeners();
  }

}