import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//import 'package:carousel_slider/carousel_slider.dart';

import './device_carousel_item.dart';
import '../providers/account.dart';

class WidgetDeviceCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final account = Provider.of<ProviderAccount>(context, listen: true);

    if (account.devices.length == 0) {
      return Center(
        child: Text('No devices found'),
      );
    }

    final controller = PageController(
      viewportFraction: 0.7,
    );
    Future.delayed(Duration.zero, () {
      controller.jumpToPage(account.selectedDeviceOrder);
    });

    return PageView(
      controller: controller,
      children: account.devices.map((device) {
          return WidgetDeviceCarouselItem(
            device,
          );
        }).toList(),
        onPageChanged: account.deviceSelectByOrder,
    );
  }
}
