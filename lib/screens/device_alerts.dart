import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

import '../providers/account.dart';
import '../widgets/busy_message.dart';
import '../models/device.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/error_message.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_item.dart';
import '../widgets/settings_select.dart';
import '../widgets/settings_toggle.dart';
import '../widgets/geofence_map.dart';
import './local_auth.dart';

const LINK_HELP = 'https://www.garadget.com/help-alerts';

const List<Map<String, dynamic>> VALUES_TIMEOUTALERT = [
  {'value': 0, 'text': 'Disabled'},
  {'value': 30, 'text': '30 seconds'},
  {'value': 60, 'text': '1 minute'},
  {'value': 120, 'text': '2 minutes'},
  {'value': 180, 'text': '3 minutes'},
  {'value': 300, 'text': '5 minutes'},
  {'value': 600, 'text': '10 minutes'},
  {'value': 900, 'text': '15 minutes'},
  {'value': 1200, 'text': '20 minutes'},
  {'value': 1800, 'text': '30 minutes'},
  {'value': 2400, 'text': '40 minutes'},
  {'value': 3600, 'text': '1 hour'},
  {'value': 5400, 'text': '1.5 hours'},
  {'value': 7200, 'text': '2 hours'},
  {'value': 10800, 'text': '3 hours'},
  {'value': 14400, 'text': '4 hours'},
  {'value': 21600, 'text': '6 hours'},
  {'value': 28800, 'text': '8 hours'},
  {'value': 43200, 'text': '12 hours'},
];

