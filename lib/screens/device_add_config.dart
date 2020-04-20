import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:particle_setup/particle_setup.dart';
import 'package:pointycastle/asymmetric/api.dart';

import '../widgets/error_message.dart';
import '../widgets/busy_message.dart';
import '../misc/input_decoration.dart';
import '../providers/account.dart';
import './home.dart';
import './device_add_confirm.dart';
import './account_signin.dart';

const SSIDPREFIX = 'Photon';

class ScreenDeviceAddConfig extends StatefulWidget {
  static const routeName = '/device/add/config';

  @override
  _ScreenDeviceAddConfigState createState() => _ScreenDeviceAddConfigState();
}

class _ScreenDeviceAddConfigState extends State<ScreenDeviceAddConfig> {
  final _particleSetup = ParticleSetup();
  String _deviceId;
  RSAPublicKey _publicKey;
  ScanAPResponse _scanResult;

  bool _isFirstRun = true;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isScanning = false;
  bool _isComplete = false;
  bool _isPasswordObscured = true;
  String _errorMessage;
  ProviderAccount _account;
  int _localNotificationId;

  String _claimCode;
  String _password;
  Scan _selectedAp;
  final _formKey = GlobalKey<FormState>();

  @override
  void setState(function) {
    if (mounted) {
      super.setState(function);
    }
  }

