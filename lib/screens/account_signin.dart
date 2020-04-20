import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './account_signup.dart';
import './account_reset.dart';

import '../providers/account.dart';
import '../misc/input_decoration.dart';
import '../widgets/busy_message.dart';
import '../widgets/network_error.dart';
import '../widgets/form_logo.dart';
import './home.dart';

class ScreenAccountSignin extends StatefulWidget {
  static const routeName = '/account/signin';

  @override
  _ScreenAccountSigninState createState() => _ScreenAccountSigninState();
}

class _ScreenAccountSigninState extends State<ScreenAccountSignin> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFirstRun = true;
  String _errorMessage;
  ProviderAccount _account;
  String _username;
  String _password;

  @override
  void setState(function) {
    if (mounted) {
      super.setState(function);
    }
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

      _username = _account.accountEmail;
      _password = '';
    }
    super.didChangeDependencies();
  }

  void _signin() async {
    if (!_formKey.currentState.validate()) {
      return null;
    }
    await showBusyMessage(context, 'Logging In...');
    String message;
    await tryNetwork(
      () {
        return _account.login(_username, _password);
      },
      onError: (error) {
        message = error;
      },
      onRetry: () => false,
    );
    Navigator.of(context).pop();
    if (message == null) {
      Navigator.of(context).pushReplacementNamed(ScreenHome.routeName);
    } else {
      showNetworkErrorDialog(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0 ||
        MediaQuery.of(context).size.height < 400;

    final accountEmail = _account.accountEmail;

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
                      initialValue: accountEmail,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Email is required';
                        }
                        final re = RegExp(
                            r"^[a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.]+\.[a-zA-Z]+");
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
                      autofocus: accountEmail != null,
                      obscureText: true,
                      decoration: InputTheme.of(context).copyWith(
                        labelText: 'Password',
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Password is required';
                        }
//                          if (value.length < 8) {
//                            return 'Password is too short';
//                          }
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
                        'Login',
                      ),
                      onPressed: _signin,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        FlatButton(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          child: Text('Don\'t have Account?'),
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(
                                ScreenAccountSignup.routeName);
                          },
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        FlatButton(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          child: Text(
                            'Forgot Password?',
                          ),
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(
                                ScreenAccountReset.routeName);
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
        title: const Text('Account Login'),
      ),
      body: SafeArea(child: body),
    );
  }

  @override
  void deactivate() {
    _isFirstRun = true;
    super.deactivate();
  }

}