const List<Map<String, dynamic>> VALUES_TIMEZONE = [
  {
    'value': '-12.00',
    'text': '(GMT-12:00) International Date Line West',
  },
  {
    'value': '-11.00',
    'text': '(GMT-11:00) Midway Island, Samoa',
  },
  {
    'value': '-10.00',
    'text': '(GMT-10:00) Hawaii',
  },
  {
    'value': '10112-9.00,20032-8.00',
    'text': '(GMT-09:00 +DST) Alaska',
  },
  {
    'value': '10112-8.00,20032-7.00',
    'text': '(GMT-08:00 +DST) Pacific Time (US & Canada)',
  },
  {
    'value': '10112-8.00,20032-7.00T',
    'text': '(GMT-08:00 +DST) Tijuana, Baja California',
  },
  {
    'value': '-7.00A',
    'text': '(GMT-07:00) Arizona',
  },
  {
    'value': '-7.00C',
    'text': '(GMT-07:00) Chihuahua, La Paz, Mazatlan',
  },
  {
    'value': '10112-7.00,20032-6.00',
    'text': '(GMT-07:00 +DST) Mountain Time (US & Canada)',
  },
  {
    'value': '-6.00A',
    'text': '(GMT-06:00) Central America',
  },
  {
    'value': '10112-6.00,20032-5.00',
    'text': '(GMT-06:00 +DST) Central Time (US & Canada)',
  },
  {
    'value': '-6.00G',
    'text': '(GMT-06:00) Guadalajara, Mexico City, Monterrey',
  },
  {
    'value': '-6.00S',
    'text': '(GMT-06:00) Saskatchewan',
  },
  {
    'value': '-5.00B',
    'text': '(GMT-05:00) Bogota, Lima, Quito, Rio Branco',
  },
  {
    'value': '10112-5.00,20032-4.00',
    'text': '(GMT-05:00 +DST) Eastern Time (US & Canada)',
  },
  {
    'value': '10112-5.00,20032-4.00,I',
    'text': '(GMT-05:00 +DST) Indiana (East)',
  },
  {
    'value': '10112-4.00,20032-3.00',
    'text': '(GMT-04:00 +DST) Atlantic Time (Canada)',
  },
  {
    'value': '-4.00C',
    'text': '(GMT-04:00) Caracas, La Paz',
  },
  {
    'value': '-4.00M',
    'text': '(GMT-04:00) Manaus',
  },
  {
    'value': '-4.00S',
    'text': '(GMT-04:00) Santiago',
  },
  {
    'value': '-3.50',
    'text': '(GMT-03:30) Newfoundland',
  },
  {
    'value': '-3.00',
    'text': '(GMT-03:00) Brasilia',
  },
  {
    'value': '-3.00A',
    'text': '(GMT-03:00) Buenos Aires, Georgetown',
  },
  {
    'value': '-3.00G',
    'text': '(GMT-03:00) Greenland',
  },
  {
    'value': '-3.00M',
    'text': '(GMT-03:00) Montevideo',
  },
  {
    'value': '-2.00',
    'text': '(GMT-02:00) Mid-Atlantic',
  },
  {
    'value': '-1.00',
    'text': '(GMT-01:00) Cape Verde Is.',
  },
  {
    'value': '0.00',
    'text': '(GMT+00:00) Monrovia, Reykjavik',
  },
  {
    'value': '00112+0.00,00032+1.00',
    'text': '(GMT+00:00 +DST) Dublin, Edinburgh, Lisbon, London',
  },
  {
    'value': '00112+1.00,00032+2.00',
    'text': '(GMT+01:00 +DST) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna',
  },
  {
    'value': '00112+1.00,00032+2.00,B',
    'text':
        '(GMT+01:00 +DST) Belgrade, Bratislava, Budapest, Ljubljana, Prague',
  },
  {
    'value': '00112+1.00,00032+2.00,C',
    'text': '(GMT+01:00 +DST) Brussels, Copenhagen, Madrid, Paris',
  },
  {
    'value': '00112+1.00,00032+2.00,S',
    'text': '(GMT+01:00 +DST) Sarajevo, Skopje, Warsaw, Zagreb',
  },
  {
    'value': '1.00',
    'text': '(GMT+01:00) West Central Africa',
  },
  {
    'value': '05102+2.00,05032+3.00',
    'text': '(GMT+02:00 +DST) Amman',
  },
  {
    'value': '00112+2.00,00032+3.00,I',
    'text': '(GMT+02:00 +DST) Athens, Bucharest, Istanbul',
  },
  {
    'value': '05091+2.00,05041+3.00',
    'text': '(GMT+02:00 +DST) Cairo',
  },
  {
    'value': '2.00H',
    'text': '(GMT+02:00) Harare, Pretoria',
  },
  {
    'value': '00112+2.00,00032+3.00',
    'text': '(GMT+02:00 +DST) Helsinki, Kyiv, Riga, Tallinn',
  },
  {
    'value': '05102+2.00,05032+3.00',
    'text': '(GMT+02:00 +DST) Jerusalem',
  },
  {
    'value': '10092+2.00,10042+3.00',
    'text': '(GMT+02:00 +DST) Windhoek',
  },
  {
    'value': '3.00K',
    'text': '(GMT+03:00) Kuwait, Riyadh, Baghdad',
  },
  {
    'value': '3.00',
    'text': '(GMT+03:00) Moscow, St. Petersburg, Volgograd',
  },
  {
    'value': '3.50',
    'text': '(GMT+03:30) Tehran',
  },
  {
    'value': '4.00T',
    'text': '(GMT+04:00) Abu Dhabi, Muscat, Tbilisi',
  },
  {
    'value': '4.50',
    'text': '(GMT+04:30) Kabul',
  },
  {
    'value': '5.00',
    'text': '(GMT+05:00) Islamabad, Karachi, Tashkent',
  },
  {
    'value': '5.50C',
    'text': '(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi',
  },
  {
    'value': '6.00',
    'text': '(GMT+06:00) Almaty, Novosibirsk',
  },
  {
    'value': '7.00',
    'text': '(GMT+07:00) Bangkok, Hanoi, Jakarta',
  },
  {
    'value': '7.00K',
    'text': '(GMT+07:00) Krasnoyarsk',
  },
  {
    'value': '8.00',
    'text': '(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi',
  },
  {
    'value': '8.00K',
    'text': '(GMT+08:00) Kuala Lumpur, Singapore',
  },
  {
    'value': '8.00I',
    'text': '(GMT+08:00) Irkutsk, Perth, Taipei, Ulaan Bataar',
  },
  {
    'value': '9.00',
    'text': '(GMT+09:00) Osaka, Sapporo, Seoul, Tokyo, Yakutsk',
  },
  {
    'value': '10102+9.50,10042+10.50',
    'text': '(GMT+09:30) Adelaide',
  },
  {
    'value': '9.50D',
    'text': '(GMT+09:30) Darwin',
  },
  {
    'value': '10.00B',
    'text': '(GMT+10:00) Brisbane',
  },
  {
    'value': '10102+10.00,10042+11.00',
    'text': '(GMT+10:00) Canberra, Hobart, Melbourne, Sydney',
  },
  {
    'value': '10.00V',
    'text': '(GMT+10:00) Guam, Port Moresby, Vladivostok',
  },
  {
    'value': '11.00',
    'text': '(GMT+11:00) Magadan, Solomon Is., New Caledonia',
  },
  {
    'value': '00092+12.00,10042+13.00',
    'text': '(GMT+12:00) Auckland, Wellington',
  },
  {
    'value': '12.0F',
    'text': '(GMT+12:00) Fiji, Kamchatka, Marshall Is.',
  },
];

