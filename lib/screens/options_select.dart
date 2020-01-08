import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/busy_message.dart';
import '../widgets/snackbar_message.dart';

class OptionsSelect extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> options;
  final dynamic value;
  final Future Function(dynamic) onSelect;

  OptionsSelect(
    this.label,
    this.options,
    this.value,
    this.onSelect,
  );

  @override
  _OptionsSelectState createState() => _OptionsSelectState();
}

class _OptionsSelectState extends State<OptionsSelect> {
  dynamic selectedValue;

  @override
  void initState() {
    selectedValue = widget.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label),
      ),
      body: ListView(
        children: widget.options.map((option) {
          return InkWell(
            onTap: () {
              dynamic oldValue = selectedValue;
              setState(() {
                selectedValue = option['value'];
              });
              if (selectedValue == oldValue) {
                Navigator.of(context).pop();
                return false;
              }
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  return BusyMessage('SAVING...');
                },
              );
              widget.onSelect(selectedValue).whenComplete(() {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }).catchError((error) {
                Navigator.of(context).pop();
                showSnackbarMessage(context, "Error Saving ${widget.label}");
                print('error: ${error.toString()}');
              });
              return true;
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      option['text'],
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  option['value'] == selectedValue
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).accentColor,
                          size: 24,
                        )
                      : SizedBox(height: 24),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
