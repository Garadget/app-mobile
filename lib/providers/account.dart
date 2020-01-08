import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/device.dart';
import '../models/particle.dart' as particle;
import './status.dart';

const STKEY_SELECTEDID = 'selectedDeviceId';
const STKEY_DEVICES = 'devices';
const STKEY_ACCEMAIL = 'accountEmail';
const STKEY_AUTHTOKEN = 'authToken';
const URL_PASSWORDRESET = 'https://garadget.com/my/json/password-reset.php';

class ProviderAccount with ChangeNotifier {
  // properties
  final particle.Account _particleAccount = particle.Account();
  final ProviderStatus _providerStatus = ProviderStatus();
  List<Device> _devices = [];
  SharedPreferences _storage;
  Timer _refreshTimer;
  String _selectedDeviceId;

  Future<bool> init() async {
    stopTimer();
    await initStorage();
    String authToken = _storage.getString(STKEY_AUTHTOKEN);
    if (authToken == null) {
      return false;
    }
    _particleAccount.token = authToken;
    return loadDevicesCached();
  }

  Future<void> initStorage() {
    if (_storage != null) {
      return Future.value();
    }
    return SharedPreferences.getInstance().then((storage) {
      _storage = storage;
    });
  }

  void stopTimer() {
    if (_refreshTimer != null && _refreshTimer.isActive) {
      _refreshTimer.cancel();
    }
  }

