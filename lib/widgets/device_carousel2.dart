import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './device_carousel_item.dart';
import '../providers/account.dart';

class WidgetDeviceCarousel extends StatefulWidget {
  @override
  _WidgetDeviceCarouselState createState() => _WidgetDeviceCarouselState();
}

class _WidgetDeviceCarouselState extends State<WidgetDeviceCarousel> {
  @override
  Widget build(BuildContext context) {
    final account = Provider.of<ProviderAccount>(context, listen: true);
    final fixedExtentScrollController = FixedExtentScrollController();

    if (account.devices.length == 0) {
      return Center(
        child: Text('No devices found'),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return /*RotatedBox(
        quarterTurns: 1,
        child: */ListWheelScrollView(
          onSelectedItemChanged: account.deviceSelectByOrder,
          controller: fixedExtentScrollController,
          physics: FixedExtentScrollPhysics(),
          children: account.devices.map((device) {
            return /*RotatedBox(
              child: */WidgetDeviceCarouselItem(device)/*,
              quarterTurns: 3,
            )*/;
          }).toList(),
          itemExtent: constraints.maxHeight * 0.85,
          diameterRatio: 3,
//        ),
      );
    });
  }
}
