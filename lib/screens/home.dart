import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/account.dart';
import '../widgets/home_drawer.dart';
import '../widgets/device_card.dart';
import '../widgets/device_carousel.dart';
import '../widgets/busy_message.dart';
import '../widgets/network_error.dart';
import './device_add_intro.dart';
import './account_signin.dart';
import './account_signup.dart';
import './local_auth.dart';

const URL_COMMUNITY_BOARD = 'https://status.particle.io';

class ScreenHome extends StatefulWidget {
  static const routeName = "/";

  @override
  _ScreenHomeState createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> with WidgetsBindingObserver {
  ProviderAccount _account;
  bool _isLoading = false;
  bool _isFirstRun = true;
  String _errorMessage;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _account.stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
      _account = Provider.of<ProviderAccount>(context, listen: true);
      _networkRequest(() => _account.init()).then((_) {
        return localAuthChallageDialog(context, AuthLevel.ALWAYS);
      }).then((allowed) {
        if (allowed) {
          _account.startTimer();
        }
      });
    } else if (_account.updateErrors) {
      _account.clearDeviceCache();
      _networkRequest(() => _account.loadDevices(true));
    }
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _account.requireLocalAuth();
    if (state == AppLifecycleState.resumed) {
      localAuthChallageDialog(context, AuthLevel.ALWAYS);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading && _errorMessage == null) {
      return BusyScreen('Loading...');
    } else if (_errorMessage != null) {
      body = NetworkError(_errorMessage);
    } else if (MediaQuery.of(context).orientation == Orientation.landscape) {
      body = _buildLandscape(context);
    } else if (MediaQuery.of(context).orientation == Orientation.portrait) {
      body = _buildPortrait(context);
    } else {
      throw ("Unsupported Orientation");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doors'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.refresh,
              semanticLabel: 'Refresh List',
            ),
            onPressed: () {
              _networkRequest(() => _account.loadDevices(true));
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              semanticLabel: 'Add Device',
            ),
            onPressed: () {
              _account.stopTimer();
              Navigator.of(context)
                  .pushNamed(
                ScreenDeviceAddIntro.routeName,
                arguments: null,
              )
                  .then((result) {
                if (result != null) {
                  _networkRequest(() => _account.loadDevices(true));
                } else {
                  _account.startTimer();
                }
              });
            },
          )
        ],
      ),
      drawer: WidgetHomeDrawer(),
      body: body,
    );
  }

  Widget _buildLandscape(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 50,
          child: WidgetDeviceCarousel(),
        ),
        Expanded(
          flex: 50,
          child: WidgetDeviceCard(),
        ),
      ],
    );
  }

  Widget _buildPortrait(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 55,
          child: WidgetDeviceCarousel(),
        ),
        Expanded(
          flex: 45,
          child: WidgetDeviceCard(),
        ),
      ],
    );
  }

  Future<void> _networkRequest(Future<bool> request()) async {
    if (_isLoading) {
      return;
    }
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    await tryNetwork(
      request,
      onError: (error) {
        setState(() {
          _errorMessage = error;
        });
      },
      onRetry: () => mounted,
    );

    String screen;
    if (_account.isAuthenticated) {
      if (_account.devices.length == 0) {
        // authenticated with no devices - start device setup
        screen = ScreenDeviceAddIntro.routeName;
      } else {
        // authenticated with devices - stay and show device list
        setState(() {
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }
    } else {
      if (_account.accountEmail != null) {
        // unauthenticated with previous account - login
        screen = ScreenAccountSignin.routeName;
      } else {
        // unauthenticated without previous account - signup
        screen = ScreenAccountSignup.routeName;
      }
    }
    if (screen != null) {
      Navigator.of(context).pushReplacementNamed(screen);
      return;
    }
  }

}
