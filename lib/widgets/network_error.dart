import 'package:flutter/material.dart';
import 'package:particle_setup/particle_setup.dart';
import 'package:url_launcher/url_launcher.dart';

const URL_SERVER_STATUS = 'https://status.particle.io';
const MESSAGE_ERROR =
    'We\'ll keep on trying, but if the issue persists for more than few seconds, please check your WiFi and cellular settings to make sure that your device is connected to the Internet.';
const MESSAGE_INSETUP1 =
    'You are still connected to Garadget\'s temporary WiFi access point.';
const MESSAGE_INSETUP2 =
    'Please reconnect to your WiFi router and return to this screen.';

Future<bool> tryNetwork(
  Future<bool> networkRequest(), {
  void onError(String error),
  bool onRetry(),
}) async {
  while (true) {
    try {
      return await networkRequest();
    } catch (error) {
      String errorMessage = error.toString();
      // check if still connected to photon
      try {
        final particleSetup = ParticleSetup();
        final deviceIdResponse = await particleSetup.getDeviceId();
        if (deviceIdResponse.isOk()) {
          errorMessage = 'in_setup';
        }
      } catch (_) {}
      if (onError != null) {
        onError(errorMessage);
      }
      if (error.toString() != 'timeout') {
        await Future.delayed(Duration(seconds: 1));
      }
      if (onRetry != null && onRetry() == false) {
        return null;
      }
    }
  }
}

String errorHeader(error) {
  final errorText = error.toString();
  switch (errorText) {
    case 'timeout':
      return 'Request Timed Out';
    case 'in_setup':
      return 'Reconnect WiFi';
    case 'invalid_grant':
      return 'Login Error';
    case 'invalid_token':
      return 'Login Required';
    case 'customer_exists':
      return 'Customer Exists';
    default:
      return 'Network Error';
  }
}

String errorBrief(error) {
  final errorText = error.toString();
  switch (errorText) {
    case 'timeout':
      return 'Please try again in a moment. ';
    case 'in_setup':
      return MESSAGE_INSETUP1 + ' ' + MESSAGE_INSETUP2;
    case 'invalid_grant':
      return 'Incorrect email address or password. Please try again or proceed to password reset.';
    case 'invalid_token':
      return 'The authentication token is no longer valid. Please re-login into your Garadget account.';
    case 'customer_exists':
      return 'The customer with this email address aready exists. Try resetting the password if you unable to login.';
    default:
      return 'Please check your WiFi and cellular settings to make sure that your device is connected to the Internet.';
  }
}

IconData errorIcon(error) {
  final errorText = error.toString();
  switch (errorText) {
    case 'timeout':
      return Icons.hourglass_empty;
    case 'in_setup':
      return Icons.router;
    case 'invalid_token':
    case 'invalid_grant':
      return Icons.security;
    case 'customer_exists':
      return Icons.people_outline;
    default:
      return Icons.cloud_off;
  }
}

Future showNetworkErrorDialog(BuildContext context, dynamic error) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return NetworkErrorDialog(error);
    },
  );
}

class NetworkErrorDialog extends StatelessWidget {
  final String message;
  NetworkErrorDialog(dynamic error) : message = error.toString();

  @override
  Widget build(BuildContext context) {
  return AlertDialog(
    title: Text(errorHeader(message)),
    content: Text(errorBrief(message)),
    actions: <Widget>[
      RaisedButton(
        child: Text('Dismiss'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ],
  );
  }
}

class NetworkError extends StatelessWidget {
  final String message;

  NetworkError(dynamic error) : message = error.toString();

  @override
  Widget build(BuildContext context) {
    if (message == 'timeout') {
      return _buildTimeout(context);
    } else if (message == 'in_setup') {
      return _buildInSetup(context);
    } else {
      return _buildError(context);
    }
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              errorIcon(message),
              size: 54,
            ),
            const SizedBox(height: 15),
            Text(
              errorHeader(message),
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 10),
            Text(
              MESSAGE_ERROR,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyText1,
            ),
            const SizedBox(height: 10),
            Text(
              'Technical Details: $message',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            FlatButton(
              child: const Text('SERVICE STATUS'),
              onPressed: () {
                canLaunch(URL_SERVER_STATUS).then((ok) {
                  if (ok) {
                    launch(URL_SERVER_STATUS);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeout(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              errorIcon(message),
              size: 54,
            ),
            const SizedBox(height: 15),
            Text(
              errorHeader(message),
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 10),
            Text(
              MESSAGE_ERROR,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInSetup(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              errorIcon(message),
              size: 54,
            ),
            const SizedBox(height: 15),
            Text(
              errorHeader(message),
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 10),
            Text(
              MESSAGE_INSETUP1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyText1,
            ),
            const SizedBox(height: 10),
            Text(
              MESSAGE_INSETUP2,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ],
        ),
      ),
    );
  }
}
