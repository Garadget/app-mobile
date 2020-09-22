import 'dart:async';
import 'particle.dart' as particle;
import 'package:geolocator/geolocator.dart';

enum DoorStatus { OPEN, CLOSED, OPENING, CLOSING, STOPPED, UNKNOWN }
enum DoorCommands { OPEN, CLOSE, STOP, NONE }
enum ConnectionStatus { ONLINE, TIMEOUT, OFFLINE, ERROR, LOADING, UNKNOWN }
enum GeofenceStatus { DISABLED, ENTER, EXIT, IN, OUT }

class Device {
  static const DEFAULT_NAME = 'Garage';
  static const STKEY_CONFIG = 'config';
  static const STKEY_NET = 'net';
  static const STKEY_ALERTS = 'alerts';
  static const STKEY_GEO = 'geo';
  static const GEO_RADIUSDIFF = 0.8; // enter geofence ratio to exit geofence

  static String intToString(int value) {
    return value.toString();
  }

  static int stringToInt(String value) {
    return int.tryParse(value);
  }

  static const List<Map<String, dynamic>> CONFIG_MAP = [
    {
      'var': STKEY_CONFIG,
      'key': 'ver',
      'prop': 'firmwareVersion',
    },
    {
      'var': STKEY_CONFIG,
      'key': 'sys',
      'prop': 'systemVersion',
    },
    {
      'var': STKEY_CONFIG,
      'key': 'nme',
      'prop': 'name',
    },
    {
      'var': STKEY_CONFIG,
      'key': 'srt',
      'prop': 'sensorThreshold',
      'devault': 10,
      'in': stringToInt,
      'out': intToString,
    },
    {
      'var': STKEY_CONFIG,
      'key': 'rdt',
      'prop': 'scanInterval',
      'devault': 1000,
      'in': stringToInt,
      'out': intToString,
    },
    {
      'var': STKEY_CONFIG,
      'key': 'mtt',
      'prop': 'doorMotionTime',
      'default': 10000,
      'in': stringToInt,
      'out': intToString,
    },
    {
      'var': STKEY_CONFIG,
      'key': 'rlt',
      'prop': 'relayOnTime',
      'default': 300,
      'in': stringToInt,
      'out': intToString,
    },
    {
      'var': STKEY_CONFIG,
      'key': 'rlp',
      'prop': 'relayOffTime',
      'default': 1000,
      'in': stringToInt,
      'out': intToString,
    },
    {
      'var': STKEY_NET,
      'key': 'ip',
      'prop': 'ip',
    },
    {
      'var': STKEY_NET,
      'key': 'snet',
      'prop': 'subnet',
    },
    {
      'var': STKEY_NET,
      'key': 'gway',
      'prop': 'gateway',
    },
    {
      'var': STKEY_NET,
      'key': 'mac',
      'prop': 'mac',
    },
    {
      'var': STKEY_NET,
      'key': 'ssid',
      'prop': 'ssid',
    },
    {
      'var': STKEY_ALERTS,
      'key': 'aev',
      'prop': 'statusAlert',
      'default': 0,
      'in': stringToInt,
      'out': intToString
    },
    {
      'var': STKEY_ALERTS,
      'key': 'aot',
      'prop': 'timeoutAlert',
      'default': 0,
      'in': stringToInt,
      'out': intToString
    },
    {
      'var': STKEY_ALERTS,
      'key': 'ans',
      'prop': 'nightAlertFrom',
      'default': 0,
      'in': stringToInt,
      'out': intToString
    },
    {
      'var': STKEY_ALERTS,
      'key': 'ane',
      'prop': 'nightAlertTo',
      'default': 0,
      'in': stringToInt,
      'out': intToString
    },
    {
      'var': STKEY_ALERTS,
      'key': 'tzo',
      'prop': 'timeZone',
    },
    {
      'var': STKEY_GEO,
      'prop': 'enabled',
    },
    {
      'var': STKEY_GEO,
      'prop': 'latitude',
    },
    {
      'var': STKEY_GEO,
      'prop': 'longitude',
    },
    {
      'var': STKEY_GEO,
      'prop': 'radius',
    }
  ];

