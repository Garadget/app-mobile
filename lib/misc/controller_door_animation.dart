import 'package:flare_flutter/flare.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';

import '../models/device.dart';

typedef void OnProgress();

class DoorAnimationController extends FlareController {

  // ratio of animation's native duration to door's specific motion duration
  double _timeRatio;

  // indicates if animation is currently running
  bool _animate = false;

  // indicates that currently selected animation is one frame 
  bool _static = false;

  // indicates that the animation object has been initialized 
  bool _ready = false;

  // name of currently selected animation in flare file
  String _reference;
  
  // completed portion of the animation 
  int _progress;

  // callback for updating the progress
  OnProgress _onProgress;

  Device _device;

  FlutterActorArtboard _artboard;
  FlareAnimationLayer _animation;

  set device(Device device) {
    _device = device;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _artboard = artboard;
    _ready = true;
    start();
  }

  void start() {

    if(!_ready) {
      return;
    }

    if (_device.connectionStatus != ConnectionStatus.ONLINE) {
        _reference = "disabled";
        _static = true;
    }
    else {
      switch (_device.doorStatus) {
        case DoorStatus.CLOSED:
          _reference = "closed";
          _static = true;
          break;

        case DoorStatus.OPEN:
          _reference = "open";
          _static = true;
          break;

        case DoorStatus.OPENING:
          _reference = "opening";
          _static = false;
          break;

        case DoorStatus.CLOSING:
          _reference = "closing";
          _static = false;
          break;

        case DoorStatus.STOPPED:
          _reference = "stopped";
          _static = true;
          break;

        default:
          _reference = "disabled";
          _static = true;
          break;
      }
    }

    _animation = FlareAnimationLayer()
      ..animation = _artboard.getAnimation(_reference)
      ..mix = 1.0;

    if (_static) {
      _timeRatio = 1;
      _animation.time = 0.0;
    }
    else {
      _timeRatio = _animation.duration * 1000 / _device.getValue('config/doorMotionTime');
      _animation.time = _device.doorStatusTime * _timeRatio;
    }
    _animate = true;

    advance(_artboard, 0.0);
  }

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    if (!_animate) {
      return true;
    }

    double newTime = _animation.time + _timeRatio * elapsed;
    int newProgress;
    bool newAnimate = _animate;

    if (newTime >= _animation.duration || _static) {
      newProgress = 100;
      newTime = _animation.duration;
      newAnimate = false;
    } else {
      newProgress = (newTime / _animation.duration * 100).round();
    }

    _animation.time = newTime;
    _animation.apply(artboard);

    if (newProgress != _progress || newAnimate != _animate) {
      if (_onProgress != null) {
        _onProgress();
      }
      _progress = newProgress;
      _animate = newAnimate;
    }
    return true;
  }

  bool get showProgress {
    return _animate;
  }

  int get progressValue {
    return _progress;
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  set onProgress(OnProgress callback) {
    _onProgress = callback;
  }
}
