import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './device_add_intro.dart';
import './account_signin.dart';
import '../providers/account.dart';
import '../misc/input_decoration.dart';
import '../widgets/busy_message.dart';
import '../widgets/network_error.dart';
import '../widgets/form_logo.dart';
import 'package:url_launcher/url_launcher.dart';

const LINK_BUY = 'https://www.garadget.com/product/garadget/';

class ScreenAccountSignup extends StatefulWidget {
  static const routeName = "/account/signup";

  @override
  _ScreenAccountSignupState createState() => _ScreenAccountSignupState();
}

class _ScreenAccountSignupState extends State<ScreenAccountSignup> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFirstRun = true;
  String _errorMessage;
  ProviderAccount _account;
  String _username = '';
  String _password = '';

  @override
  void setState(function) {
    if (mounted) {
      super.setState(function);
    }
  }

  @override
  void deactivate() {
    _isFirstRun = true;
    super.deactivate();
  }

  @override
  void didChangeDependencies() async {
    if (_isFirstRun) {
      _isFirstRun = false;
      _account = Provider.of<ProviderAccount>(context, listen: false);
      await _account.initStorage();

      if (_isLoading) {
        return;
      }
      setState(() {
        _errorMessage = null;
        _isLoading = true;
      });

      await tryNetwork(
        _account.logout,
        onError: (error) {
          setState(() {
            _errorMessage = error;
          });
        },
        onRetry: () => mounted,
      );
      setState(() {
        _errorMessage = null;
        _isLoading = false;
      });
    }
    super.didChangeDependencies();
  }

  void _signup() async {
    if (!_formKey.currentState.validate()) {
      return null;
    }
    await showBusyMessage(context, 'Signing up...');
    String message;
    await tryNetwork(
      () {
        return _account.signup(_username, _password);
      },
      onError: (error) {
        message = error;
      },
      onRetry: () => false,
    );
    Navigator.of(context).pop();
    if (message == null) {
      Navigator.of(context)
          .pushReplacementNamed(ScreenDeviceAddIntro.routeName);
    } else {
      showNetworkErrorDialog(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0 ||
        MediaQuery.of(context).size.height < 400;

    Widget body;
    if (_isLoading && _errorMessage == null) {
      return BusyScreen('Loading...');
    } else if (_errorMessage != null) {
      body = NetworkError(_errorMessage);
    } else {
      body = Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            isKeyboardVisible ? SizedBox.shrink() : FormLogo(),
            Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      autocorrect: false,
                      autofocus: false,
                      keyboardType: TextInputType.emailAddress,
                      maxLines: 1,
                      decoration: InputTheme.of(context).copyWith(
                        labelText: 'Email',
                      ),
                      initialValue: _username,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Email is required';
                        }
                        final re = RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                        if (!re.hasMatch(value)) {
                          return 'Invalid format of Email';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _username = value.trim().toLowerCase();
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      autocorrect: false,
                      autofocus: false,
                      obscureText: true,
                      decoration: InputTheme.of(context).copyWith(
                        labelText: 'Password',
                      ),
                      initialValue: _password,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Password is too short';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _password = value;
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    RaisedButton(
                      child: Text(
                        'Create',
                      ),
                      onPressed: _signup,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        FlatButton(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          child: Text('Already Have Account?'),
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(
                                ScreenAccountSignin.routeName);
                          },
                        ),
                        FlatButton(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          child: Text(
                            'Don\'t Have Garadget?',
                          ),
                          onPressed: () {
                            canLaunch(LINK_BUY).then((ok) {
                              if (ok) {
                                launch(LINK_BUY);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: body,
      ),
    );
  }
}