  final particle.Device particleDevice;
  final Map<String, dynamic> _deviceData = {};
  final Map<String, bool> _updates = {};
  ConnectionStatus _connectionStatus;
  DoorStatus _doorStatus = DoorStatus.UNKNOWN;
  DateTime _doorStatusTime = DateTime.now();
  bool _pendingStatusUpdate = false;
  bool _pendingCommand = false;
  int _skipStatusUpdates = 0;
  GeofenceStatus _geoStatus = GeofenceStatus.DISABLED;

  Device(this.particleDevice)
      : _connectionStatus = particleDevice.connected
            ? ConnectionStatus.LOADING
            : ConnectionStatus.OFFLINE;

  Future<bool> rename(String newName) {
    String oldName = name;
    final re = RegExp(r'[\W]');
    newName.replaceAll(re, '');
    if (newName.length > 31) {
      newName = newName.substring(0, 31);
    }

    setValue('config/name', newName);
    particleDevice.name = newName;
    return Future.wait([
      particleDevice.rename(newName),
      saveConfig(),
    ]).then((_) {
      _onSuccess();
      return true;
    }).catchError((error) {
      setValue('config/name', oldName);
      particleDevice.name = oldName;
      _onError(error);
    });
  }

  Future<bool> remove() {
    return particleDevice.unclaim();
  }

  bool setValue(String path, dynamic value) {
    List<String> pathList = path.split('/');
    dynamic container = _deviceData;

    while (pathList.length > 1) {
      final loc = pathList.removeAt(0);
      int index = int.tryParse(loc);
      if (loc is String && container is Map) {
        if (container[loc] == null) {
          Map<String, dynamic> newMap = {};
          container[loc] = newMap;
        }
        container = container[loc];
        continue;
      } else if (index != null && container is List) {
        if (container[index] == null) {
          List<dynamic> newList = [];
          container[index] = newList;
        }
        container = container[index];
        continue;
      }
      return false;
    }
    final oldValue = container[pathList[0]];
    if (value == oldValue) {
      return false;
    }
    if (value == null) {
      if (container is Map) {
        container.remove(pathList[0]);
      } else if (container is List) {
        container.removeAt(int.tryParse(pathList[0]));
      }
    } else {
      container[pathList[0]] = value;
    }
    _updates[path] = true;
    return true;
  }

  dynamic getValue(String path) {
//    print('getting value $path on $id');

    if (path == 'config/systemVersion') {
      return particleDevice.systemFirmwareVersion;
    }

    List<String> pathList = path.split('/');
    Map value = _deviceData;

    while (pathList.length > 1) {
      final loc = pathList.removeAt(0);
      if (loc is String && value is Map && value[loc] != null) {
        value = value[loc];
        continue;
      } else if (loc is int && value is List && value[loc] != null) {
        value = value[loc];
        continue;
      }
      return null;
    }
    return value[pathList[0]];
  }

  Future<Map<String, String>> readVariable(name) {
    return particleDevice.readVariable(name).then((value) {
      _onSuccess();
      Map<String, String> result = {};
      String pipeSeparated = value['result'];
      pipeSeparated.split('|').forEach((valuePairString) {
        List<String> valuePairList = valuePairString.split('=');
        if (valuePairList.length == 2) {
          result[valuePairList[0]] = valuePairList[1];
        } else if (valuePairList.length == 1) {
          result[valuePairList[0]] = null;
        }
      });
      return result;
    }).catchError(_onError);
  }

  Future<bool> _connectivityCheck() {
    if (_connectionStatus == ConnectionStatus.OFFLINE ||
        _connectionStatus == ConnectionStatus.TIMEOUT) {
      return getInfo();
    }
    return Future.value(true);
  }

