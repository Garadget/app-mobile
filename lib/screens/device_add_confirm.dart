import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../misc/input_decoration.dart';
import '../providers/account.dart';
import './home.dart';
import './account_signin.dart';
import '../widgets/linked_text.dart';
import '../widgets/busy_message.dart';
import '../widgets/error_message.dart';
import '../widgets/info_box.dart';

const DEVICE_NAME_PREFIX = 'Garage';

class ScreenDeviceAddConfirm extends StatefulWidget {
  static const routeName = '/device/add/confirm';

  @override
  _ScreenDeviceAddConfirmState createState() => _ScreenDeviceAddConfirmState();
}

class _ScreenDeviceAddConfirmState extends State<ScreenDeviceAddConfirm> {
  bool _isFirstRun = true;
  bool _isPhoneOnline = false;
  bool _wifiAdvice = false;
  bool _isDeviceOnline = false;
  bool _deviceOfflineAdvice = false;
  bool _isConfirmed = false;
  bool _resetAdvice = false;
  List<bool> _cancelFutures = [false, false];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = new TextEditingController();

  ProviderAccount _account;
  String _deviceId;
  String _deviceName;
  Device _device;

  @override
  void deactivate() {
    _cancelFutures = [true, true];
    _isFirstRun = true;
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      _deviceId = ModalRoute.of(context).settings.arguments as String;
      // await for internet
      await _confirm(0).timeout(Duration(seconds: 15), onTimeout: () {
        _cancelFutures[0] = true;
        if (!_isPhoneOnline) {
          setState(() {
            _wifiAdvice = true;
          });
        }
      });
      // await for confirmation
      await _confirm(1).timeout(Duration(seconds: 30), onTimeout: () {
        // continue
//        _cancelFutures[1] = true;
        if (!_isConfirmed) {
          setState(() {
            _resetAdvice = true;
          });
        } else if (!_isDeviceOnline) {
          setState(() {
            _deviceOfflineAdvice = true;
          });
        }
      });
    }
    super.didChangeDependencies();
  }

  Future<void> _confirm(int futureNumber) async {
    while (true) {
      if (!mounted || _cancelFutures[futureNumber]) {
        return;
      }
      try {
        if (_device == null) {
          await _account.loadDevices();
          setState(() {
            _wifiAdvice = false;
            _isPhoneOnline = true;
          });
          _device = _account.devices.singleWhere((device) {
            return (device.id == _deviceId);
          });
          setState(() {
            _isConfirmed = true;
            _resetAdvice = false;
          });
        } else if (_device.connectionStatus == ConnectionStatus.ONLINE) {
          setState(() {
            _isDeviceOnline = true;
            _deviceOfflineAdvice = false;
          });
          return;
        }
      } catch (error) {
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
    Widget onlineStatus;
    Widget confirmStatus = SizedBox.shrink();
    Widget actionBlock = SizedBox.shrink();
    Widget troubleShooting = InfoBox(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Please try again, making sure you enter the correct WiFi password.\n\nIf the issue persists, refer to these support resources:'),
          LinkedText('Troubleshooting Guide', 'https://www.garadget.com/fixme'),
          LinkedText('Community Board', 'https://community.garadget.com/'),
          LinkedText(
              'Technical Support', 'https://www.garadget.com/contact-us'),
        ],
      ),
    );
    if (_isPhoneOnline) {
      // phone reconnected
      onlineStatus = ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: const Text('Back Online'),
        subtitle: Text(
            'Your $platform device switched back to your regular Internet connection.'),
      );
      // device confirmed
      if (_isConfirmed) {
        // device confirmed and online
        if (_isDeviceOnline) {
          confirmStatus = ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Success'),
            subtitle: Text(
                'New device is online and the server has confirmed a successful setup.'),
          );

          // suggest a unique name
          if (_deviceName == null) {
            _deviceName = DEVICE_NAME_PREFIX;
            int deviceSuffix = 2;
            while (_account.devices
                    .indexWhere((device) => device.name == _deviceName) >=
                0) {
              _deviceName = '$DEVICE_NAME_PREFIX ${deviceSuffix.toString()}';
              deviceSuffix++;
            }
          }
          _controller.value = _controller.value.copyWith(
            text: _deviceName,
          );

          actionBlock = Form(
            key: _formKey,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                const SizedBox(
                  width: 72,
                ),
                Expanded(
                  child: TextFormField(
                    autocorrect: false,
                    autofocus: true,
                    controller: _controller,
                    onFieldSubmitted: (_) {
                      _renameAndExit();
                    },
                    decoration: InputTheme.of(context).copyWith(
                      labelText: 'Door Name',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) => _controller.clear());
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Device name is required';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _deviceName = value;
                      });
                    },
                  ),
                ),
                const SizedBox(
                  width: 45,
                ),
              ],
            ),
          );
        }
        // device confirmed but offline
        else if (_deviceOfflineAdvice) {
          confirmStatus = ListTile(
            leading: const Icon(Icons.error_outline),
            title: const Text('Not Connected'),
            subtitle: Text(
                'The device is already in your account, but it did not come online.'),
          );
          actionBlock = troubleShooting;
        }
        // device confirmed awaiting to come online
        else {
          confirmStatus = const ListTile(
            leading: const CircularProgressIndicator(),
            title: const Text('Waiting For Connection'),
            subtitle: Text('Garadget is added to account, but not yet online.'),
          );
        }

        // device not confirmed
      } else if (_resetAdvice) {
        confirmStatus = const ListTile(
          leading: const Icon(Icons.hourglass_empty),
          title: const Text('Setup Failed'),
          subtitle: Text('Garadged did not come online as expected.'),
        );
        actionBlock = troubleShooting;
      }
      // awaiting device confirmation
      else {
        confirmStatus = const ListTile(
          leading: const CircularProgressIndicator(),
          title: const Text('Waiting For Confirmation'),
          subtitle: Text(
              'Server needs to confirm that new Garadget is online and associated with your account.'),
        );
      }
      // awaiting manual internet connection
    } else if (_wifiAdvice) {
      onlineStatus = ListTile(
        leading: const Icon(Icons.cloud_off),
        title: const Text('Reconnect to Internet'),
        subtitle: Text(
            'In WiFi settings for this $platform device connect to your regular Internet connection.'),
      );
      // awaiting automatic internet connection
    } else {
      onlineStatus = ListTile(
        leading: const CircularProgressIndicator(),
        title: const Text('Waiting for Internet'),
        subtitle: Text(
            'Your $platform device should automatically reconnect to the Internet.'),
      );
    }

    Widget cancelButton;
    Widget actionButton;

    if (_isConfirmed && _isDeviceOnline) {
      cancelButton = SizedBox.shrink();
      actionButton = RaisedButton(
        child: const Text('Done'),
        onPressed: () {
          _renameAndExit();
        },
      );
    } else {
      cancelButton = _account.devices.length == 0
          ? FlatButton(
              child: Text('logout'),
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  ScreenAccountSignin.routeName,
                  (route) => route.isFirst,
                );
              },
            )
          : FlatButton(
              child: const Text('Cancel'),
              onPressed: () {
                _account.deviceSelectById(_deviceId);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  ScreenHome.routeName,
                  (route) => route.isFirst,
                );
              },
            );
      actionButton = RaisedButton(
        child: const Text('Try Again'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Wrapping Up'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            cancelButton,
            actionButton,
          ],
        ),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: <Widget>[
            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Submitted'),
              subtitle: Text(
                  'Garadget received WiFi credentials and now connecting to your router.'),
            ),
            onlineStatus,
            confirmStatus,
            const SizedBox(
              height: 15,
            ),
            actionBlock,
          ],
        ),
      ),
    );
  }

  _renameAndExit() async {
    try {
      await showBusyMessage(context, 'Submitting...');
      await _device.rename(_deviceName);
      _account.deviceSelectById(_deviceId);
      Navigator.of(context).pushNamedAndRemoveUntil(
        ScreenHome.routeName,
        (route) => route.isFirst,
      );
    } catch (error) {
      showErrorDialog(context, 'Error Renaming',
          'There was an error renaming your Garadget.\n\nDetails: ${error.toString()}');
    }
  }
}
