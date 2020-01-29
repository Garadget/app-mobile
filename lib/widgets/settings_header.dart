import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsHeader extends StatelessWidget {
  final String title;
  final String helpLink;

  SettingsHeader(this.title, {this.helpLink});

  @override
  Widget build(BuildContext context) {
    TextStyle style = Theme.of(context).textTheme.subtitle;
    Widget content = Text(
      title,
      style: style,
    );
    if (helpLink != null) {
      content = InkWell(
        onTap: () {
          canLaunch(helpLink).then((ok) {
            if (ok) {
              launch(helpLink);
            }
          });
        },
        child: Row(
          children: <Widget>[
            Expanded(
              child: content,
            ),
            Icon(
              Icons.help_outline,
              color: style.color,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(15, 25, 15, 10),
          decoration: BoxDecoration(
            color: Colors.black12,
            border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: content,
        ),
      ],
    );
  }
}
