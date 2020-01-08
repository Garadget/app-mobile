import 'package:flutter/material.dart';

class SettingsToggle extends StatelessWidget {
  final String label;
  final void Function(bool value) action;
  final bool value;

  SettingsToggle(
    this.label,
    this.value,
    this.action,
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label),
            ),
            Switch(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: Theme.of(context).primaryColor,
              value: value,
              onChanged: action,
            )
          ],
        ),
      ),
      onTap: () {
        action(!this.value);
      },
    );
  }
}
