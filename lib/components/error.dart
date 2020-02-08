import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

void displayAndLogError(
    BuildContext context, Logger logger, Object e, StackTrace stackTrace,
    [String message]) {
  final log = logger ?? Logger.root;
  final errorMessage = e is UIException ? e.message : message ?? e.toString();

  if (e is! UIException) {
    log.severe(errorMessage, e, stackTrace);
  } else if (e is UIException && e.exception != null) {
    log.severe(errorMessage, e.exception, stackTrace);
  }

  final scaffold = Scaffold.of(context);
  scaffold.removeCurrentSnackBar();
  scaffold.showSnackBar(SnackBar(
    content: Text(errorMessage),
    backgroundColor: Colors.red,
  ));
}

void displaySuccess(BuildContext context, String message) {
  Scaffold.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: Colors.green,
  ));
}

Future<T> handleFutureError<T>(
  Future<T> future,
  BuildContext context,
  Logger logger, {
  String error,
  String success,
}) async {
  try {
    final result = await future;
    if (success != null) {
      displaySuccess(context, success);
    }
    return result;
  } on Exception catch (e, stackTrace) {
    displayAndLogError(context, logger, e, stackTrace, error);
  }
  return Future<T>.value(null);
}

class UIException implements Exception {
  UIException(this.message, [this.exception]);

  final String message;
  final Object exception;

  @override
  String toString() => message ?? 'Something went wrong.';
}
