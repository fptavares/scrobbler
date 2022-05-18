import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const bluosMonitorFieldKey = Key('bluos_monitor_address');

  static const discogsInvalidUsernameMessage = 'Please enter your Discogs username';
  static const lastfmInvalidUsernameMessage = 'Please enter your Last.fm username';
  static const lastfmInvalidPasswordMessage = 'Please enter your Last.fm password';
  static const bluosInvalidAddressMessage = 'Must be a valid hostname or IP address';

  static const saveSuccessMessage = 'Saved new account information.';
}

class AccountsMyCustomFormState extends State<AccountsForm> {
  final _formKey = GlobalKey<FormState>();

  final Logger log = Logger('AccountsForm');

  String? _discogsUsername;
  String? _lastfmUsername;
  String? _lastfmPassword;
  String? _bluosMonitorAddress;

  bool _isSaving = false;

  final TextEditingController _lastfmUsernameController = TextEditingController();

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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Consumer<Settings>(
            builder: (_, settings, __) {
              _lastfmUsernameController.text = settings.lastfmUsername ?? ''; // initial value

              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Image(
                    image: AssetImage('assets/discogs_logo.png'),
                    semanticLabel: 'Discogs',
                  ),
                  TextFormField(
                    key: AccountsForm.discogsUsernameFieldKey,
                    //validator: (value) => value!.isEmpty ? AccountsForm.discogsInvalidUsernameMessage : null,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Discogs Username',
                    ),
                    initialValue: settings.discogsUsername,
                    onSaved: (value) => _discogsUsername = value,
                  ),
                  const SizedBox(height: 40),
                  const Image(
                    image: AssetImage('assets/lastfm_logo.png'),
                    semanticLabel: 'Last.fm',
                  ),
                  TextFormField(
                    key: AccountsForm.lastfmUsernameFieldKey,
                    controller: _lastfmUsernameController,
                    validator: (value) => value!.isEmpty ? AccountsForm.lastfmInvalidUsernameMessage : null,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Last.fm Username'),
                    onSaved: (value) => _lastfmUsername = value,
                  ),
                  TextFormField(
                    key: AccountsForm.lastfmPasswordFieldKey,
                    obscureText: true,
                    validator: (value) => (value!.isEmpty && _lastfmUsernameController.text != settings.lastfmUsername)
                        ? AccountsForm.lastfmInvalidPasswordMessage
                        : null,
                    decoration: const InputDecoration(labelText: 'Last.fm Password'),
                    initialValue: _lastfmPassword,
                    onSaved: (value) => _lastfmPassword = value,
                  ),
                  if (_isSaving) const LinearProgressIndicator(),
                  const SizedBox(height: 40),
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.all(0),
                    title: const Image(
                      image: AssetImage('assets/bluos_logo.png'),
                      semanticLabel: 'BluOS',
                    ),
                    value: settings.isScrobblingBluOS,
                    onChanged: (value) => settings.isScrobblingBluOS = value!,
                  ),
                  if (settings.isScrobblingBluOS)
                    TextFormField(
                      key: AccountsForm.bluosMonitorFieldKey,
                      keyboardType: TextInputType.url,
                      validator: (value) => _validateAddress(value) ? null : AccountsForm.bluosInvalidAddressMessage,
                      decoration: const InputDecoration(
                        labelText: 'BluOS monitor address',
                        helperText: 'Leave empty if not using an external server to monitor BluOS players',
                        helperMaxLines: 3,
                        hintText: '[Hostname/IP]:[Port]',
                      ),
                      initialValue: settings.bluOSMonitorAddress,
                      onSaved: (value) => _bluosMonitorAddress = value,
                    ),
                  if (settings.isScrobblingBluOS)
                    TextButton.icon(
                      icon: const Icon(Icons.help),
                      label: const Text('More about BluOS monitor'),
                      onPressed: () => _showMoreAboutMonitor(context),
                    ),
                  const SizedBox(height: 40),
                  Center(
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.amberAccent),
                      ),
                      child: const Text('Save accounts'),
                      onPressed: _isSaving ? null : () async => await _handleSave(settings),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  _showMoreAboutMonitor(BuildContext context) async {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Monitoring BluOS players'),
          content: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  text:
                      'Unfortunately, the app by itself can only monitor what\'s being played on another device while the app is open.\n\n'
                      'To monitor tracks played even if the app is in the background, or closed, you need to run a separate server that will monitor the BluOS player independetly of this application.\n\n'
                      'For more information, and instructions on how to install this, please go to ',
                ),
                TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue,
                      ),
                  text: 'github.com/fptavares/scrobbler/pkgs/bluos-monitor',
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final url = Uri.https('github.com', '/fptavares/scrobbler/pkgs/bluos-monitor');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                ),
                const TextSpan(
                  text: '.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSave(Settings settings) async {
    final form = _formKey.currentState!;
    // Validate returns true if the form is valid, otherwise false.
    if (form.validate()) {
      setState(() => _isSaving = true);

      form.save();

      settings.bluOSMonitorAddress = _bluosMonitorAddress;

      if (settings.discogsUsername != _discogsUsername) {
        settings.discogsUsername = _discogsUsername;
        analytics.logLogin(loginMethod: 'discogs');
      }

      settings.lastfmUsername = _lastfmUsername;

      if (_lastfmPassword?.isNotEmpty ?? false) {
        analytics.logLogin(loginMethod: 'lastfm');

        final scrobbler = Provider.of<Scrobbler>(context, listen: false);

        settings.lastfmSessionKey = await handleFutureError(
            scrobbler.initializeSession(_lastfmUsername!, _lastfmPassword!), context, log,
            success: AccountsForm.saveSuccessMessage, trace: 'init_lastfm_session');
      } else {
        displaySuccess(context, AccountsForm.saveSuccessMessage);
      }

      setState(() => _isSaving = false);
    }
  }

  bool _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return true;
    }
    final matcher = RegExp(r'^[\w\d\-\.\:]+$');
    return matcher.hasMatch(value);
  }
}