  Future<bool> getInfo() {
    return particleDevice.getInfo().then((response) {
      // device connected - go ahead with the request
      _doorStatus = DoorStatus.UNKNOWN;
      if (response['connected']) {
        _connectionStatus = ConnectionStatus.ONLINE;
        return true;
      }
      _doorStatusTime = DateTime.parse(response['last_heard']);
      // device is still offline - skip request
      if (_connectionStatus == ConnectionStatus.OFFLINE) {
        return false;
      }
      // device went offline - update status
      _connectionStatus = ConnectionStatus.OFFLINE;
      throw ('offline');
    });
  }

  Future<bool> loadStatus() async {
    // prevent concurrent requests and skip few updates to allow door to respond to command
    if (_skipStatusUpdates > 0 || _pendingStatusUpdate || _pendingCommand) {
      _skipStatusUpdates--;
      return false;
    }

    _pendingStatusUpdate = true;
    bool statusChanged = true;
    try {
      bool deviceOnline = await _connectivityCheck();
      if (!deviceOnline) {
        return false;
      }
      Map<String, String> statusMap = await readVariable('doorStatus');

      // discard results in transition to avoid race conditions
      if (statusMap == null || _skipStatusUpdates > 0 || _pendingCommand) {
        _pendingStatusUpdate = false;
        return false;
      }

      Map<String, dynamic> status = {'reflection': 0};
      DoorStatus prevStatus = _doorStatus;
      _doorStatus = parseDoorStatus(statusMap['status']);
      statusChanged = prevStatus != _doorStatus;
      if (statusChanged) {
        _doorStatusTime = parseStatusTime(statusMap['time']);
      }
      var numValue = int.tryParse(statusMap['base'] ?? '');
      if (numValue != null) {
        status['ambientLight'] = ((1 - (numValue / 4095)) * 100).round();
      }
      status['reflection'] = int.tryParse(statusMap['sensor'] ?? '');
      status['wifiSignal'] = int.tryParse(statusMap['signal'] ?? '');
      setValue('status', status);
    } finally {
      _pendingStatusUpdate = false;
    }
    return statusChanged;
  }

  Future<bool> loadConfig() {
    return _connectivityCheck().then((deviceOnline) {
      if (!deviceOnline) {
        return false;
      }
      return Future.wait([
        loadStatus(),
        readVariable('doorConfig').then((configMap) {
          if (configMap == null) {
            return false;
          }
          final configChanged = parseConfig(STKEY_CONFIG, configMap);
          final alertsChanged = parseConfig(STKEY_ALERTS, configMap);
          return configChanged || alertsChanged;
        }),
        readVariable('netConfig').then((netMap) {
          return parseConfig(STKEY_NET, netMap);
        }),
      ]).then((result) {
        return result.reduce((value, element) => value || element);
      });
    });
  }

  bool parseConfig(String type, Map<String, dynamic> valueMap) {
    Map<String, dynamic> config = {};
    CONFIG_MAP.forEach((param) {
      if (param['var'] != type) {
        return;
      }
      String value = valueMap[param['key']] ?? param['default'];
      if (value == null) {
        return;
      }
      dynamic cleanValue = param['in'] != null ? param['in'](value) : value;
      config[param['prop']] = cleanValue;
    });
    return setValue(type, config);
  }

  Future<bool> saveConfig() {
    List<String> config = [];
    List<String> clearUpdates = [];
    _updates.forEach((path, _) {
      Map<String, dynamic> matchedParam;
      for (Map<String, dynamic> param in CONFIG_MAP) {
        String currPath = param['var'] + '/' + param['prop'];
        if (path == currPath) {
          matchedParam = param;
//          print('updated: $path');
          break;
        }
      }
      if (matchedParam == null || matchedParam['key'] == null) {
        return;
      }
      dynamic value = getValue(path);
      dynamic cleanValue =
          matchedParam['out'] != null ? matchedParam['out'](value) : value;
      config.add(matchedParam['key'] + '=' + cleanValue);
      clearUpdates.add(path);
    });
    if (config.length == 0) {
      return Future.value(false);
    }
    return particleDevice.callFunction('setConfig', config.join('|')).then(
      (result) {
        clearUpdates.forEach((path) {
          _updates.remove(path);
        });
        return true;
      },
    );
  }

