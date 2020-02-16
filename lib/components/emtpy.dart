import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    Key key,
    @required this.imagePath,
    @required this.headline,
    @required this.subhead,
  }) : super(key: key);

  final String imagePath;
  final String headline;
  final String subhead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 30.0,
                bottom: 15.0,
                left: 15.0,
                right: 15.0,
              ),
              child: Image(image: AssetImage(imagePath)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              headline,
              style: theme.textTheme.display1.copyWith(
                color: theme.accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            subhead,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.subhead.copyWith(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
