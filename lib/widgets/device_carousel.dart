import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carousel_slider/carousel_slider.dart';

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

    return CarouselSlider(
        enableInfiniteScroll: false,
        initialPage: account.selectedDeviceOrder,
        aspectRatio: 1.4,
        onPageChanged: account.deviceSelectByOrder,
        viewportFraction: 0.7,
        enlargeCenterPage: true,
        autoPlay: false,
        items: account.devices.map((device) {
          return WidgetDeviceCarouselItem(
            device,
          );
        }).toList());
  }
}
