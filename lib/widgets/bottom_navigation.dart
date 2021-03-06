import 'package:flutter/material.dart';

import '../screens/home.dart';
import '../screens/device_settings.dart';
import '../screens/device_alerts.dart';
import '../screens/device_remove.dart';

class BottomNavigation extends StatelessWidget {

  final int currentIndex;
  static const ROUTES = [
    ScreenHome.routeName,
    ScreenDeviceSettings.routeName,
    ScreenDeviceAlerts.routeName,
    ScreenDeviceRemove.routeName,
  ];

  BottomNavigation(this.currentIndex);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            title: Text('Settings'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            title: Text('Alerts'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete),
            title: Text('Remove'),
          ),
        ],
        currentIndex: currentIndex,
        onTap: (item) {
          if (item == 0) {
            Navigator.of(context).pop();  
          }
          else {
            Navigator.of(context).pushReplacementNamed(ROUTES[item]);
          }
        },
      );
  }
}