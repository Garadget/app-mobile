import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './account_signup.dart';
import './account_signin.dart';
import '../providers/account.dart';
import '../widgets/busy_message.dart';
import '../widgets/network_error.dart';
import '../widgets/bottom_bar_button.dart';
import '../widgets/form_logo.dart';

class ScreenAccountReset extends StatefulWidget {
  static const routeName = "/account/reset";

  @override
  _ScreenAccountResetState createState() => _ScreenAccountResetState();
}

class _ScreenAccountResetState extends State<ScreenAccountReset> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFirstRun = true;
  String _errorMessage;
  ProviderAccount _account;
  String _username;

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
        _username = _account.accountEmail;
      });
    }
    super.didChangeDependencies();
  }

  void _reset() async {
    if (!_formKey.currentState.validate()) {
      return null;
    }
    await showBusyMessage(context, 'Processing...');
    String message;
    await tryNetwork(
      () {
        return _account.resetPassword(_username);
      },
      onError: (error) {
        message = error;
      },
      onRetry: () => false,
    );
    Navigator.of(context).pop();

    if (message != null) {
      showNetworkErrorDialog(context, message);
      return;
    }

    await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Password Reset'),
            content: Text(
                'If the email address you entered exists in our system, we have sent a message containing the reset link.'),
            actions: <Widget>[
              RaisedButton(
                child: Text('Back to Login'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              )
            ],
          );
        });
    Navigator.of(context).pushReplacementNamed(ScreenAccountSignin.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final inputNormalBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).primaryColor,
        width: 1.0,
      ),
    );
    final inputErrorBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).errorColor,
        width: 1.0,
      ),
    );

    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
      enabledBorder: inputNormalBorder,
      focusedBorder: inputNormalBorder,
      errorBorder: inputErrorBorder,
      focusedErrorBorder: inputErrorBorder,
      hasFloatingPlaceholder: true,
    );

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
                    Text(
                      'Password Reset',
                      style: Theme.of(context).textTheme.title,
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    TextFormField(
                      autocorrect: false,
                      autofocus: accountEmail == null,
                      keyboardType: TextInputType.emailAddress,
                      maxLines: 1,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Email',
                      ),
                      initialValue: accountEmail,
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
                        _username = value.toLowerCase();
                      },
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    RaisedButton(
                      child: Text(
                        'Initiate',
                      ),
                      onPressed: _reset,
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
      body: SafeArea(
        child: body,
      ),
      bottomNavigationBar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox.shrink(),
          BottomBarButton(
            'Existing Account',
            () {
              Navigator.of(context)
                  .pushReplacementNamed(ScreenAccountSignin.routeName);
            },
          ),
          BottomBarButton(
            'Create Account',
            () {
              Navigator.of(context)
                  .pushReplacementNamed(ScreenAccountSignup.routeName);
            },
          ),
        ],
      ),
    );
  }
}
