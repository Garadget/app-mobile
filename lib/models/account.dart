import "device.dart";

class Account {

//  bool _loaded = false;
  final String email;
  String _accessToken;
//  String _refreshToken;
//  List<GaradgetDevice> _devices = [];
  int tokenExpires;

  Account(this.email);

  int _loadDevices() {
//    _loaded = true;
    return 0;
  }

  void signin(password) {
  }

  void signup(password) {
  }

  void signout() {
  }

  void reset() {
  }

  void reload() {
    _loadDevices();
  }

/*  List<Device> get devices {
    if (!_loaded) {
      _loadDevices();
    }
    return _devices;
  }*/

  Device getDevice(String deviceId) {
    return null;
  }

  String get accessToken {
    // refresh if expired
    return _accessToken;
  }

}