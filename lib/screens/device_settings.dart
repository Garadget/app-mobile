import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../widgets/bottom_navigation.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_item.dart';
import '../widgets/settings_select.dart';
import '../widgets/error_message.dart';
import '../widgets/busy_message.dart';
import '../widgets/snackbar_message.dart';
import '../models/device.dart';
import '../providers/account.dart';
import '../providers/device_status.dart';
import '../providers/device_info.dart';
import './local_auth.dart';

const List<Map<String, dynamic>> VALUES_SCANPERIOD = [
  {'value': 500, 'text': 'Twice per Second'},
  {'value': 1000, 'text': 'Every Second'},
  {'value': 2000, 'text': 'Every 2 Seconds'},
  {'value': 3000, 'text': 'Every 3 Seconds'},
  {'value': 5000, 'text': 'Every 5 Seconds'},
  {'value': 10000, 'text': 'Every 10 Seconds'},
  {'value': 30000, 'text': 'Twice per Minute'},
  {'value': 60000, 'text': 'Every Minute'},
];

const List<int> VALUES_THRESHOLD = [
  5,
  10,
  15,
  20,
  25,
  30,
  35,
  40,
  45,
  50,
  55,
  60,
  65,
  70,
  75,
  80
];
const List<int> VALUES_RELAYONTIME = [200, 300, 400, 500, 700, 1000];
const List<int> VALUES_RELAYOFFTIME = [
  300,
  400,
  500,
  600,
  700,
  800,
  900,
  1000,
  1500,
  2000,
  2500,
  3000,
  4000,
  5000
];

class ScreenDeviceSettings extends StatefulWidget {
  static const routeName = '/device/settings';

  @override
  _ScreenDeviceSettingsState createState() => _ScreenDeviceSettingsState();
}

