import 'package:flutter/material.dart';

class SettingsItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final void Function(BuildContext context) action;

  SettingsItem(
    this.label, {
    this.value,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [
      Expanded(
        child: Text(label),
      ),
    ];

    if (value != null) {
      items.add(
        Text(
          value,
          style: Theme.of(context).textTheme.body2,
          softWrap: false,
          overflow: TextOverflow.fade,
        ),
      );
    }

    if (icon != null) {
      items.add(const SizedBox(
        width: 5,
        height: 40,
      ));
      items.add(
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).textTheme.body2.color,
        ),
      );
    } else {
      items.add(const SizedBox(
        height: 40,
        width: 29,
      ));
    }

    Widget content = Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: items,
      ),
    );

    if (action != null) {
      content = InkWell(
        child: content,
        onTap: () {
          action(context);
        },
      );
    }

    return content;
  }
}
