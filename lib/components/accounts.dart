import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../model/lastfm.dart';
import '../model/settings.dart';
import 'error.dart';

class AccountsForm extends StatefulWidget {
  @override
  AccountsMyCustomFormState createState() {
    return AccountsMyCustomFormState();
  }
}

class AccountsMyCustomFormState extends State<AccountsForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final Logger log = Logger('AccountsForm');

  String _discogsUsername;
  String _lastfmUsername;
  String _lastfmPassword;

  bool _isSaving = false;

  final TextEditingController _lastfmUsernameController =
      TextEditingController();

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
                      const Image(image: AssetImage('assets/discogs_logo.png')),
                      TextFormField(
                        validator: (value) => value.isEmpty
                            ? 'Please enter your Discogs username'
                            : null,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                        initialValue: discogs.username,
                        onSaved: (value) => _discogsUsername = value,
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      const Image(image: AssetImage('assets/lastfm_logo.png')),
                      TextFormField(
                        controller: _lastfmUsernameController,
                        validator: (value) => value.isEmpty
                            ? 'Please enter your Last.fm username'
                            : null,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            const InputDecoration(labelText: 'Username'),
                        onSaved: (value) => _lastfmUsername = value,
                      ),
                      TextFormField(
                        obscureText: true,
                        validator: (value) => (value.isEmpty &&
                                _lastfmUsernameController.text !=
                                    lastfm.username)
                            ? 'Please enter your Last.fm password'
                            : null,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        initialValue: _lastfmPassword,
                        onSaved: (value) => _lastfmPassword = value,
                      ),
                      if (_isSaving) const LinearProgressIndicator(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: FlatButton(
                      color: Colors.amberAccent,
                      child: const Text('Save accounts'),
                      onPressed:
                          _isSaving ? null : () => handleSave(discogs, lastfm),
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

  Future<void> handleSave(
      DiscogsSettings discogs, LastfmSettings lastfm) async {
    final form = _formKey.currentState;
    // Validate returns true if the form is valid, otherwise false.
    if (form.validate()) {
      setState(() => _isSaving = true);

      form.save();

      discogs.username = _discogsUsername;
      lastfm.username = _lastfmUsername;

      final scrobbler = Provider.of<Scrobbler>(context, listen: false);

      try {
        if (_lastfmPassword?.isNotEmpty ?? false) {
          final sessionKey = await scrobbler.initializeSession(
              _lastfmUsername, _lastfmPassword);
          lastfm.sessionKey = sessionKey;
        }

        displaySuccess(context, 'Saved new account information.');
      } on Exception catch (e, stackTrace) {
        displayAndLogError(context, log, e, stackTrace);
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }
}

class FullHeightForm extends StatelessWidget {
  const FullHeightForm({Key key, this.child, this.formKey}) : super(key: key);

  final Widget child;
  final Key formKey;

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
