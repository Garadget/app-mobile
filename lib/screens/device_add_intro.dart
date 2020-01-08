import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/account.dart';
import '../widgets/busy_message.dart';
import '../widgets/network_error.dart';
import './device_add_config.dart';
import './account_signin.dart';

class ScreenDeviceAddIntro extends StatefulWidget {
  static const routeName = '/device/add/intro';

  @override
  _ScreenDeviceAddIntroState createState() => _ScreenDeviceAddIntroState();
}

class _ScreenDeviceAddIntroState extends State<ScreenDeviceAddIntro> {
  bool _isLoading = false;
  bool _isFirstRun = true;
  String _errorMessage;
  ProviderAccount _account;
  String _claimCode;

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
    if (_isFirstRun && _claimCode == null) {
      _isFirstRun = false;
      _account = Provider.of<ProviderAccount>(context, listen: false);
      _account.stopTimer();
      await _account.initStorage();

      if (_isLoading) {
        return;
      }
      setState(() {
        _errorMessage = null;
        _isLoading = true;
      });

      await tryNetwork(
        () async {
          _claimCode = await _account.getClaimCode();
          return true;
        },
        onError: (error) {
          setState(() {
            _errorMessage = error;
          });
        },
        onRetry: () => mounted,
      );
      setState(() {
        _errorMessage = null;
        _isLoading = false;
      });
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {

    Widget body;
    Widget footer = SizedBox.shrink();
    if (_isLoading && _errorMessage == null) {
      return BusyScreen('Loading...');
    } else if (_errorMessage != null) {
      body = NetworkError(_errorMessage);
    } else {
      body = ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: <Widget>[
          Image.asset('assets/images/powerup.png'),
          const SizedBox(
            height: 30,
          ),
          const ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Power up'),
            subtitle: Text(
                'Plug in outlet adapter and connect Garadget using micro-USB cable.'),
          ),
          const ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Setup Mode'),
            subtitle: Text(
                'Garadget\'s LED should be blinking dark blue. If it doesn\'t, hold "M" button for 3 seconds.'),
          ),
          const ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Internet Connection'),
            subtitle: Text(
                'Received authorization from the server and ready to proceed.'),
          ),
        ],
      );
      footer = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _account.devices.length == 0
                ? FlatButton(
                    child: Text('logout'),
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          ScreenAccountSignin.routeName,
                          (route) => route.isFirst);
                    },
                  )
                : FlatButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                        Navigator.of(context).pop();
                    },
                  ),
            RaisedButton(
              child: const Text('Next'),
              onPressed: _claimCode == null
                  ? null
                  : () {
                      Navigator.of(context).pushNamed(
                          ScreenDeviceAddConfig.routeName,
                          arguments: _claimCode);
                    },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Device - Prepare"),
      ),
      bottomNavigationBar: footer,
      body: body,
    );
  }
}
