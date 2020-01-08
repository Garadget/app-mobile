import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/account.dart';
import '../screens/account_signin.dart';

class WidgetHomeDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ProviderAccount account =
        Provider.of<ProviderAccount>(context, listen: false);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth * 0.75,
            child: Drawer(
              semanticLabel: "Slide-In Menu",
              child: Column(
                children: <Widget>[
                  WidgetDrawerHeader("Garadget"),
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      child: Column(
                        children: <Widget>[
                          WidgetDrawerItem(
                            account.accountEmail,
                            Icons.account_circle,
                            null,
                          ),
                          WidgetDrawerItem(
                            'Authentication',
                            Icons.fingerprint,
                            () {},
                          ),
                          WidgetDrawerItem(
                            'Sign Out',
                            Icons.exit_to_app,
                            () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  ScreenAccountSignin.routeName,
                                  (route) => route.isFirst);
                            },
                          ),
                          Expanded(
                            child: Container(
                              child: SizedBox(),
                            ),
                          ),
                          WidgetDrawerItem(
                            'Get Help',
                            Icons.help_outline,
                            () {},
                          ),
                          WidgetDrawerItem(
                            'About This App (v2.0)',
                            Icons.copyright,
                            () {},
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class WidgetDrawerHeader extends StatelessWidget {
  final String text;

  WidgetDrawerHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Row(
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/logo-boxed.svg',
            color: Theme.of(context).primaryTextTheme.title.color,
            height: 30.0,
            width: 30.0,
            allowDrawingOutsideViewBox: true,
            semanticsLabel: '$text Logo',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            child: Text(
              text,
              style: Theme.of(context).primaryTextTheme.title,
            ),
          ),
        ],
      ),
    );
  }
}

class WidgetDrawerItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Function action;

  WidgetDrawerItem(this.text, this.icon, this.action);

  @override
  Widget build(BuildContext context) {
    final color = action == null
        ? Theme.of(context).disabledColor
        : Theme.of(context).textTheme.button.color;

    return GestureDetector(
      onTap: action,
      child: Container(
        height: 36,
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 30 * MediaQuery.of(context).textScaleFactor,
              color: color,
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: TextStyle(
                      color: color,
                      fontSize: Theme.of(context).textTheme.button.fontSize),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