  void _onError(error) {
    if (error == 'timeout') {
      if (_connectionStatus == ConnectionStatus.TIMEOUT ||
          _connectionStatus == ConnectionStatus.OFFLINE) {
        return;
      }
      _connectionStatus = ConnectionStatus.TIMEOUT;
      _doorStatusTime = DateTime.now();
    } else {
      _connectionStatus = ConnectionStatus.ERROR;
    }
    throw (error);
  }

  void _onSuccess() {
    _connectionStatus = ConnectionStatus.ONLINE;
  }

  Future<GeofenceStatus> getGeoStatus(double latitude, double longitude) async {
    if (!isUsingLocation) {
      return Future.value(GeofenceStatus.DISABLED);
    }
    final double doorLat = getValue('geo/latitude');
    final double doorLon = getValue('geo/longitude');
    double radius = getValue('geo/radius');

    if (doorLat == null || doorLon == null || radius == null) {
      return _geoStatus;
    }

    double distance = await Geolocator().distanceBetween(
      latitude,
      longitude,
      getValue('geo/latitude'),
      getValue('geo/longitude'),
    );
    GeofenceStatus newStatus;

    final outside = distance > radius;
    final inside = !outside && distance <= radius * GEO_RADIUSDIFF;

    switch (_geoStatus) {
      case GeofenceStatus.ENTER:
      case GeofenceStatus.IN:
        newStatus = outside ? GeofenceStatus.EXIT : GeofenceStatus.IN;
        break;
      case GeofenceStatus.EXIT:
      case GeofenceStatus.OUT:
        newStatus = inside ? GeofenceStatus.ENTER : GeofenceStatus.OUT;
        break;
      case GeofenceStatus.DISABLED:
        newStatus = outside ? GeofenceStatus.OUT : GeofenceStatus.IN;
        break;
    }
    _geoStatus = newStatus;
    return _geoStatus;
  }

  String get id {
    return particleDevice.id;
  }

  String get name {
    if (particleDevice.name == null) {
      return DEFAULT_NAME;
    }
    return particleDevice.name.replaceAll('_', ' ');
  }

