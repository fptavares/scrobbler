import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    Key? key,
    required this.imagePath,
    this.headline,
    this.subhead,
  }) : super(key: key);

  final String imagePath;
  final String? headline;
  final String? subhead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 30.0, bottom: 15.0, left: 30.0, right: 30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              flex: 10,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Image(image: AssetImage(imagePath)),
              ),
            ),
            if (headline != null) const Flexible(flex: 1, child: SizedBox(height: 23.0)),
            if (headline != null)
              Text(
                headline!,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium!.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (subhead != null) const Flexible(flex: 1, child: SizedBox(height: 8.0)),
            if (subhead != null)
              Text(
                subhead!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }
}
