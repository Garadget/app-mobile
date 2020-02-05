import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../providers/account.dart';
import '../providers/device_status.dart';
import '../providers/device_info.dart';
import '../screens/device_settings.dart';
import '../widgets/snackbar_message.dart';

const STRING_PLACEHOLDER = '...';

class WidgetDeviceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _account = Provider.of<ProviderAccount>(context, listen: false);
    Provider.of<ProviderDeviceStatus>(context, listen: true);
    Provider.of<ProviderDeviceInfo>(context, listen: true);
    final _device = _account.selectedDevice;

    if (_account.initErrors.length > 0) {
      Future.delayed(Duration.zero, () {
        showSnackbarMessage(context, _account.initErrors.join("\n"));
        _account.initErrors.clear();
      });
    }

    if (_device == null) {
      return SizedBox.shrink();
    }

    final List<Widget> cards = [
      WidgetCardTile(
        icon: Icons.line_weight,
        title: 'Status: ${_device.doorStatusString}',
        subtitle: _device.doorStatusTimeString,
      ),
    ];
    if (_device.connectionStatus == ConnectionStatus.ONLINE) {
      cards.add(
        WidgetCardTile(
          icon: Icons.brightness_5,
          title: 'Reflection: ${_device.getValue('status/reflection') ?? STRING_PLACEHOLDER}%',
          subtitle: 'Ambient Light: ${_device.getValue('status/ambientLight') ?? STRING_PLACEHOLDER}%',
        ),
      );
      final int wifiSignal = _device.getValue('status/wifiSignal');
      final String wifiSignalString = wifiSignal == null ? STRING_PLACEHOLDER : ProviderAccount.wifiSignalToString(wifiSignal);
      cards.add(
        WidgetCardTile(
          icon: Icons.wifi,
          title: 'WiFi: $wifiSignalString',
          subtitle: 'SSID: ${_device.getValue('net/ssid') ?? STRING_PLACEHOLDER}',
        ),
      );
    }
    cards.add(
      WidgetCardTile(
        icon: Icons.settings,
        title: 'Alerts & Settings',
        subtitle: 'Configure your Garadget',
        tapHandler: () {
          Navigator.of(context).pushNamed(
            ScreenDeviceSettings.routeName,
            arguments: _device,
          );
        }),
    );

    return Card(
//      margin: EdgeInsets.all(10),
      elevation: 1,
      child: ListView(
        padding: const EdgeInsets.all(15),
        scrollDirection: Axis.vertical,
        children: cards,
      ),
    );
  }
}

class WidgetCardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Function tapHandler;

  WidgetCardTile({
    this.title,
    this.subtitle,
    this.icon,
    this.tapHandler,
  });

  @override
  Widget build(BuildContext context) {

    List<Widget> columns = [
      Icon(
        icon,
        size: 30,
        color: Colors.grey,
      ),
      SizedBox(
        width: 10,
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.headline,
              softWrap: false,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.subtitle,
              softWrap: false,
            ),
          ],
        ),
      )
    ];

    if (tapHandler != null) {
      columns.add(Icon(
        Icons.chevron_right,
        size: 30,
        color: Colors.grey,
      ));
    }

    Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
      child: Row(
        children: columns,
      ),
    );

    if (tapHandler != null) {
      return GestureDetector(
        onTap: tapHandler,
        child: content,
      );
    } else {
      return content;
    }
  }
}
