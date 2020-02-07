import 'package:flutter/material.dart';
import '../screens/options_select.dart';

class SettingsSelect extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> options;
  final Map<String, dynamic> value;
  final Future Function(dynamic) onSelect;

  SettingsSelect(
    this.label,
    this.options,
    this.value,
    this.onSelect,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: InkWell(
        child: Row(
          children: [
            Text(
              label,
              softWrap: false,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                value == null ? 'Select ' + label : value['text'],
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.body2,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
            const SizedBox(
              width: 5,
              height: 40,
            ),
            Icon(
              Icons.chevron_right,
              size: 24,
              color: Theme.of(context).textTheme.body2.color,
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                OptionsSelect(label, options, value == null ? null : value['value'], onSelect),
          ));
        },
      ),
    );
  }
}