class _ScreenDeviceSettingsState extends State<ScreenDeviceSettings> {
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
      Future.wait([
        _device.particleDevice.getInfo(),
        _device.loadConfig(),
      ]).then((result) {
        return _account.storeDevices();
      }).catchError((error) {
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
          title: Text('Settings'),
        ),
        bottomNavigationBar: BottomNavigation(2),
        body: ListView(
          children: <Widget>[
            // @todo: offline option

            SettingsHeader('DEVICE'),
            SettingsItem(
              'ID',
              value: _device.id,
              icon: Icons.content_copy,
              action: (ctx) {
                _copyToClipboard(ctx, _device.id);
              },
            ),
            SettingsItem('Name', value: _device.name, icon: Icons.edit,
                action: (ctx) {
              _renameDevice(ctx, _device);
            }),
            SettingsItem(
              'System',
              value: _device.getValue('config/systemVersion'),
            ),
            SettingsItem(
              'Firmware',
              value: _device.getValue('config/firmwareVersion'),
            ),
//            SettingsItem('Last Contact', 'value'),
            SettingsHeader('NETWORK'),
            SettingsItem(
              'WiFi SSID',
              value: _device.getValue('net/ssid'),
            ),
            SettingsItem(
              'Signal Quality',
              value: ProviderAccount.wifiSignalToString(
                _device.getValue('status/wifiSignal') as int,
              ),
            ),
            SettingsItem(
              'IP',
              value: _device.getValue('net/ip'),
            ),
            SettingsItem(
              'Gateway',
              value: _device.getValue('net/gateway'),
            ),
            SettingsItem(
              'Mask',
              value: _device.getValue('net/subnet'),
            ),
            SettingsItem(
              'MAC',
              value: _device.getValue('net/mac'),
            ),
            SettingsHeader('SENSOR'),
            SettingsItem(
              'Status',
              value: _device.doorStatusString,
            ),
            SettingsItem(
              'Reflection',
              value: _device.getValue('status/reflection').toString() + '%',
            ),
            SettingsSelect(
              'Sensor Threshold',
              VALUES_THRESHOLD.map((value) => _percentOption(value)).toList(),
              _percentOption(_device.getValue('config/sensorThreshold') ?? 10),
              (value) {
                return _deviceSaveValue('config/sensorThreshold', value);
              },
            ),
            SettingsSelect(
              'Scan Period',
              VALUES_SCANPERIOD,
              VALUES_SCANPERIOD.firstWhere(
                (item) =>
                    item['value'] == _device.getValue('config/scanInterval'),
                orElse: () => VALUES_SCANPERIOD[1],
              ),
              (value) {
                return _deviceSaveValue('config/scanInterval', value);
              },
            ),
            SettingsHeader('OPENER'),
            SettingsSelect(
              'Door Motion Time',
              List<Map<String, dynamic>>.generate(
                  26, (pos) => _wholeSecondsOption(pos * 1000 + 5000)),
              _wholeSecondsOption(
                  _device.getValue('config/doorMotionTime') ?? 10000),
              (value) {
                return _deviceSaveValue('config/doorMotionTime', value);
              },
            ),
            SettingsSelect(
              'Relay On Time',
              VALUES_RELAYONTIME
                  .map((value) => _fractionalSecondsOption(value))
                  .toList(),
              _fractionalSecondsOption(
                  _device.getValue('config/relayOnTime') ?? 300),
              (value) {
                return _deviceSaveValue('config/relayOnTime', value);
              },
            ),
            SettingsSelect(
              'Relay Off Time',
              VALUES_RELAYOFFTIME
                  .map((value) => _fractionalSecondsOption(value))
                  .toList(),
              _fractionalSecondsOption(
                  _device.getValue('config/relayOffTime') ?? 1000),
              (value) {
                return _deviceSaveValue('config/relayOffTime', value);
              },
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _deviceSaveValue(String key, dynamic value) {
    return localAuthChallageDialog(context, AuthLevel.ACTIONS).then((allowed) {
      if (!allowed) {
        return false;
      }
      _device.setValue(key, value);
      return _device.saveConfig().then((_) {
        return _account.storeDevices();
      }).then((_) {
        return true;
      });
    });
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSnackbarMessage(context, "Copied to Clipboard",
        icon: Icons.content_copy);
  }

  void _renameDevice(BuildContext context, Device device) {
    localAuthChallageDialog(context, AuthLevel.ACTIONS).then((allowed) {
      if (!allowed) {
        return false;
      }

      bool _busy = false;
      final _controller = TextEditingController();
      _controller.addListener(() {
        if (_busy) {
          return;
        }
        _busy = true;
        final re = RegExp(r'[^a-zA-Z0-9\s]');
        final text = _controller.text.replaceAll(re, '');
        if (_controller.text == text) {
          _busy = false;
          return;
        }
        _controller.value = _controller.value.copyWith(
          text: text,
          selection: TextSelection(
            baseOffset: text.length,
            extentOffset: text.length,
          ),
          composing: TextRange.empty,
        );
        _busy = false;
      });

      return showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text('Rename Garadget'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    autocorrect: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: device.name,
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(31),
                    ],
                    controller: _controller,
                  )
                ],
              ),
              actions: <Widget>[
                RaisedButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(ctx).pop(false);
                  },
                ),
                RaisedButton(
                  child: const Text('Rename'),
                  onPressed: () {
                    String newName = _controller.text;
                    Navigator.of(ctx).pop(true);
                    if (newName.length == 0 || newName == device.name) {
                      return false;
                    }
                    showBusyMessage(context, 'Renaming...');
                    device.rename(newName).whenComplete(() {
                      Navigator.of(context).pop();
                    }).then((_) {
                      print('renamed');
                    }).catchError((error) {
                      showSnackbarMessage(context, "Error Renaming Device");
                      print('error: ${error.toString()}');
                    });
                    return true;
                  },
                ),
              ],
            );
          });
    });
  }

  Map<String, dynamic> _percentOption(int value) {
    return {'text': '$value%', 'value': value};
  }

  Map<String, dynamic> _wholeSecondsOption(int value) {
    final seconds = (value / 1000).round();
    final units = value == 1000 ? 'second' : 'seconds';
    return {'text': '$seconds $units', 'value': value};
  }

  Map<String, dynamic> _fractionalSecondsOption(int value) {
    final seconds = (value / 1000).toStringAsFixed(1);
    final units = value == 1000 ? 'second' : 'seconds';
    return {'text': '$seconds $units', 'value': value};
  }
}
