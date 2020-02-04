// Define a custom Form widget.
import 'package:drs_app/model/lastfm.dart';
import 'package:drs_app/model/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountsForm extends StatefulWidget {
  @override
  AccountsMyCustomFormState createState() {
    return AccountsMyCustomFormState();
  }
}

class AccountsMyCustomFormState extends State<AccountsForm> {
  final _formKey = GlobalKey<FormState>();

  String _discogsUsername;
  String _lastfmUsername;
  String _lastfmPassword;

  bool _isSaving = false;

  final _lastfmUsernameController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _lastfmUsernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return FullHeightForm(
      formKey: _formKey,
      child: Consumer2<DiscogsSettings, LastfmSettings>(
        builder: (_, discogs, lastfm, __) {
          _lastfmUsernameController.text = lastfm.username; // initial value

          return IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Image(image: AssetImage('assets/discogs_logo.png')),
                      TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter your Discogs username';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Username',
                        ),
                        initialValue: discogs.username,
                        onSaved: (value) => _discogsUsername = value,
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Image(image: AssetImage('assets/lastfm_logo.png')),
                      TextFormField(
                        controller: _lastfmUsernameController,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter your Last.fm username';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Username',
                        ),
                        onSaved: (value) => _lastfmUsername = value,
                      ),
                      TextFormField(
                        obscureText: true,
                        validator: (value) {
                          if (value.isEmpty &&
                              _lastfmUsernameController.text !=
                                  lastfm.username) {
                            return 'Please enter your Last.fm password';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                        ),
                        initialValue: _lastfmPassword,
                        onSaved: (value) => _lastfmPassword = value,
                      ),
                      if (_isSaving) LinearProgressIndicator(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: FlatButton(
                      color: Colors.amberAccent,
                      child: Text('Save accounts'),
                      onPressed: (_isSaving)
                          ? null
                          : () async {
                              final form = _formKey.currentState;
                              // Validate returns true if the form is valid, otherwise false.
                              if (form.validate()) {
                                setState(() => _isSaving = true);

                                form.save();

                                discogs.username = _discogsUsername;
                                lastfm.username = _lastfmUsername;

                                final scrobbler = Provider.of<Scrobbler>(
                                    context,
                                    listen: false);

                                try {
                                  if (_lastfmPassword?.isNotEmpty ?? false) {
                                    final String sessionKey =
                                        await scrobbler.initializeSession(
                                            _lastfmUsername, _lastfmPassword);
                                    lastfm.sessionKey = sessionKey;
                                  }

                                  Scaffold.of(context).showSnackBar(SnackBar(
                                      content: Text(
                                          'Saved new account information.')));
                                } catch (e) {
                                  Scaffold.of(context).showSnackBar(SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red,
                                  ));
                                } finally {
                                  setState(() => _isSaving = false);
                                }
                              }
                            },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FullHeightForm extends StatelessWidget {
  final Widget child;
  final Key formKey;

  const FullHeightForm({Key key, this.child, this.formKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: LayoutBuilder(
          builder: (_, viewportConstraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
