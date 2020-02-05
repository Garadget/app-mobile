import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/bottom_navigation.dart';
import '../widgets/error_message.dart';
import '../widgets/busy_message.dart';
import '../models/device.dart';
import '../providers/account.dart';
import '../providers/device_status.dart';
import '../providers/device_info.dart';
import './local_auth.dart';

class ScreenDeviceRemove extends StatefulWidget {
  static const routeName = '/device/remove';

  @override
  _ScreenDeviceRemoveState createState() => _ScreenDeviceRemoveState();
}

class _ScreenDeviceRemoveState extends State<ScreenDeviceRemove> {
  bool _isBusy = true;
  bool _isFirstRun = true;
  String _errorMessage;
  ProviderAccount _account;
  Device _device;

  // @override
  void didChangeDependencies() {
    if (_isFirstRun) {
//      ModalRoute.of(context).settings.arguments as Device;
      _account = Provider.of<ProviderAccount>(context, listen: false);

      _device = _account.selectedDevice;
      _device.particleDevice.getInfo().catchError((error) {
        _errorMessage = error;
      }).whenComplete(() {
        setState(() {
          _isBusy = false;
        });
      });
      _isFirstRun = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy) {
      return BusyScreen('Loading...');
    } else if (_errorMessage != null) {
      return ErrorScreen(_errorMessage);
    } else {
      Provider.of<ProviderDeviceStatus>(context, listen: true);
      Provider.of<ProviderDeviceInfo>(context, listen: true);

      return Scaffold(
        appBar: AppBar(
          title: Text('Remove Device'),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  RaisedButton(
                    child: const Text('Remove'),
                    onPressed: _removeDevice,
                  ),
                ],
              ),
            ),
            BottomNavigation(3),
          ],
        ),
        body: ErrorScreen(
          'You are about to remove device \'${_device.name}\' from your account ${_account.accountEmail}.\n\nTo add this unit to the same or a different account repeat the device setup process again.',
          header: 'Warning',
          icon: Icons.warning,
        ),
      );
    }
  }

  Future<void> _removeDevice() async {
    bool allowed = await localAuthChallageDialog(context, AuthLevel.ACTIONS);
    if (!allowed) {
      return false;
    }
    try {
        await _account.removeDevice(_device.id);
        Navigator.of(context).pop();
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    }
  }
}
