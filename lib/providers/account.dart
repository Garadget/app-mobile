import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/device.dart';
import '../models/particle.dart' as particle;
import './device_status.dart';
import './device_info.dart';

const STKEY_SELECTEDID = 'selectedDeviceId';
const STKEY_DEVICES = 'devices';
const STKEY_ACCEMAIL = 'accountEmail';
const STKEY_AUTHTOKEN = 'authToken';
const STKEY_AUTHLEVEL = 'authLevel';
const STKEY_AUTHMETHOD = 'authMethod';
const STKEY_PINCODE = 'pinCode';
const URL_PASSWORDRESET = 'https://garadget.com/my/json/password-reset.php';
const URL_PUSHSUBSCRIBE = 'https://www.garadget.com/my/json/pn-signup.php';

enum AuthLevel {
  ALWAYS,
  ACTIONS,
  NEVER,
}

enum AuthMethod {
  PINCODE,
  TOUCHID,
  FACEID,
}

class ProviderAccount with ChangeNotifier {
  final _particleAccount = particle.Account();
  final _providerDeviceStatus = ProviderDeviceStatus();
  final _providerDeviceInfo = ProviderDeviceInfo();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  List<Device> _devices = [];
  SharedPreferences _storage;
  Timer _refreshTimer;
  String _selectedDeviceId;
  bool _isUpdatingStatus = false;
  bool _isUpdatingDevices = false;
  bool _updateErrors = false;
  bool _localAuth = true; // request local re-auth

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
      _updateErrors = false;
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
      return _providerDeviceStatus.update();
    });
  }

  Future<bool> signup(String username, String password) {
    return _particleAccount.signup(username, password).then((result) {
      _storage.setString(STKEY_ACCEMAIL, username);
      _storage.setString(STKEY_AUTHTOKEN, _particleAccount.token);
      _localAuth = false;
      return result;
    });
  }

  Future<bool> login(String username, String password) {
    return _particleAccount.login(username, password).then((result) {
      _storage.setString(STKEY_ACCEMAIL, username);
      _storage.setString(STKEY_AUTHTOKEN, _particleAccount.token);
      _localAuth = false;
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
      return await loadDevices(true);
    }
    final devices = json.decode(devicesCache);
    final List<Device> loadedDevices = [];
    devices.forEach((cache) {
      loadedDevices.add(Device.rehydrate(_particleAccount, cache));
    });
    _devices = loadedDevices;
    print('loaded: ${_devices.length}');
    await updateSelection(null);
    notifyListeners();
    requestNotifications();
    return true;
  }

  Future<bool> loadDevices(bool timer) async {
    print('reloading...');
    if (_isUpdatingDevices) {
      throw ('collision');
    }
    _isUpdatingDevices = true;
    stopTimer();

    // get device list from Particle
    try {
      List<particle.Device> devices = await _particleAccount.getDevices();
      print('list loaded: ${devices.length}');
      if (devices.length > 0) {
        _devices =
            devices.map((particleDevice) => Device(particleDevice)).toList();
        loadConfig(); // no await
      }
      await updateSelection(null);
      notifyListeners();
    } finally {
      _isUpdatingDevices = false;
    }
    if (timer) {
      startTimer();
    }
    return true;
  }

  Future<void> storeDevices() {
    final devicesData =
        json.encode(_devices.map((device) => device.persistentData).toList());
    return _storage.setString(STKEY_DEVICES, devicesData);
  }

  Future<void> loadStatus() async {
    if (_isUpdatingStatus) {
      return;
    }
    _isUpdatingStatus = true;
    bool stausUpdated = false;
    bool updateErrors = false;
    try {
      await Future.wait(
        _devices.map((device) async {
          try {
            final deviceStatusUpdated = await device.loadStatus();
            if (deviceStatusUpdated) {
              stausUpdated = true;
            }
          } catch (error) {
            if (error.toString() != 'timeout' && error.toString() != 'offline') {
              // flag account level request errors
              updateErrors = true;
            }
            stausUpdated = true;
          }
        }).toList(),
      );
    } finally {
      if (stausUpdated || updateErrors != _updateErrors) {
        _updateErrors = updateErrors;
        providerDeviceStatus.update();
      }
      else {
        _providerDeviceInfo.update();
      }
      _isUpdatingStatus = false;
    }
  }

  Future<bool> loadConfig() {
    return Future.wait(_devices.map(
      (device) => device.loadConfig().then((result) {
        return result;
      }).catchError((error) {
        print('device: ${device.id} error: ${error.toString()}');
        return true;
      }).whenComplete(() {
        _providerDeviceStatus.update();
      }),
    )).then((results) {
      return results.reduce((value, element) => value || element);
    }).whenComplete(() {
      print('stored devices');
      storeDevices();
      requestNotifications();
    });
  }

  getDeviceById(String id) {
    return devices.firstWhere((device) {
      return device.id == id;
    }, orElse: () => null);
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
    _providerDeviceStatus.update();
    if (commandString != null) {
      device.commandRemote(commandString).then((result) {
        // @todo: handle command failures (SnackBar widget?)
        _providerDeviceStatus.update();
      });
    }
  }

  bool get isUsingNotifications {
    return _devices.fold(false, (value, element) => value || element.isUsingNotifications);
  }

  Future<bool> requestNotifications() async {

    bool allowed = await _firebaseMessaging.requestNotificationPermissions();
    final token = await _firebaseMessaging.getToken();

    final Map postData = {
      'platform': 'fcm',
      'subscriber': token,
      'user': accountEmail,
      'authtoken': _particleAccount.token
    };
    if (!isUsingNotifications || (allowed != null && !allowed)) {
      postData['action'] = 'remove';
      print('notifications not used');
      return true;
    }
    else {
      postData['action'] = 'add';
      postData['device'] = _devices.map((device) => device.id).join(',');
    }
    print('data: ${postData.toString()}');

    try {
      await http.post(
        URL_PUSHSUBSCRIBE,
        headers: null,
        body: postData,
      ).then((response) {
        print('response: ${response.body}');
        final responseMap = json.decode(response.body);
        if (responseMap['error'] != null) {
          throw (responseMap['error']);
        }
      });
    }
    catch(error) {
      print('Error: ${error.toString()}');
    }
    return true;
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

  get providerDeviceStatus {
    return _providerDeviceStatus;
  }

  get providerDeviceInfo {
    return _providerDeviceInfo;
  }

  String get selectedDeviceId {
    return _selectedDeviceId;
  }

  bool get updateErrors {
    return _updateErrors;
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

  AuthLevel get authLevel {
    final value = _storage.getString(STKEY_AUTHLEVEL);
    switch (value) {
      case 'always':
        return AuthLevel.ALWAYS;
      case 'actions':
        return AuthLevel.ACTIONS;
      case 'never':
      default:
        return AuthLevel.NEVER;
    }
  }

  Future<bool> setAuthLevel(AuthLevel value) {
    String stringValue;
    switch (value) {
      case AuthLevel.ALWAYS:
        stringValue = 'always';
        break;
      case AuthLevel.ACTIONS:
        stringValue = 'actions';
        break;
      case AuthLevel.NEVER:
      default:
        return _storage.remove(STKEY_AUTHLEVEL);
    }
    return _storage.setString(STKEY_AUTHLEVEL, stringValue);
  }

  void requireLocalAuth() {
    _localAuth = true;
  }

  void fulfillLocalAuth() {
    _localAuth = false;
  }

  AuthMethod isLocalAuthNeeded(AuthLevel level) {
    if (_localAuth && (authLevel == AuthLevel.ALWAYS || authLevel == level)) {
      return authMethod;
    }
    return null;
  }

  AuthMethod get authMethod {
    final value = _storage.getString(STKEY_AUTHMETHOD);
    switch (value) {
      case 'pincode':
        return AuthMethod.PINCODE;
      case 'faceid':
        return AuthMethod.FACEID;
      case 'touchid':
        return AuthMethod.TOUCHID;
      default:
        return null;
    }
  }

  Future<bool> setAuthMethod(AuthMethod value) {
    String stringValue;
    switch (value) {
      case AuthMethod.PINCODE:
        stringValue = 'pincode';
        break;
      case AuthMethod.FACEID:
        stringValue = 'faceid';
        break;
      case AuthMethod.TOUCHID:
        stringValue = 'touchid';
        break;
      default:
        return _storage.remove(STKEY_AUTHMETHOD);
    }
    return _storage.setString(STKEY_AUTHMETHOD, stringValue);
  }

  Future<bool> setPinCode(String value) {
    if (value == null || value.isEmpty) {
      return _storage.remove(STKEY_PINCODE);
    }
    return _storage.setString(STKEY_PINCODE, value);
  }

  bool isPinCodeCorrect(String value) {
    return value == _storage.getString(STKEY_PINCODE);
  }

  List<Device> get devices {
    // @todo: sort by sort order
    return [..._devices];
  }
}
