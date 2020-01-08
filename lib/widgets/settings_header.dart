import 'package:flutter/material.dart';

class SettingsHeader extends StatelessWidget {
  final String title;

  SettingsHeader(this.title);

  @override
  Widget build(BuildContext context) {
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
          child: Text(title, style: Theme.of(context).textTheme.subtitle),
        ),
      ],
    );
  }
}

