import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import '../providers/account.dart';
import '../widgets/busy_message.dart';
import '../widgets/snackbar_message.dart';
import '../misc/input_decoration.dart';
import './account_signin.dart';

class ScreenLocalAuth extends StatefulWidget {
  static const routeName = "/account/auth";

  @override
  _ScreenLocalAuthState createState() => _ScreenLocalAuthState();
}

class _ScreenLocalAuthState extends State<ScreenLocalAuth> {
  final _formKey = GlobalKey<FormState>();
  bool _isFirstRun = true;
  bool _isPinObscured = true;

  AuthLevel _authLevel;
  AuthMethod _authMethod;
  String _pinCode;
  ProviderAccount _account;
  LocalAuthentication localAuth = LocalAuthentication();

  @override
  void didChangeDependencies() async {
    if (_isFirstRun) {
      _isFirstRun = false;
      _account = Provider.of<ProviderAccount>(context, listen: false);
      await _account.initStorage();
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: localAuth.getAvailableBiometrics(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return BusyScreen('Loading...');
        }
        List<BiometricType> availableBiometrics = snapshot.data;
        if (_authLevel == null && _account.authLevel != null) {
          _authLevel = _account.authLevel;
        }
        if (_authMethod == null) {
          if (_account.authMethod != null) {
            _authMethod = _account.authMethod;
          } else if (availableBiometrics.contains(BiometricType.face)) {
            _authMethod = AuthMethod.FACEID;
          } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
            _authMethod = AuthMethod.TOUCHID;
          } else {
            _authMethod = AuthMethod.PINCODE;
          }
        }

        final widgetList = <Widget>[
          const Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            child: Text(
                'You can enable a layer of protection by requiring additional authentication for logged in user.'),
          ),
          const SizedBox(
            height: 10,
          ),
          RadioTile(
            title: const Text('Always'),
            subtitle:
                const Text('Authenticate every time this app is accessed'),
            value: AuthLevel.ALWAYS,
            groupValue: _authLevel,
            onTap: _setAuthLevel,
          ),
          RadioTile(
            title: const Text('For Actions'),
            subtitle: const Text(
                'Authenticate when controlling the doors or changing settings'),
            value: AuthLevel.ACTIONS,
            groupValue: _authLevel,
            onTap: _setAuthLevel,
          ),
          RadioTile(
            title: const Text('Never'),
            subtitle: const Text('Do not require additional authentication'),
            value: AuthLevel.NEVER,
            groupValue: _authLevel,
            onTap: _setAuthLevel,
          ),
          const SizedBox(
            height: 10,
          ),
          const Divider(
            indent: 80,
            endIndent: 15,
          ),
        ];

        if (_authLevel != AuthLevel.NEVER) {
          if (availableBiometrics.contains(BiometricType.face)) {
            widgetList.add(
              RadioTile(
                title: const Text('FaceID'),
                value: AuthMethod.FACEID,
                groupValue: _authMethod,
                onTap: _setAuthMethod,
              ),
            );
          }
          if (availableBiometrics.contains(BiometricType.fingerprint)) {
            widgetList.add(
              RadioTile(
                title: const Text('Fingerprint'),
                value: AuthMethod.TOUCHID,
                groupValue: _authMethod,
                onTap: _setAuthMethod,
              ),
            );
          }
          widgetList.add(
            RadioTile(
              title: TextFormField(
                autocorrect: false,
                autofocus: false,
                obscureText: _isPinObscured,
                decoration: InputTheme.of(ctx).copyWith(
                  labelText: 'PIN Code',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPinObscured ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPinObscured = !_isPinObscured;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'PIN Code is required';
                  } else if (value.length < 4) {
                    return 'PIN Code is too short';
                  } else if (value.length > 10) {
                    return 'PIN Code is too long';
                  }
                  return null;
                },
                onChanged: (value) {
                  _pinCode = value;
                },
                onFieldSubmitted: (_) {
                  _formKey.currentState.validate();
                },
              ),
              value: AuthMethod.PINCODE,
              groupValue: _authMethod,
              onTap: _setAuthMethod,
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Authentication"),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                ),
                Builder(
                    // Create an inner BuildContext so that the onPressed methods
                    // can refer to the Scaffold with Scaffold.of().
                    builder: (ctx) {
                  return RaisedButton(
                    child: const Text('Save'),
                    onPressed: () {
                      if (_authMethod != AuthMethod.PINCODE) {
                        _pinCode = null;
                      } else if (!_formKey.currentState.validate()) {
                        return;
                      }
                      localAuthChallageDialog(ctx, AuthLevel.ACTIONS)
                          .then((allowed) {
                        if (!allowed) {
                          throw(false);
                        }
                        return Future.wait([
                          _account.setAuthLevel(_authLevel),
                          _account.setAuthMethod(_authMethod),
                          _account.setPinCode(_pinCode),
                        ]);
                      }).then((_) {
                        Navigator.of(ctx).pop(true);
                      }).catchError((_){});
                    },
                  );
                }),
              ],
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 15),
                children: widgetList,
              ),
            ),
          ),
        );
      },
    );
  }

  void _setAuthLevel(dynamic authLevel) {
    setState(() {
      _authLevel = authLevel as AuthLevel;
    });
  }

  void _setAuthMethod(dynamic authMethod) {
    setState(() {
      _authMethod = authMethod as AuthMethod;
    });
  }
}

