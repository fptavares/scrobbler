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

// Define a corresponding State class.
// This class holds data related to the form.
class AccountsMyCustomFormState extends State<AccountsForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  String _discogsUsername;
  String _lastfmUsername;
  String _lastfmPassword;

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 30.0),
        child: Consumer2<DiscogsSettings, LastfmSettings>(
          builder: (_, discogs, lastfm, __) => Column(
            children: <Widget>[
              // Add TextFormFields and RaisedButton here.
              Image(image: AssetImage('assets/discogs_logo.png')),
              TextFormField(
                // The validator receives the text that the user has entered.
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter your Discogs username';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Username',
                ),
                initialValue: discogs.username,
                onSaved: (value) => _discogsUsername = value,
              ),
              SizedBox(height: 50),
              Image(image: AssetImage('assets/lastfm_logo.png')),
              TextFormField(
                // The validator receives the text that the user has entered.
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
                initialValue: lastfm.username,
                onSaved: (value) => _lastfmUsername = value,
              ),
              TextFormField(
                // The validator receives the text that the user has entered.
                obscureText: true,
                validator: (value) {
                  if (value.isEmpty) {
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
              if (_isSaving)
                LinearProgressIndicator(),
              SizedBox(height: 20),
              if (!_isSaving)
                OutlineButton(
                  onPressed: () async {
                    final form = _formKey.currentState;
                    // Validate returns true if the form is valid, otherwise false.
                    if (form.validate()) {
                      setState(() => _isSaving = true);

                      form.save();

                      discogs.username = _discogsUsername;
                      lastfm.username = _lastfmUsername;

                      final scrobbler =
                          Provider.of<Scrobbler>(context, listen: false);

                      try {
                        final String sessionKey =
                            await scrobbler.initializeSession(
                                _lastfmUsername, _lastfmPassword);
                        lastfm.sessionKey = sessionKey;

                        Scaffold.of(context).showSnackBar(SnackBar(
                            content: Text('Saved new account information.')));
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
                  child: Text('Save'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