  @override
  void didChangeDependencies() {
    if (_isFirstRun) {
      _isFirstRun = false;
      _localNotificationId = null;
      _claimCode = ModalRoute.of(context).settings.arguments as String;
      _account = Provider.of<ProviderAccount>(context, listen: false);
      _account.initStorage();
      _testConnection();
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return ErrorScreen(_errorMessage);
    } else {
      final platform = ProviderAccount.platformString(context);
      List<Widget> tiles = [];
      if (!_isConnected) {
        tiles.add(ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Connect to Garadget'),
          subtitle: Text(
              'In WiFi settings of this $platform device connect to the access point with prefix \'$SSIDPREFIX\' then return to this app.'),
        ));
      } else {
        tiles.add(ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: const Text('Connected to Garadget'),
          subtitle: Text('ID: $_deviceId\nEncryption key received.'),
        ));

        bool noScanResults =
            _scanResult == null || _scanResult.scans.length == 0;
        if (_selectedAp != null) {
          tiles.add(ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('WiFi Router Selected'),
            subtitle: Text(
                'Garadget will be using ${_selectedAp.ssid} WiFi access point.'),
            trailing: IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  _selectedAp = null;
                  _scanAps();
                }),
          ));
          if (_selectedAp.wifiSecurityType != WifiSecurity.OPEN) {
            tiles.add(ListTile(
              leading: const Icon(Icons.security),
              title: Text('Enter WiFi Password'),
              subtitle: Text('Specify password for ${_selectedAp.ssid}'),
            ));
            tiles.add(
              Form(
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
                        obscureText: _isPasswordObscured,
                        onFieldSubmitted: (_) {
                          _handleConnect();
                        },
                        decoration: InputTheme.of(context).copyWith(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
//               color: Theme.of(context).primaryColorDark,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 8) {
                            return 'Password is too short';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _password = value;
                          setState(() {
                            _isComplete = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 45,
                    ),
                  ],
                ),
              ),
            );
          }
        } else if (_isScanning && noScanResults) {
          tiles.add(const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Scanning WiFi'),
            subtitle: Text('Garadget scans WiFi access points...'),
          ));
        } else if (!_isScanning && noScanResults) {
          tiles.add(ListTile(
            leading: Icon(Icons.error_outline),
            title: Text('No WiFi Access Points Found'),
            subtitle: Text(
                'Garadget couldn\'t detect any WiFi networks. Make sure your WiFi router is on and supports 2.4GHz band.'),
          ));
        } else {
          tiles.add(ListTile(
            leading: _isScanning
                ? const CircularProgressIndicator()
                : const Icon(Icons.wifi),
            title: const Text('Select WiFi Connection'),
            subtitle: Text('Select the access point for Garadget to connect.'),
            trailing: IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _scanAps,
            ),
          ));
          _scanResult.scans.sort((value1, value2) {
            return value2.rssi - value1.rssi;
          });
          List<Widget> wifiEntries = [];
          _scanResult.scans.forEach((item) {
            wifiEntries.add(WifiEntry(
              item,
              _selectedAp,
              (ap) {
                setState(() {
                  _selectedAp = ap;
                  if (ap.wifiSecurityType == WifiSecurity.OPEN) {
                    _isComplete = true;
                  }
                  if (_localNotificationId != null) {
                    _account.localNotificationRemove(_localNotificationId);
                  }
                });
              },
            ));
          });
          tiles.add(
            Column(
              children: wifiEntries,
            ),
          );
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('WiFi Connection'),
        ),
        bottomNavigationBar: Padding(
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
                        if (_isComplete) {
                          _account.deviceSelectById(_deviceId);
                        }
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          ScreenHome.routeName,
                          (route) => route.isFirst,
                        );
                      },
                    ),
              RaisedButton(
                child: const Text('Connect'),
                onPressed: _isConnected && _isComplete ? _handleConnect : null,
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: tiles,
        ),
      );
    }
  }

  void _handleConnect() async {
    if (!_formKey.currentState.validate() || !_isConnected || !_isComplete) {
      return;
    }
    try {
      await showBusyMessage(context, 'Submitting...');
      final setResponse = await _particleSetup
          .setClaimCode(
            _claimCode,
          )
          .timeout(const Duration(seconds: 5),
              onTimeout: () => throw ('Claim Code Timeout'));
      if (!setResponse.isOk()) {
        throw ('Error setting claim code');
      }
      final configResponse = await _particleSetup
          .configureAP(
            _selectedAp,
            _password,
            _publicKey,
          )
          .timeout(const Duration(seconds: 10),
              onTimeout: () => throw ('AP Config Timeout'));
      if (!configResponse.isOk()) {
        throw ('Error submitting connection info');
      }
      final connectResponse = await _particleSetup.connectAP().timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw ('AP Connect Timeout'));
      if (!connectResponse.isOk()) {
        throw ('Error sending connect command');
      }
      DeviceIdResponse deviceIdResponse;
      try {
        deviceIdResponse =
            await _particleSetup.getDeviceId().timeout(Duration(seconds: 5));
      } catch (_) {
        // this must fail
      }
      if (deviceIdResponse != null && deviceIdResponse.isOk()) {
        throw ('Did not disconnect $SSIDPREFIX');
      }
      Navigator.of(context).pop();
      Navigator.of(context)
          .pushNamed(
        ScreenDeviceAddConfirm.routeName,
        arguments: _deviceId,
      )
          .then((_) {
        _testConnection();
      });
    } catch (error) {
      Navigator.of(context).pop();
      showErrorDialog(context, 'Communication Error',
              'Reset Garadget by unplugging it from power and plugging it back so we can try again.\n\nDetails: ${error.toString()}')
          .then((_) {
        _scanResult = null;
        _testConnection();
      });
    }
  }

  void _testConnection() async {
    while (true) {
      if (!mounted || _isConnecting) {
        return;
      }
      // pause ping while scanning APs
      if (_isScanning) {
        await Future.delayed(Duration(milliseconds: 200));
        continue;
      }
      _isConnecting = true;
      try {
//        print('ping');
        final deviceId = await _particleSetup
            .getDeviceId()
            .timeout(Duration(seconds: 1), onTimeout: () {
          throw ('timeout');
        });
        if (deviceId.isOk()) {
          _deviceId = deviceId.deviceIdHex;
        } else {
          throw ('Error getting device ID');
        }
        if (_publicKey == null) {
          final publicKey = await _particleSetup.getPublicKey();
          if (publicKey.isOk()) {
            _publicKey = publicKey.publicKey;
          } else {
            throw ('Error getting public key');
          }
        }
        // print('pong');
        if (!_account.isAppActive && _localNotificationId == null) {
          _localNotificationId = await _account.localNotificationShow(
            'Return to Garadget App',
            'Click here to continue device setup',
          );
        }
        setState(() {
          _isConnected = true;
        });
      } catch (error) {
        setState(() {
          _isConnected = false;
        });
      }
      if (_scanResult == null) {
        await _scanAps();
      }
      if (_isConnected && _scanResult != null) {
        _isConnecting = false;
        return;
      }
      await Future.delayed(Duration(seconds: 1));
      _isConnecting = false;
    }
  }

  Future<void> _scanAps() async {
    if (!mounted || !_isConnected || _isScanning) {
      return;
    }
    setState(() {
      _isScanning = true;
      _isComplete = false;
    });
    try {
      _scanResult = await _particleSetup.scanAP();
      if (_selectedAp != null) {
        // remove selected ap if not found in new scan
        if (_scanResult.scans
                .indexWhere((item) => item.ssid == _selectedAp.ssid) <
            0) {
          _selectedAp = null;
        }
      }
    } catch (error) {
      print(error);
      _isConnected = false;
      if (!_isConnecting) {
        _testConnection();
      }
    }
    setState(() {
      _isScanning = false;
    });
  }
}

class WifiEntry extends StatelessWidget {
  final Scan entry;
  final Scan selected;
  final Function onChanged;

  WifiEntry(this.entry, this.selected, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(entry);
      },
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          const SizedBox(
            width: 60,
          ),
          Radio(
            value: entry.ssid,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            groupValue: selected != null ? selected.ssid : null,
            onChanged: (_) {
              onChanged(entry);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.ssid,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
                Text(
                  entry.wifiSecurityType.toString() +
                      ', ' +
                      entry.wifiSignalStrength.toString(),
                  style: Theme.of(context).textTheme.body2,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
    );
  }
}