  void startTimer() {
    if (_refreshTimer != null && _refreshTimer.isActive) {
      return;
    }

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      loadStatus();
    });
  }

  Future<void> updateSelection(String deviceId) async {
    String savedId = _storage.getString(STKEY_SELECTEDID);
    print('loaded selection: $savedId');

    // no devices - no selection
    if (_devices.length == 0) {
      deviceId = null;
    } else {
      // use saved if none supplied
      if (deviceId == null) {
        deviceId = savedId;
      }

      // test if device with supplied id exists
      if (deviceId != null && getDeviceById(deviceId) == null) {
        deviceId = null;
      }
      if (deviceId == null) {
        deviceId = _devices[0].id;
      }
    }

    _selectedDeviceId = deviceId;
    if (deviceId == savedId) {
      return;
    }

    if (deviceId == null) {
      await _storage.remove(STKEY_SELECTEDID);
    }
    await _storage.setString(STKEY_SELECTEDID, deviceId);
  }

  //Device activeDevice = null;
  Future<void> deviceSelectByOrder(deviceOrder) {
    return updateSelection(getDeviceByOrder(deviceOrder).id).then((_) {
      print('device selected: $deviceOrder');
      return _providerStatus.update();
    });
  }

  Future<bool> signup(String username, String password) {
    return _particleAccount.signup(username, password).then((result) {
      _storage.setString(STKEY_ACCEMAIL, username);
      _storage.setString(STKEY_AUTHTOKEN, _particleAccount.token);
      return result;
    });
  }

  Future<bool> login(String username, String password) {
    return _particleAccount.login(username, password).then((result) {
      _storage.setString(STKEY_ACCEMAIL, username);
      _storage.setString(STKEY_AUTHTOKEN, _particleAccount.token);
      return result;
    });
  }

  Future<bool> logout() {
    stopTimer();
    return _particleAccount.logout().then((result) {
      _storage.remove(STKEY_SELECTEDID);
      _storage.remove(STKEY_DEVICES);
      _storage.remove(STKEY_AUTHTOKEN);
      return result;
    });
  }

  Future<bool> resetPassword(String email) {
    return http.post(
      URL_PASSWORDRESET,
      headers: null,
      body: {'action': 'init', 'email': email},
    ).then((response) {
      final responseMap = json.decode(response.body);
      if (responseMap['error'] != null) {
        throw (responseMap['error']);
      }
      return true;
    });
  }

  Future<String> getClaimCode() {
    return _particleAccount.getClaimCode().then((claimCode) {
      return claimCode;
    });
  }

  void clearDeviceCache() {
    _storage.remove(STKEY_DEVICES);    
  }

  Future<bool> loadDevicesCached() async {

    // load device list from cache
    stopTimer();
    final devicesCache = _storage.getString(STKEY_DEVICES);
    if (devicesCache == null) {
      print('cache is empty - hard reload');
      return await loadDevices();
    }

    final devices = json.decode(devicesCache);
    final List<Device> loadedDevices = [];
    devices.forEach((cache) {
      loadedDevices.add(Device.rehydrate(_particleAccount, cache));
    });
    _devices = loadedDevices;
    print('loaded: ${_devices.length}');
    await updateSelection(null);
    startTimer();
    return true;
  }

  Future<bool> loadDevices() async {
    print('reloading...');
    stopTimer();

    // get device list from Particle
    List<particle.Device> devices = await _particleAccount.getDevices();
    print('list loaded: ${devices.length}');
    if (devices.length > 0) {
      _devices =
          devices.map((particleDevice) => Device(particleDevice)).toList();
      loadConfig(); // no await
    }
    await updateSelection(null);
    startTimer();
    return true;
  }

  Future<void> storeDevices() {
    final devicesData =
        json.encode(_devices.map((device) => device.persistentData).toList());
    return _storage.setString(STKEY_DEVICES, devicesData);
  }

  Future<void> loadStatus() {
    print('.');
    return Future.wait(
      _devices.map((device) {
        return device.loadStatus().then((statusUpdated) {
          if (statusUpdated) {
            notifyListeners();
          }
        }).catchError((error) {
          notifyListeners();
          print('error: ${error.toString()}');
        }).whenComplete(() {
          _providerStatus.update();
        });
      }).toList(),
    );
  }

  Future<bool> loadConfig() {
    return Future.wait(_devices.map(
      (device) => device.loadConfig().then((result) {
        return result;
      }).catchError((error) {
        print('device: ${device.id} error: ${error.toString()}');
        return true;
      }).whenComplete(() {
        notifyListeners();
      }),
    )).then((results) {
      return results.reduce((value, element) => value || element);
    }).whenComplete(() {
      print('stored devices');
      storeDevices();
    });
  }

  getDeviceById(String id) {
    return devices.firstWhere((device) {
      return device.id == id;
    });
  }

  getDeviceByOrder(int order) {
    return devices[order];
  }

  Device addDevice(String deviceId) {
    final particleDevice = particle.Device(this._particleAccount, deviceId);
    final appDevice = Device(particleDevice);
    _devices.add(appDevice);
    return appDevice;
  }

  deviceCommand(String deviceId, DoorCommands command) {
    final device = getDeviceById(_selectedDeviceId);
    final commandString = device.commandLocal(command);
    notifyListeners();
    if (commandString != null) {
      device.commandRemote(commandString).then((result) {
        // @todo: handle command failures (SnackBar widget?)
        notifyListeners();
      });
    }
  }

  static String wifiSignalToString(int wifiSignal) {
    if (wifiSignal == null) {
      return '-';
    }

    String wiFiSingalDescr;
    if (wifiSignal < -85) {
      wiFiSingalDescr = 'weak';
    }
    if (wifiSignal < -70) {
      wiFiSingalDescr = 'fair';
    } else if (wifiSignal < -60) {
      wiFiSingalDescr = 'good';
    } else {
      wiFiSingalDescr = 'excellent';
    }
    return '${wifiSignal}dB ($wiFiSingalDescr)';
  }

  static String platformString(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.android:
        return 'Android';
      default:
        return 'Mobile';
    }
  }

  get providerStatus {
    return _providerStatus;
  }

  String get selectedDeviceId {
    return _selectedDeviceId;
  }

  int get selectedDeviceOrder {
    return _devices.indexWhere((device) => device.id == _selectedDeviceId);
  }

  Device get selectedDevice {
    return getDeviceById(_selectedDeviceId);
  }

  bool get isAuthenticated {
    return _particleAccount.isAuthenticated;
  }

  String get accountEmail {
    return _storage.getString(STKEY_ACCEMAIL);
  }

  List<Device> get devices {
    // @todo: sort by sort order
    return [..._devices];
  }
}
