import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flare_flutter/flare_actor.dart';
import '../misc/controller_door_animation.dart';

import '../models/device.dart';
import '../providers/account.dart';
import '../providers/device_status.dart';
import '../screens/local_auth.dart';

class WidgetDeviceCarouselItem extends StatefulWidget {
  final Device device;

  WidgetDeviceCarouselItem(this.device) : super(key: Key(device.id));

  @override
  _WidgetDeviceCarouselItemState createState() =>
      _WidgetDeviceCarouselItemState();
}

class _WidgetDeviceCarouselItemState extends State<WidgetDeviceCarouselItem> {
  DragStartDetails _startVerticalDragDetails;
  DragUpdateDetails _updateVerticalDragDetails;
  ProviderAccount _account;
  final DoorAnimationController animationController = DoorAnimationController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _account = Provider.of<ProviderAccount>(context, listen: false);
    Provider.of<ProviderDeviceStatus>(context, listen: true);
    animationController.device = widget.device;
    animationController.start();

    return GestureDetector(
      onTap: _tapCommand,
      onVerticalDragStart: _handleSwipeStart,
      onVerticalDragUpdate: _handleSwipeUpdate,
      onVerticalDragEnd: _handleSwipeEnd,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(3),
        child: AspectRatio(
          aspectRatio: 180 / 195,
          child: Column(
            children: <Widget>[
              const AspectRatio(
                aspectRatio: 180 / 25,
                child: SizedBox(),
              ),
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 180 / 120,
                    child: FlareActor(
                      'assets/animations/garage-door.flr',
                      alignment: Alignment.center,
                      fit: BoxFit.fitWidth,
                      controller: animationController,
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      const AspectRatio(
                        aspectRatio: 180 / 52,
                        child: SizedBox(),
                      ),
                      AspectRatio(
                        aspectRatio: 180 / 36,
                        child: FittedBox(
                          child: WidgetProgressText(
                            animationController,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const AspectRatio(
                aspectRatio: 180 / 4,
                child: SizedBox(),
              ),
              AspectRatio(
                aspectRatio: 180 / 26,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    widget.device.name,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                ),
              ),
              AspectRatio(
                aspectRatio: 180 / 19,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    widget.device.doorStatusString,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _tapCommand() {
    DoorCommands command;
    switch (widget.device.doorStatus) {
      case DoorStatus.STOPPED:
      case DoorStatus.CLOSED:
        command = DoorCommands.OPEN;
        break;
      case DoorStatus.OPEN:
        command = DoorCommands.CLOSE;
        break;
      case DoorStatus.OPENING:
      case DoorStatus.CLOSING:
        command = DoorCommands.STOP;
        break;
      default:
        return null;
    }
    _deviceCommand(widget.device.id, command);
  }

  void _handleSwipeStart(DragStartDetails swipeDetails) {
    _startVerticalDragDetails = swipeDetails;
  }

  void _handleSwipeEnd(DragEndDetails swipeDetails) {
    if (widget.device.connectionStatus != ConnectionStatus.ONLINE) {
      return null;
    }

    double dx = _updateVerticalDragDetails.globalPosition.dx -
        _startVerticalDragDetails.globalPosition.dx;
    double dy = _updateVerticalDragDetails.globalPosition.dy -
        _startVerticalDragDetails.globalPosition.dy;

    if (dx.abs() > dy.abs() || dy.abs() < 30) {
      _tapCommand();
      return;
    }
    if (dy > 0) {
      _deviceCommand(widget.device.id, DoorCommands.CLOSE);
    } else if (dy < 0) {
      _deviceCommand(widget.device.id, DoorCommands.OPEN);
    }
  }

  void _handleSwipeUpdate(DragUpdateDetails swipeDetails) {
    _updateVerticalDragDetails = swipeDetails;
  }

  void _deviceCommand(String deviceId, DoorCommands command) async {
    final allowed = await localAuthChallageDialog(context, AuthLevel.ACTIONS);
    if (!allowed) {
      return;
    }
    _account.deviceCommand(deviceId, command);
  }
}

class WidgetProgressText extends StatefulWidget {
  final DoorAnimationController animationController;

  WidgetProgressText(this.animationController);

  @override
  _WidgetProgressTextState createState() => _WidgetProgressTextState();
}

class _WidgetProgressTextState extends State<WidgetProgressText> {
  int progress = 0;

  @override
  void initState() {
    widget.animationController.onProgress = (newProgress) {
      setState(() {
        progress = newProgress;
      });
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.animationController.showProgress ? 1 : 0,
      duration: Duration(milliseconds: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            progress.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 50,
            ),
          ),
          const Text(
            '%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.animationController.onProgress = null;
    super.dispose();
  }
}