  static DoorStatus parseDoorStatus(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return DoorStatus.CLOSED;
      case 'open':
        return DoorStatus.OPEN;
      case 'closing':
        return DoorStatus.CLOSING;
      case 'opening':
        return DoorStatus.OPENING;
      case 'stopped':
        return DoorStatus.STOPPED;
      default:
        return DoorStatus.UNKNOWN;
    }
  }

  DateTime parseStatusTime(String time) {
    DateTime statusTime = DateTime.now();
    var matches = RegExp(r'^(\d+)([smhd])$').firstMatch(time);
    if (matches == null) {
      return statusTime;
    }
    var value = int.tryParse(matches.group(1));

    switch (matches.group(2)) {
      case 's':
        return statusTime.subtract(Duration(seconds: value));
      case 'm':
        return statusTime.subtract(Duration(minutes: value));
      case 'h':
        return statusTime.subtract(Duration(hours: value));
      case 'd':
        return statusTime.subtract(Duration(days: value));
    }
    return statusTime;
  }

  String get doorStatusString {
    if (_connectionStatus != ConnectionStatus.ONLINE) {
      return connectionStatusString;
    }
    switch (doorStatus) {
      case DoorStatus.CLOSED:
        return 'closed';
      case DoorStatus.OPEN:
        return 'open';
      case DoorStatus.CLOSING:
        return 'closing...';
      case DoorStatus.OPENING:
        return 'opening...';
      case DoorStatus.STOPPED:
        return 'stopped';
      case DoorStatus.UNKNOWN:
      default:
        return 'loading...';
    }
  }

  DoorStatus get doorStatus {
    return _doorStatus;
  }

  String get connectionStatusString {
    switch (connectionStatus) {
      case ConnectionStatus.ONLINE:
        return 'online';
      case ConnectionStatus.TIMEOUT:
        return 'timeout';
      case ConnectionStatus.OFFLINE:
        return 'offline';
      case ConnectionStatus.ERROR:
        return 'error';
      case ConnectionStatus.LOADING:
      default:
        return 'loading...';
    }
  }

  ConnectionStatus get connectionStatus {
    return _connectionStatus;
  }

  set doorStatus(DoorStatus doorStatus) {
    if (doorStatus == _doorStatus) {
      return;
    }
    _doorStatusTime = DateTime.now();
    _doorStatus = doorStatus;
  }

  double get doorStatusTime {
    Duration statusTime = DateTime.now().difference(_doorStatusTime);
    return statusTime.inMilliseconds / 1000;
  }

  String get doorStatusTimeString {
    int time = (this.doorStatusTime).round();
    if (time < 1) {
      return 'now';
    }
    if (time == 1) {
      return '$time second';
    }
    if (time < 60) {
      return '$time seconds';
    }
    time = (time / 60).floor();
    if (time == 1.0) {
      return '$time minute';
    }
    if (time < 120.0) {
      return '$time minutes';
    }
    time = (time / 60).floor();
    if (time == 1.0) {
      return '$time hour';
    }
    if (time < 48.0) {
      return '$time hours';
    }
    time = (time / 24).floor();
    if (time == 1.0) {
      return '$time day';
    }
    return '$time days';
  }

  String commandLocal(DoorCommands command) {
    switch (command) {
      case DoorCommands.OPEN:
        switch (_doorStatus) {
          case DoorStatus.OPEN:
          case DoorStatus.OPENING:
            return null;
          default:
            doorStatus = DoorStatus.OPENING;
            return 'open';
        }
        break;

      case DoorCommands.CLOSE:
        switch (_doorStatus) {
          case DoorStatus.CLOSED:
          case DoorStatus.CLOSING:
            return null;
          default:
            doorStatus = DoorStatus.CLOSING;
            return 'close';
        }
        break;

      case DoorCommands.STOP:
        switch (_doorStatus) {
          case DoorStatus.CLOSED:
          case DoorStatus.OPEN:
          case DoorStatus.STOPPED:
            return null;
          default:
            doorStatus = DoorStatus.STOPPED;
            return 'stop';
        }
        break;

      default:
        return null;
    }
  }

  Future<bool> commandRemote(String sendCommand) async {
    _pendingCommand = true;
    bool result = false;
    try {
      result = await particleDevice.callFunction('setState', sendCommand);
    } finally {
      _skipStatusUpdates = 2;
      _pendingCommand = false;
      await loadStatus();
    }
    return result;
  }

  Map<String, dynamic> get persistentData {
    return {
      'id': id,
      'name': name,
      STKEY_CONFIG: getValue(STKEY_CONFIG) as Map<String, dynamic>,
      STKEY_ALERTS: getValue(STKEY_ALERTS) as Map<String, dynamic>,
      STKEY_NET: getValue(STKEY_NET) as Map<String, dynamic>,
    };
  }

  Map<String, dynamic> get locationData {
    final data = getValue(STKEY_GEO) as Map<String, dynamic>;
    return data != null && data['enabled'] ? data : null;
  }

  set locationData(Map<String, dynamic> location) {
    setValue(STKEY_GEO, location);
  }

  static Device rehydrate(particle.Account account, Map<String, dynamic> data) {
    final particleDevice = particle.Device(
      account,
      data['id'],
      name: data['name'],
      connected: true,
    );
    final device = Device(particleDevice);
    device.setValue(STKEY_CONFIG, data[STKEY_CONFIG]);
    device.setValue(STKEY_ALERTS, data[STKEY_ALERTS]);
    device.setValue(STKEY_NET, data[STKEY_NET]);
    return device;
  }

  bool get isUsingNotifications {
    int value = getValue('alerts/statusAlert');
    if (value != null && value != 0) {
      return true;
    }
    value = getValue('alerts/timeoutAlert');
    if (value != null && value != 0) {
      return true;
    }
    value = getValue('alerts/nightAlertFrom');
    int value2 = getValue('alerts/nightAlertTo');
    if (value != null && value2 != null && value != value2) {
      return true;
    }
    return false;
  }

  bool get isUsingLocation {
    return getValue('geo/enabled') ?? false;
  }
}
