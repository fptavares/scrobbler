import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../model/analytics.dart';
import '../model/lastfm.dart';
import '../model/settings.dart';
import 'error.dart';

class AccountsForm extends StatefulWidget {
  @override
  AccountsMyCustomFormState createState() {
    return AccountsMyCustomFormState();
  }

  static const discogsUsernameFieldKey = Key('discogs_username');
  static const lastfmUsernameFieldKey = Key('lastfm_username');
  static const lastfmPasswordFieldKey = Key('lastfm_password');

  static const discogsInvalidUsernameMessage =
      'Please enter your Discogs username';
  static const lastfmInvalidUsernameMessage =
      'Please enter your Last.fm username';
  static const lastfmInvalidPasswordMessage =
      'Please enter your Last.fm password';

  static const saveSuccessMessage = 'Saved new account information.';
}

class AccountsMyCustomFormState extends State<AccountsForm> {
  final _formKey = GlobalKey<FormState>();

  final Logger log = Logger('AccountsForm');

  String _discogsUsername;
  String _lastfmUsername;
  String _lastfmPassword;

  bool _isSaving = false;

  final TextEditingController _lastfmUsernameController =
      TextEditingController();

  @override
  void initState() {
    analytics.logAccountSettingsOpen();
    super.initState();
  }

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
                      const Image(
                        image: AssetImage('assets/discogs_logo.png'),
                        semanticLabel: 'Discogs',
                      ),
                      TextFormField(
                        key: AccountsForm.discogsUsernameFieldKey,
                        validator: (value) => value.isEmpty
                            ? AccountsForm.discogsInvalidUsernameMessage
                            : null,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Discogs Username',
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
                      const Image(
                        image: AssetImage('assets/lastfm_logo.png'),
                        semanticLabel: 'Last.fm',
                      ),
                      TextFormField(
                        key: AccountsForm.lastfmUsernameFieldKey,
                        controller: _lastfmUsernameController,
                        validator: (value) => value.isEmpty
                            ? AccountsForm.lastfmInvalidUsernameMessage
                            : null,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            const InputDecoration(labelText: 'Last.fm Username'),
                        onSaved: (value) => _lastfmUsername = value,
                      ),
                      TextFormField(
                        key: AccountsForm.lastfmPasswordFieldKey,
                        obscureText: true,
                        validator: (value) => (value.isEmpty &&
                                _lastfmUsernameController.text !=
                                    lastfm.username)
                            ? AccountsForm.lastfmInvalidPasswordMessage
                            : null,
                        decoration:
                            const InputDecoration(labelText: 'Last.fm Password'),
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
                      onPressed: _isSaving
                          ? null
                          : () async => await _handleSave(discogs, lastfm),
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

  Future<void> _handleSave(
      DiscogsSettings discogs, LastfmSettings lastfm) async {
    final form = _formKey.currentState;
    // Validate returns true if the form is valid, otherwise false.
    if (form.validate()) {
      setState(() => _isSaving = true);

      form.save();

      if (discogs.username != _discogsUsername) {
        analytics.logLogin(loginMethod: 'discogs');
      }

      discogs.username = _discogsUsername;
      lastfm.username = _lastfmUsername;

      if (_lastfmPassword?.isNotEmpty ?? false) {
        analytics.logLogin(loginMethod: 'lastfm');

        final scrobbler = Provider.of<Scrobbler>(context, listen: false);

        lastfm.sessionKey = await handleFutureError(
            scrobbler.initializeSession(_lastfmUsername, _lastfmPassword),
            context,
            log,
            success: AccountsForm.saveSuccessMessage,
            trace: 'init_lastfm_session');
      } else {
        displaySuccess(context, AccountsForm.saveSuccessMessage);
      }

      setState(() => _isSaving = false);
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
      child: LayoutBuilder(
        builder: (_, viewportConstraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
