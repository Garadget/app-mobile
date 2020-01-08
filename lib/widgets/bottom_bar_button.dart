import 'package:flutter/material.dart';

class BottomBarButton extends StatelessWidget {

  final String text;
  final Function onTap;
  
  BottomBarButton(this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        padding: EdgeInsets.all(15.0),
        decoration: const BoxDecoration(
          color: Colors.black12,
          border: Border(
            top: BorderSide(
              color: Colors.black26,
              width: 1.0,
            ),
          ),
        ),
        child: Text(text),
      ),
      onTap: onTap,
    );
  }
}