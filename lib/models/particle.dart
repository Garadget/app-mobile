import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart' as secrets;

class Account with http.BaseClient {
  static const AUTHURL = 'https://api.particle.io/oauth/token';
  static const BASEURL = 'https://api.particle.io/v1';
  static const SIGNUPURL = '$BASEURL/products/${secrets.PROD_ID}/customers';
  static const REQUEST_TIMEOUT = 8;

  http.Client httpClient = http.Client();
  String _authToken;
  //String _refreshToken;
  //DateTime _tokenExpires;
  bool _isAuthenticated = false;

  set token(String token) {
    _authToken = token;
    _isAuthenticated = true;
  }

  String get token {
    return _authToken;
  }

  bool get isAuthenticated {
    return _isAuthenticated;
  }

  Future<bool> signup(String username, String password) {
    if (username == null || password == null) {
      throw ('Username and Password are required for new account');
    }
    return post(
      SIGNUPURL,
      headers: <String, String>{
        'Authorization': 'Basic ' +
            base64Encode(
                utf8.encode('${secrets.CLIENT_ID}:${secrets.CLIENT_SECRET}')),
      },
      body: {
        'email': username,
        'password': password,
      },
    ).then((response) {
      final body = parseResponse(response);
      _authToken = body['access_token'];
      // _refreshToken = body['refresh_token'];
      // if (body['expires_in'] != null && body['expires_in'] > 0) {
      //   _tokenExpires = DateTime.now().add(Duration(seconds: 10));
      // }
      _isAuthenticated = true;
      return true;
    });
  }

  Future<bool> login(String username, String password) {
    if (username == null || password == null) {
      throw ('Username and Password are required to login');
    }
    return post(
      AUTHURL,
      headers: <String, String>{
        'Authorization': 'Basic ' +
            base64Encode(
                utf8.encode('${secrets.CLIENT_ID}:${secrets.CLIENT_SECRET}')),
      },
      body: {
        'grant_type': 'password',
        'username': username,
        'password': password,
      },
    ).then((response) {
      final body = parseResponse(response);
      _authToken = body['access_token'];
      // _refreshToken = body['refresh_token'];
      // if (body['expires_in'] != null && body['expires_in'] > 0) {
      //   _tokenExpires = DateTime.now().add(Duration(seconds: 10));
      // }
      _isAuthenticated = true;
      return true;
    });
  }

  Future<bool> logout() {
    if (_authToken == null || !_isAuthenticated) {
      _authToken = null;
      _isAuthenticated = false;
      return Future.value(true);
    }
    return delete('$BASEURL/access_tokens/current').then((response) {
      final body = parseResponse(response) as Map<String, dynamic>;
      if (body['ok']) {
        _authToken = null;
      }
      return (body['ok']);
    });
  }

  Future<List<Device>> getDevices() {
    return get('$BASEURL/devices').then((response) {
      final body = parseResponse(response);
      return body.map<Device>((device) {
        return Device(
          this,
          device['id'],
          name: device['name'],
          connected: device['connected'],
          lastHeard: DateTime.parse(device['last_heard']),
          systemFirmwareVersion: device['system_firmware_version'],
          lastIpAddress: device['last_ip_address'],
        );
      }).toList();
    });
  }

  Future<String> getClaimCode() {
    return post('$BASEURL/device_claims').then((response) {
      final body = parseResponse(response);
      return body['claim_code'];
    });
  }

  dynamic parseResponse(http.Response response) {
    const List<String> AUTH_ERRORS = [
      'invalid_token',
      'invalid_grant',
      'customer_exists',
    ];
    final body = json.decode(response.body);
    if (body is Map<String, dynamic> && body['error'] != null) {
      if (AUTH_ERRORS.contains(body['error'])) {
        _isAuthenticated = false;
      }
      String description = body['error_description'] ?? body['info'];
      print('Particle Error: ${body['error']}' +
          (description == null ? '' : ' - $description'));
      throw (body['error']);
    }
    _isAuthenticated = true;
    return body;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final url = request.url.toString();
    if (url != AUTHURL && url != SIGNUPURL) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }
    return httpClient.send(request).timeout(Duration(seconds: REQUEST_TIMEOUT),
        onTimeout: () {
      throw ('timeout');
    });
  }

  @override
  void close() {
    httpClient.close();
    print('closed http');
  }
}

class Device {
  final Account account;
  final String id;
  bool connected;
  String name;
  String systemFirmwareVersion;
  String lastIpAddress;
  DateTime lastHeard;
  bool firmwareUpdatesEnabled;

  Device(
    this.account,
    this.id, {
    this.name,
    this.connected = false,
    this.lastHeard,
    this.systemFirmwareVersion,
    this.lastIpAddress,
    this.firmwareUpdatesEnabled,
  });

  Future<Map> getInfo() {
    return account.get('${Account.BASEURL}/devices/$id').then((response) {
      var body = account.parseResponse(response) as Map<String, dynamic>;

      name = body['name'];
      connected = body['connected'];
      lastHeard = DateTime.parse(body['last_heard']);
      systemFirmwareVersion = body['system_firmware_version'];
      lastIpAddress = body['last_ip_address'];
      firmwareUpdatesEnabled = body['firmware_updates_enabled'];
      return body;
    });
  }

  Future<Map> readVariable(name) {
    return account
        .get(
      '${Account.BASEURL}/devices/$id/$name',
    )
        .then((response) {
      return account.parseResponse(response);
    });
  }

  Future<bool> callFunction(name, value) {
    return account.post(
      '${Account.BASEURL}/devices/$id/$name',
      body: <String, String>{'arg': value},
    ).then((response) {
      var body = account.parseResponse(response) as Map<String, dynamic>;
      connected = body['connected'];
      return (body['return_value'] == 1);
    });
  }

  Future<String> rename(name) {
    return account.put(
      '${Account.BASEURL}/devices/$id',
      body: <String, String>{'name': name},
    ).then((response) {
      var body = account.parseResponse(response) as Map<String, dynamic>;
      return (body['name']);
    });
  }

  Future<bool> unclaim() {
    return account.delete('${Account.BASEURL}/devices/$id').then((response) {
      var body = account.parseResponse(response) as Map<String, dynamic>;
      return body['ok'];
    });
  }
}
