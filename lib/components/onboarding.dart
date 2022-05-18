import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../model/analytics.dart';
import '../model/settings.dart';
import 'accounts.dart';

class OnboardingPage extends StatelessWidget {
  OnboardingPage() {
    analytics.logOnboargding();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: 0);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white30,
        child: const Text('Skip'),
        onPressed: () {
          analytics.logSkippedOnboarding(fromPage: controller.page!);

          final settings = Provider.of<Settings>(context, listen: false);
          settings.isSkipped = true;
        },
      ),
      body: PageView(
        controller: controller,
        children: <Widget>[
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(30),
            child: WelcomePage(
              onPressed: () => controller.animateToPage(
                1,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              ),
            ),
          ),
          Container(
            color: Colors.amber[50],
            padding: EdgeInsets.all(50),
            child: Center(
              child: SizedBox(
                width: 400,
                child: AccountsForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  final void Function() onPressed;

  Flexible get arrowDown => const Flexible(
      flex: 1,
      child: Icon(
        Icons.arrow_downward,
        size: 60,
        color: Colors.amberAccent,
      ));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Expanded(
          flex: 8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Flexible(
                flex: 2,
                child: Image(
                  image: AssetImage('assets/discogs_logo_white.png'),
                ),
              ),
              arrowDown,
              Flexible(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      flex: 4,
                      child: SvgPicture.asset(
                        'assets/logo.svg',
                        color: Colors.amber,
                        height: 150,
                      ),
                    ),
                    const Flexible(
                      flex: 2,
                      child: Text(
                        'Scrobbler',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 38,
                          color: Colors.amber,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              arrowDown,
              const Flexible(
                flex: 2,
                child: Image(image: AssetImage('assets/lastfm_logo.png')),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.amberAccent),
              ),
              child: Text(
                'Get started',
                style: Theme.of(context).textTheme.headline6,
              ),
              onPressed: onPressed,
            ),
          ),
        ),
      ],
    );
  }
}
