import 'package:drs_app/components/accounts.dart';
import 'package:drs_app/model/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatelessWidget {
  final arrowDown = Flexible(flex: 1, child: Icon(
    Icons.arrow_downward,
    size: 60,
    color: Colors.amberAccent,
  ));

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: 0);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white30,
        //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
        child: Text('Skip'),
        onPressed: () {
          final settings = Provider.of<DiscogsSettings>(context, listen: false);
          settings.skipped = true;
        },
      ),
      //floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: PageView(
        controller: controller,
        children: <Widget>[
          Container(
            color: Theme.of(context).primaryColor,
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Expanded(
                  flex: 8,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        flex: 2,
                          child: Image(
                              image:
                                  AssetImage('assets/discogs_logo_white.png'))),
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
                                //Theme.of(context).primaryColor,
                                height: 150,
                              ),
                            ),
                            Flexible(
                              flex: 2,
                              child: Text('Record Scrobbler',
                                  style: TextStyle(
                                    fontFamily: 'OpenSans',
                                    fontSize: 38,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w400,
                                  )),
                            ),
                          ],
                        ),
                      ),
                      arrowDown,
                      Flexible(flex: 2,child: Image(image: AssetImage('assets/lastfm_logo.png'))),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: FlatButton(
                      color: Colors.amberAccent,
                      child: Text(
                        'Get started',
                        style: Theme.of(context).textTheme.title,
                      ),
                      onPressed: () => controller.animateToPage(
                        1,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.amber[50],
            child: AccountsForm(),
          ),
        ],
      ),
    );
  }
}
