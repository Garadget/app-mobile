import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/device.dart';
import '../models/particle.dart' as particle;
import './device_status.dart';
import './device_info.dart';

const STKEY_SELECTEDID = 'selectedDeviceId';
const STKEY_DEVICES = 'devices';
const STKEY_LOCATION = 'location';
const STKEY_ACCEMAIL = 'accountEmail';
const STKEY_AUTHTOKEN = 'authToken';
const STKEY_AUTHLEVEL = 'authLevel';
const STKEY_AUTHMETHOD = 'authMethod';
const STKEY_PINCODE = 'pinCode';
const PORT_GEOFENCE = 'garadget-geofence';
const URL_PASSWORDRESET = 'https://garadget.com/my/json/password-reset.php';
const URL_PUSHSUBSCRIBE = 'https://www.garadget.com/my/json/pn-signup.php';
const AUTH_TIMEOUT = 2000; // milliseconds between local auth challenges

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
  final _firebaseMessaging = FirebaseMessaging();
  final _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription _locationUpdates;

  List<Device> _devices = [];
  SharedPreferences _storage;
  Timer _refreshTimer;
  String _selectedDeviceId;
  bool _isUpdatingStatus = false;
  bool _isUpdatingDevices = true;
  bool _isGeofenceReady = false;
  bool _isNotificationReady = false;
  List<String> _initErrors = [];
  List<String> _updateErrors = [];
  bool isInLocalAuth = false;
  bool _localAuth = true; // request local re-auth
  int authTime;
  bool isAppActive = true;

  Future<bool> init() async {
    _initNotifications();
    await initStorage();

    String authToken = _storage.getString(STKEY_AUTHTOKEN);
    if (authToken == null) {
      return false;
    }
    _particleAccount.token = authToken;
    return loadDevicesCached();
  }

  void _initMessaging() {
    _firebaseMessaging.configure(
//      onMessage: (Map<String, dynamic> message) async {
//        print("onMessage: $message");
//      },
      onResume: (Map<String, dynamic> message) async {
        final deviceId = message['data']['device'];
        await updateSelection(deviceId);
        return notifyListeners();
      },
    );
  }

  Future<void> initGeofence() async {
    print('init geofence');
    if (!isUsingLocation) {
      if (_locationUpdates != null) {
        print('turning off location');
        await _locationUpdates?.cancel();
        _locationUpdates = null;
        _isGeofenceReady = false;
//        await GeofencingManager.demoteToBackground();
      }
      return;
    }

    try {
      await Geolocator().getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        locationPermissionLevel: GeolocationPermission.locationAlways,
      );
    } on PlatformException catch (error) {
      _initErrors.add(
          'The app was unable to access the location used for departure alert.\nSet Location access for Garadget to \'Always\'.\n\nSystem Response: ${error.message}');
      return;
    }

    try {
      if (!_isGeofenceReady) {
        _locationUpdates =
            Geolocator().getPositionStream().listen(_handleLocationUpdate);
        _isGeofenceReady = true;
      }
    } catch (error) {
      _initErrors.add('Error Initializing Geofencing: ${error.toString()}');
    }
  }

  Future<void> _handleLocationUpdate(Position location) {
//    print('location update: ${location.latitude}, ${location.longitude}');
    final List<String> statusList = [];
    String firstId;
    return Future.wait(_devices.map((device) async {
      final geoStatus = await device.getGeoStatus(
        location.latitude,
        location.longitude,
      );
//z      print('geo status: $geoStatus');
      if (geoStatus != GeofenceStatus.EXIT || isAppActive) {
        return Future.value();
      }
      try {
        await device.loadStatus();
        print('exited, door status: ${device.doorStatus}');
        if (device.doorStatus != DoorStatus.CLOSED &&
            device.doorStatus != DoorStatus.CLOSING) {
          statusList.add(device.name + ' remains ' + device.doorStatusString);
        }
      } catch (error) {
        statusList.add(device.name + ' did not responding');
      } finally {
        if (firstId == null) {
          firstId = device.id;
        }
      }
    }).toList())
        .then((_) {
      if (statusList.isEmpty) {
        return;
      }
      String statusString = statusList.removeLast();
      if (statusList.isNotEmpty) {
        statusString = statusList.join(', ') + ' and ' + statusString;
      }
      print('notifying');
      localNotificationShow(
        'Departure Alert',
        '$statusString',
        payload: firstId,
      );
    });
  }

  void _initNotifications() {
    if (_isNotificationReady) {
      return;
    }
    var androidSettings =
        new AndroidInitializationSettings('notification_icon');
    var iOsSettings = IOSInitializationSettings(
      onDidReceiveLocalNotification: _onReceivedNotification,
    );
    final settings = InitializationSettings(androidSettings, iOsSettings);
    try {
      _localNotifications.initialize(
        settings,
        onSelectNotification: _onSelectNotification,
      );
    } catch (error) {
      _initErrors.add('Error Initializing Local Notifications');
    }
    _isNotificationReady = true;
  }

  Future<dynamic> _onReceivedNotification(
    int id,
    String title,
    String body,
    String payload,
  ) {
    print('iOS notification: $title / $body');
    return Future.value();
  }

  Future<dynamic> _onSelectNotification(String payload) async {
    print('select notification');
    if (payload != null) {
      await updateSelection(payload);
      return notifyListeners();
    }
  }

  Future<int> localNotificationShow(
    String title,
    String body, {
    int id,
    String payload,
  }) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'garadget-notifications',
      'Garadget Notifications',
      'Garadget Notifications',
      importance: Importance.Max,
      priority: Priority.High,
      ticker: 'ticker',
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    if (id == null) {
      id = DateTime.now().microsecondsSinceEpoch % 0x7FFFFFFF;
    }
    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
    return id;
  }

  Future<void> localNotificationRemove(int id) async {
    await _localNotifications.cancel(id);
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
    print('stopping timer');
    if (_refreshTimer != null && _refreshTimer.isActive) {
      _refreshTimer.cancel();
      _updateErrors = [];
    }
  }

  void startTimer() {
    print('starting timer');
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
    final deviceId = getDeviceByOrder(deviceOrder).id;
    return deviceSelectById(deviceId);
  }

  Future<void> deviceSelectById(deviceId) {
    if (deviceId == _selectedDeviceId) {
      return Future.value();
    }
    return updateSelection(deviceId).then((_) {
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
    return _particleAccount.logout().then((result) {
      _storage.remove(STKEY_SELECTEDID);
      clearDeviceCache();
      _storage.remove(STKEY_AUTHTOKEN);
      stopTimer();
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
    _isUpdatingDevices = true;
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
    await _onDevicesLoaded();
    await _onAccountLoaded();
    return true;
  }

  Future<bool> loadDevices() async {
    _isUpdatingDevices = true;

    // get device list from Particle
    try {
      List<particle.Device> devices = await _particleAccount.getDevices();
      if (devices.length > 0) {
        _devices =
            devices.map((particleDevice) => Device(particleDevice)).toList();
        loadConfig().then((_) {
          _onAccountLoaded();
        }); // no await
      }
    } finally {
      await _onDevicesLoaded();
    }
    return true;
  }

  void _appendLocationData() {
    final config = _storage.getString(STKEY_LOCATION);
    if (config == null) {
      return;
    }
    final Map<String, dynamic> locationData = json.decode(config);
    _devices.forEach((device) {
      if (locationData[device.id] != null) {
        device.locationData = locationData[device.id];
      }
    });
  }

  Future<void> _onDevicesLoaded() async {
    print('devices loaded: ${_devices.length}');
    _appendLocationData();
    await updateSelection(null);
    _isUpdatingDevices = false;
    notifyListeners();
  }

  Future<void> _onAccountLoaded() async {
    print('account loaded');
    subscribeToNotifications();
    _initMessaging();
    initGeofence();
  }

  Future<void> storeDevices() async {
    final devicesData =
        json.encode(_devices.map((device) => device.persistentData).toList());
    await _storage.setString(STKEY_DEVICES, devicesData);
    final Map<String, dynamic> locationData = {};
    _devices.forEach((device) {
      final deviceLocation = device.locationData;
      if (deviceLocation != null && deviceLocation['enabled']) {
        locationData[device.id] = deviceLocation;
      }
    });
    await _storage.setString(STKEY_LOCATION, json.encode(locationData));
//    print('stored devices');
  }

  Future<void> loadStatus() async {
    if (_isUpdatingStatus) {
      return;
    }
    _isUpdatingStatus = true;
    bool stausUpdated = false;
    List<String> updateErrors = [];
    try {
      await Future.wait(
        _devices.map((device) async {
          try {
            final deviceStatusUpdated = await device.loadStatus();
            if (deviceStatusUpdated) {
              stausUpdated = true;
            }
          } catch (exception) {
            final error = exception.toString();
            if (error != 'timeout' && error != 'offline' && _refreshTimer.isActive) {
              // flag account level request errors
              updateErrors.add('${device.name}:  $error');
            }
            stausUpdated = true;
          }
        }).toList(),
      );
    } finally {
      final errorUpdated = updateErrors.length != _updateErrors.length;
      _updateErrors = updateErrors;
      if (errorUpdated) {
        notifyListeners();
      } else if (stausUpdated) {
        _providerDeviceStatus.update();
      } else {
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
      storeDevices();
      subscribeToNotifications();
    });
  }

  Device getDeviceById(String id) {
    return devices.firstWhere((device) {
      return device.id == id;
    }, orElse: () => null);
  }

  Device getDeviceByOrder(int order) {
    return devices[order];
  }

  Device addDevice(String deviceId) {
    final particleDevice = particle.Device(this._particleAccount, deviceId);
    final appDevice = Device(particleDevice);
    _devices.add(appDevice);
    return appDevice;
  }

  Future<void> removeDevice(String deviceId) {
    stopTimer();
    return getDeviceById(deviceId).remove().then((_) {
      _devices.removeWhere((device) => device.id == deviceId);
      return storeDevices();
    }).then((_) {
      return loadDevices();
    }).then((_) {
      startTimer();
    });
  }

  void deviceCommand(String deviceId, DoorCommands command) {
    final device = getDeviceById(_selectedDeviceId);
    if (device.connectionStatus != ConnectionStatus.ONLINE) {
      return null;
    }

    final commandString = device.commandLocal(command);
    _providerDeviceStatus.update();
    if (commandString != null) {
      device.commandRemote(commandString).then((result) {
        _providerDeviceStatus.update();
      });
    }
  }

  bool get isUsingNotifications {
    return _devices.fold(
        false, (value, device) => value || device.isUsingNotifications);
  }

  bool get isUsingLocation {
    return _devices.fold(
        false, (value, device) => value || device.isUsingLocation);
  }

  bool get isGeofenceReady {
    return _isGeofenceReady;
  }

  Future<bool> subscribeToNotifications() async {
    final token = await _firebaseMessaging.getToken();
    final Map postData = {
      'platform': 'fcm',
      'subscriber': token,
      'user': accountEmail,
      'authtoken': _particleAccount.token
    };

    if (isUsingNotifications) {
      bool allowed = await _firebaseMessaging.requestNotificationPermissions();
      if (allowed != null && !allowed) {
        print('notification not ready');
        return Future.value(false);
      }
      postData['action'] = 'add';
      postData['device'] = _devices.map((device) => device.id).join(',');
    } else {
      postData['action'] = 'remove';
      print('notifications not used');
      return true;
    }
    // print('data: ${postData.toString()}');

    try {
      await http
          .post(
        URL_PUSHSUBSCRIBE,
        headers: null,
        body: postData,
      )
          .then((response) {
//        print('response: ${response.body}');
        final responseMap = json.decode(response.body);
        if (responseMap['error'] != null) {
          throw (responseMap['error']);
        }
      });
    } catch (error) {
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

  List<String> get initErrors {
    return _initErrors;
  }

  List<String> get updateErrors {
    return _updateErrors;
  }

  bool get isUpdatingDevices {
    return _isUpdatingDevices;
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
    if (authTime != null && (DateTime.now().millisecondsSinceEpoch - authTime) < AUTH_TIMEOUT) {
      return;
    }
    _localAuth = true;
  }

  void fulfillLocalAuth() {
    authTime = DateTime.now().millisecondsSinceEpoch;
    isInLocalAuth = false;
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
    return [..._devices];
  }
}
