import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkedText extends StatelessWidget {
  final String text;
  final String link;

  LinkedText(this.text, this.link);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 10, 0, 0),
      child: Row(
        children: <Widget>[
          const Text('•'),
          const SizedBox(
            width: 5,
          ),
          InkWell(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyText2.copyWith(
                    decoration: TextDecoration.underline,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            onTap: () {
              canLaunch(link).then((ok) {
                if (ok) {
                  launch(link);
                }
              });
            },
          )
        ],
      ),
    );
  }
}
