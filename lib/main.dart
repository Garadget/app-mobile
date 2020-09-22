import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './providers/account.dart';
import './providers/device_status.dart';
import './providers/device_info.dart';

import './screens/home.dart';
import './screens/account_signup.dart';
import './screens/account_signin.dart';
import './screens/account_reset.dart';
import './screens/local_auth.dart';
import './screens/device_settings.dart';
import './screens/device_alerts.dart';
import './screens/device_remove.dart';
import './screens/device_add_intro.dart';
import './screens/device_add_config.dart';
import './screens/device_add_confirm.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ProviderAccount providerAccount = ProviderAccount();
    ProviderDeviceStatus providerDeviceStatus = providerAccount.providerDeviceStatus;
    ProviderDeviceInfo providerDeviceInfo = providerAccount.providerDeviceInfo;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => providerAccount),
        ChangeNotifierProvider(create: (_) => providerDeviceStatus),
        ChangeNotifierProvider(create: (_) => providerDeviceInfo),
      ],
      child: MaterialApp(
        title: 'Garadget',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
//        brightness: Brightness.dark,
          primarySwatch: MaterialColor(0xff005e20, {
            50: Color(0xffe0ece4),
            100: Color(0xffb3cfbc),
            200: Color(0xff80af90),
            300: Color(0xff4d8e63),
            400: Color(0xff267641),
            500: Color(0xff005e20),
            600: Color(0xff00561c),
            700: Color(0xff004c18),
            800: Color(0xff004213),
            900: Color(0xff00310b)
          }),
          accentColor: Color.fromRGBO(0xf4, 0x68, 0x09, 1),
          fontFamily: 'Roboto',
//        accentColor: Colors.white,
          textTheme: TextTheme(
            headline5: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            // default text style
            bodyText2: TextStyle(),
            // grey standard size text used for values
            bodyText1: TextStyle(
//              fontSize: 12,
              height: 1,
              color: Colors.grey,
            ),
            // grey smaller size text used for notes
            caption: TextStyle(
              color: Colors.grey,
            )
          ),
          buttonTheme: ButtonThemeData(
            textTheme: ButtonTextTheme.primary,
            padding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        initialRoute: ScreenHome.routeName,
        routes: {
          ScreenHome.routeName: (_) => ScreenHome(),
          ScreenAccountSignup.routeName: (_) => ScreenAccountSignup(),
          ScreenAccountSignin.routeName: (_) => ScreenAccountSignin(),
          ScreenAccountReset.routeName: (_) => ScreenAccountReset(),
          ScreenLocalAuth.routeName: (_) => ScreenLocalAuth(),
          ScreenDeviceSettings.routeName: (_) => ScreenDeviceSettings(),
          ScreenDeviceAlerts.routeName: (_) => ScreenDeviceAlerts(),
          ScreenDeviceRemove.routeName: (_) => ScreenDeviceRemove(),
          ScreenDeviceAddIntro.routeName: (_) => ScreenDeviceAddIntro(),
          ScreenDeviceAddConfig.routeName: (_) => ScreenDeviceAddConfig(),
          ScreenDeviceAddConfirm.routeName: (_) => ScreenDeviceAddConfirm(),
        },
      ),
    );
  }
}
