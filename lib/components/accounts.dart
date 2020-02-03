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
    return FullHeightForm(
      formKey: _formKey,
      child: Consumer2<DiscogsSettings, LastfmSettings>(
        builder: (_, discogs, lastfm, __) => IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Add TextFormFields and RaisedButton here.
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Image(image: AssetImage('assets/discogs_logo.png')),
                    TextFormField(
                      // The validator receives the text that the user has entered.
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
                    if (_isSaving) LinearProgressIndicator(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              //if (!_isSaving)
              Expanded(
                flex: 2,
                child: Center(
                  child: FlatButton(
                    color: Colors.amberAccent,
                    child: Text(
                      'Save accounts',
                      /*style: Theme.of(context).textTheme.title*/
                    ),
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
                  ),
                ),
              ),
            ],
          ),
        ),
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