class ScreenDeviceAlerts extends StatefulWidget {
  static const routeName = '/device/alerts';

  @override
  _ScreenDeviceAlertsState createState() => _ScreenDeviceAlertsState();
}

class _ScreenDeviceAlertsState extends State<ScreenDeviceAlerts> {
  bool _isBusy = true;
  bool _isFirstRun = true;
  bool _mapInit = false;
  String _errorMessage;
  ProviderAccount _account;
  Device _device;
  int _previousTimeoutAlert;
  int _previousNightAlertFrom;
  int _previousNightAlertTo;
  ScrollController _scrollController = ScrollController();

  @override
  void setState(function) {
    if (mounted) {
      super.setState(function);
    }
  }

  // @override
  void didChangeDependencies() {
    if (_isFirstRun) {
      _isFirstRun = false;
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
      Widget content;
      if (_device.connectionStatus != ConnectionStatus.ONLINE) {
        content = ErrorScreen(
          'Device must be online to access alerts. Current status: ${_device.doorStatusString}',
          header: 'Not Connected',
          icon: Icons.signal_wifi_off,
        );
      } else {
        final statusAlerts = _device.getValue('alerts/statusAlert');
        final timeoutAlert = _device.getValue('alerts/timeoutAlert');
        if (timeoutAlert != 0) {
          _previousTimeoutAlert = timeoutAlert;
        }
        final nightAlertFrom = _device.getValue('alerts/nightAlertFrom');
        if (nightAlertFrom != 0) {
          _previousNightAlertFrom = nightAlertFrom;
        }
        final nightAlertTo = _device.getValue('alerts/nightAlertTo');
        if (nightAlertTo != 0) {
          _previousNightAlertTo = nightAlertTo;
        }
        final timeZone = _device.getValue('alerts/timeZone');
        final geoEnabled = _device.getValue('geo/enabled') ?? false;

        content = ListView(
          controller: _scrollController,
          children: <Widget>[
            SettingsHeader(
              'STATUS ALERTS',
              helpLink: LINK_HELP + '-status',
            ),
            _getStatusAlert('Online', statusAlerts, 64),
            _getStatusAlert('Offline', statusAlerts, 128),
            _getStatusAlert('Open', statusAlerts, 8),
            _getStatusAlert('Closed', statusAlerts, 1),
            _getStatusAlert('Stopped', statusAlerts, 16),
            SettingsHeader(
              'TIMEOUT ALERT',
              helpLink: LINK_HELP + '-timeout',
            ),
            SettingsToggle(
              'Enable',
              timeoutAlert != 0,
              (value) {
                _deviceSaveValue(
                    'alerts/timeoutAlert',
                    timeoutAlert == 0
                        ? _previousTimeoutAlert ??
                            VALUES_TIMEOUTALERT[8]['value']
                        : 0);
              },
            ),
            timeoutAlert == 0
                ? SizedBox.shrink()
                : SettingsSelect(
                    'When Door Remains Open',
                    VALUES_TIMEOUTALERT,
                    VALUES_TIMEOUTALERT.firstWhere(
                      (item) => item['value'] == timeoutAlert,
                      orElse: () => VALUES_TIMEOUTALERT[8],
                    ),
                    (value) {
                      return _deviceSaveValue('alerts/timeoutAlert', value);
                    },
                  ),
            SettingsHeader(
              'NIGHT ALERT',
              helpLink: LINK_HELP + '-night',
            ),
            SettingsToggle(
              'Enable',
              nightAlertFrom != nightAlertTo,
              (value) {
                _deviceSaveValue('alerts/nightAlertFrom',
                    value ? _previousNightAlertFrom ?? 1320 : 0);
                _deviceSaveValue('alerts/nightAlertTo',
                    value ? _previousNightAlertTo ?? 360 : 0);
              },
            ),
            nightAlertFrom == nightAlertTo
                ? SizedBox.shrink()
                : SettingsItem(
                    'From',
                    value: _intToString(context, nightAlertFrom),
                    icon: Icons.chevron_right,
                    action: (ctx) {
                      _pickTime(ctx, nightAlertFrom, (value) {
                        _deviceSaveValue(
                            'alerts/nightAlertFrom', _timeToInt(value));
                      });
                    },
                  ),
            nightAlertFrom == nightAlertTo
                ? SizedBox.shrink()
                : SettingsItem(
                    'To',
                    value: _intToString(context, nightAlertTo),
                    icon: Icons.chevron_right,
                    action: (ctx) {
                      _pickTime(ctx, nightAlertTo, (value) {
                        _deviceSaveValue(
                            'alerts/nightAlertTo', _timeToInt(value));
                      });
                    },
                  ),
            nightAlertFrom == nightAlertTo
                ? SizedBox.shrink()
                : SettingsSelect(
                    'Time Zone',
                    VALUES_TIMEZONE,
                    VALUES_TIMEZONE.firstWhere(
                      (item) => item['value'] == timeZone,
                      orElse: () => null,
                    ),
                    (value) {
                      return _deviceSaveValue('alerts/timeZone', value);
                    },
                  ),
            SettingsHeader(
              'DEPARTURE ALERT',
              helpLink: LINK_HELP + '-departure',
            ),
            SettingsToggle(
              'Enable',
              geoEnabled,
              (value) {
                if (value && !_mapInit) {
                  _mapInit = true;
                  showBusyMessage(context, 'Loading Map');
                }
                return _deviceSaveValue('geo/enabled', value);
              },
            ),
            geoEnabled
                ? GeofenceMap(
                    latitude: _device.getValue('geo/latitude'),
                    longitude: _device.getValue('geo/longitude'),
                    radius: _device.getValue('geo/radius'),
                    onChange: (latitude, longitude, radius) {
                      if (_mapInit) {
                        _mapInit = false;
                        Navigator.of(context).pop();
                        return _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                        );
                      }
                      _device.setValue('geo/latitude', latitude);
                      _device.setValue('geo/longitude', longitude);
                      _device.setValue('geo/radius', radius);
                      _account.initGeofence();
                      return _deviceSaveValue('geo/enabled', true);
                    },
                    onError: (error) {
                      _mapInit = false;
                      Navigator.of(context).pop();
                      showErrorDialog(
                          context, 'Location Services Error', error.toString());
                      _deviceSaveValue('geo/enabled', false);
                      setState(() {});
                    },
                  )
                : SizedBox.shrink(),
          ],
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('Alerts'),
        ),
        bottomNavigationBar: BottomNavigation(2),
        body: content,
      );
    }
  }

  Widget _getStatusAlert(String status, int allAlerts, int thisAlert) {
    return SettingsToggle(
      status,
      (allAlerts & thisAlert) != 0,
      (value) {
        _deviceSaveValue('alerts/statusAlert', allAlerts ^ thisAlert);
      },
    );
  }

  Future<bool> _deviceSaveValue(String key, dynamic value) {
    final oldValue = _device.getValue(key);
    return localAuthChallageDialog(context, AuthLevel.ACTIONS).then((allowed) {
      if (!allowed) {
        return false;
      }
      _device.setValue(key, value);
      return _device.saveConfig();
    }).then((_) {
      return Future.wait([
        _account.storeDevices(),
        _account.subscribeToNotifications(),
      ]);
    }).catchError((error) {
      _errorMessage = error.toString();
      print('Error: $_errorMessage');
      _device.setValue(key, oldValue);
    }).whenComplete(() {
      setState(() {});
    }).then((_) {
      return true;
    });
  }

  void _pickTime(BuildContext context, int value, void onSelect(int)) {
    DateTime time;
    final format24h = MediaQuery.of(context).alwaysUse24HourFormat;

    final timePicker = TimePickerSpinner(
      time: _intToTime(value),
      is24HourMode: format24h,
      normalTextStyle: Theme.of(context).textTheme.body2,
      highlightedTextStyle: Theme.of(context)
          .textTheme
          .title
          .copyWith(fontWeight: FontWeight.bold),
//        spacing: 50,
      itemHeight: 40,
      isForce2Digits: true,
      onTimeChange: (newTime) {
        time = newTime;
      },
    );

    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Select Time'),
            content: timePicker,
            actions: <Widget>[
              RaisedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
              ),
              RaisedButton(
                child: const Text('Select'),
                onPressed: () {
                  onSelect(time);
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          );
        });
  }

  int _timeToInt(DateTime value) {
    return value.hour * 60 + value.minute;
  }

  DateTime _intToTime(int value) {
    var time = DateTime.now();
    return DateTime(
      time.year,
      time.month,
      time.day,
      (value / 60).floor(),
      (value % 60),
    );
  }

  String _timeToString(BuildContext context, DateTime value) {
    final format24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final minutes = ':' + value.minute.toString().padLeft(2, '0');
    if (format24h) {
      return value.hour.toString().padLeft(2, '0') + minutes;
    } else if (value.hour > 12) {
      return (value.hour - 12).toString() + minutes + ' PM';
    } else if (value.hour == 0) {
      return '12' + minutes + ' AM';
    } else {
      return value.hour.toString() + minutes + ' AM';
    }
  }

  String _intToString(BuildContext context, int value) {
    return _timeToString(context, _intToTime(value));
  }
}
