import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:provider/provider.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/account.dart';
import '../screens/account_signin.dart';
import '../screens/local_auth.dart';

const LINK_HELP = 'https://community.garadget.com/';
const LINK_SOURCE = 'https://github.com/Garadget/';

class WidgetHomeDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final _account = Provider.of<ProviderAccount>(context, listen: false);

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
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          child: Column(
                            children: <Widget>[
                              WidgetDrawerItem(
                                _account.accountEmail,
                                Icons.account_circle,
                              ),
                              WidgetDrawerItem(
                                'Authentication',
                                Icons.fingerprint,
                                action: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context)
                                      .pushNamed(ScreenLocalAuth.routeName);
                                },
                                trailing: Icon(Icons.chevron_right),
                              ),
                              WidgetDrawerItem(
                                'Sign Out',
                                Icons.exit_to_app,
                                action: () {
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                  Navigator.of(context).pushReplacementNamed(
                                      ScreenAccountSignin.routeName);
                                },
                              ),
                              Expanded(
                                child: Container(
                                  child: const SizedBox(),
                                ),
                              ),
                              Divider(),
                              WidgetDrawerItem(
                                'Get Help',
                                Icons.help_outline,
                                link: LINK_HELP,
                              ),
                              WidgetDrawerItem(
                                'v.${snapshot.data.version}+${snapshot.data.buildNumber}, GPL3',
                                Icons.lock_open,
                                link: LINK_SOURCE,
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
      },
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
  final String link;
  final Function action;
  final Widget trailing;

  WidgetDrawerItem(this.text, this.icon,
      {this.action, this.link, this.trailing});

  @override
  Widget build(BuildContext context) {
    final color = action == null && link == null
        ? Theme.of(context).disabledColor
        : Theme.of(context).textTheme.button.color;

    final iconSize = 30 * MediaQuery.of(context).textScaleFactor;
    final row = <Widget>[
      Icon(
        icon,
        size: iconSize,
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
            ),
          ),
        ),
      ),
    ];
    if (trailing != null) {
      row.add(const SizedBox(width: 5));
      row.add(trailing);
    } else if (link != null) {
      row.add(const SizedBox(width: 5));
      row.add(Icon(
        Icons.link,
//        size: iconSize,
      ));
    }

    return GestureDetector(
      onTap: action != null
          ? action
          : (link != null
              ? () {
                  canLaunch(link).then((ok) {
                    if (ok) {
                      launch(link);
                    }
                  });
                }
              : null),
      child: Container(
        height: 36,
        child: Row(
          children: row,
        ),
      ),
    );
  }
}