class RadioTile extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final dynamic value;
  final dynamic groupValue;
  final Function onTap;

  RadioTile({
    this.title,
    this.subtitle,
    this.value,
    this.groupValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: ListTile(
        leading: Radio(
          value: value,
          groupValue: groupValue,
          onChanged: onTap,
        ),
        title: title,
        subtitle: subtitle,
      ),
      onTap: () {
        onTap(value);
      },
    );
  }
}

Future<bool> localAuthChallageDialog(
  BuildContext context,
  AuthLevel authLevel,
) async {
  final _account = Provider.of<ProviderAccount>(context, listen: false);
  if (_account.isLocalAuthNeeded(authLevel) == null) {
    return true;
  }

  try {
    bool successful = false;
    if (_account.authMethod == AuthMethod.FACEID ||
        _account.authMethod == AuthMethod.TOUCHID) {
      final localAuth = LocalAuthentication();
      successful = await localAuth.authenticateWithBiometrics(
        stickyAuth: true,
        localizedReason: 'Authenticate',
        useErrorDialogs: false,
      );
    } else if (_account.authMethod == AuthMethod.PINCODE) {
      successful = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return ScreenLocalAuthChallenge(null);
        },
      );
    } else {
      return true;
    }
    if (!successful) {
      throw(false);
    }
    _account.fulfillLocalAuth();
  } catch (error) {
    if (_account.authLevel == AuthLevel.ALWAYS) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).pushReplacementNamed(ScreenAccountSignin.routeName);
    }
    else if (error is PlatformException) {
      showSnackbarMessage(context, error.message, icon: Icons.fingerprint);
    }
    return false;
  }
  return true;
}

const MAX_ATTEMPTS = 3;

class ScreenLocalAuthChallenge extends StatefulWidget {
  final Function onComplete;
  ScreenLocalAuthChallenge(this.onComplete);

  @override
  _ScreenLocalAuthChallengeState createState() =>
      _ScreenLocalAuthChallengeState();
}

class _ScreenLocalAuthChallengeState extends State<ScreenLocalAuthChallenge> {
  ProviderAccount _account;
  final _formKey = GlobalKey<FormState>();
  String _pinCode;
  int attempts = 0;
  bool _isPinObscured = true;

  @override
  Widget build(BuildContext context) {
    _account = Provider.of<ProviderAccount>(context, listen: true);
    return AlertDialog(
      title: Text('Authenticate'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          autocorrect: false,
          autofocus: true,
          obscureText: _isPinObscured,
          decoration: InputTheme.of(context).copyWith(
            labelText: 'PIN Code',
            suffixIcon: IconButton(
              icon: Icon(
                _isPinObscured ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isPinObscured = !_isPinObscured;
                });
              },
            ),
          ),
          validator: (value) {
            if (value.isEmpty) {
              return 'PIN Code is required';
            }
            if (!_account.isPinCodeCorrect(value)) {
              if (attempts == 0) {
                attempts++;
                return 'PIN Code is incorrect';
              } else {
                attempts++;
                return 'Attempts left: ${MAX_ATTEMPTS - attempts + 1}';
              }
            }
            return null;
          },
          onChanged: (value) {
            _pinCode = value;
          },
          onFieldSubmitted: _onPinCode,
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text(
              _account.authLevel == AuthLevel.ALWAYS ? 'Sign Out' : 'Cancel'),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        RaisedButton(
          child: Text('Authenticate'),
          onPressed: () {
            _onPinCode(_pinCode);
          },
        )
      ],
    );
  }

  bool _onPinCode(value) {
    if (!_formKey.currentState.validate()) {
      if (attempts > MAX_ATTEMPTS) {
        Navigator.of(context).pop(false);
      }
      return false;
    }
    Navigator.of(context).pop(true);
    return true;
  }
}
