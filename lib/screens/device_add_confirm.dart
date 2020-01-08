import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
//import '../widgets/network_error.dart';
import '../providers/account.dart';

class ScreenDeviceAddConfirm extends StatefulWidget {
  static const routeName = "/device/add/confirm";

  @override
  _ScreenDeviceAddConfirmState createState() => _ScreenDeviceAddConfirmState();
}

class _ScreenDeviceAddConfirmState extends State<ScreenDeviceAddConfirm> {
//  bool _isLoading = false;
  bool _isFirstRun = true;
//  String _errorMessage;
  ProviderAccount _account;
  Device _device;

  @override
  void deactivate() {
    _isFirstRun = true;
    super.deactivate();
  }

  @override
  void setState(function) {
    if (mounted) {
      super.setState(function);
    }
  }

  @override
  void didChangeDependencies() async {
    if (_isFirstRun) {
      _isFirstRun = false;
      _account = Provider.of<ProviderAccount>(context, listen: false);
      final deviceId = ModalRoute.of(context).settings.arguments as String;
      _device = _account.addDevice(deviceId);
    }
    super.didChangeDependencies();
  }

  Future<void> _waitForInternet() async {

  }

  Future<void> _waitForDevice() async {
    while (true) {
      try {
        final online = await _device.getInfo();
        if (online) {
          return;
        }
      }
      catch(error) {
        print('Error while waiting: ${error.toString()}');
        if (error.toString() == 'timeout') {
          continue;
        }
      }
      await Future.delayed(Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {

    final platform = ProviderAccount.platformString(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Adding Device"),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Summary'),
              subtitle: Text(
                  'We have transmitted WiFi information to Garadget and it will now attempt connecting to your router. Your $platform device should reconnect to the Internet as well.'),
            ),
            const ListTile(
              leading: Icon(Icons.router),
              title: Text('Connecting to Router'),
              subtitle: Text(
                  'Blinking green LED indicates that Garadget connects to WiFi router. If this lasts lonter than few seconds or if LED switches back to blinking dark blue, then WiFi connection failed.'),
            ),
            const ListTile(
              leading: const Icon(Icons.cloud_queue),
              title: const Text('Internet Connection'),
              subtitle: Text(
                  'Received authorization from the server and ready to proceed.'),
            ),
          ],
        ),
      ),
    );
  }
}
