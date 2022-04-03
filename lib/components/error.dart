import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../model/analytics.dart';

void displayAndLogError(BuildContext context, Logger logger, Object e, StackTrace stackTrace, [String message]) {
  final log = logger ?? Logger.root;
  final errorMessage = e is UIException ? e.message : message ?? e.toString();

  if (e is! UIException) {
    log.severe(errorMessage, e, stackTrace);
  } else if (e is UIException && e.exception != null) {
    log.warning(errorMessage, e.exception, stackTrace);
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
  String trace,
}) async {
  Trace callTrace;
  if (trace != null) {
    callTrace = analytics.newTrace(trace);
    callTrace.start();
  }

  try {
    final result = await future;
    if (success != null) {
      displaySuccess(context, success);
    }
    return result;
  } on Exception catch (e, stackTrace) {
    displayAndLogError(context, logger, e, stackTrace, error);
  } finally {
    callTrace?.stop();
  }
  return Future<T>.value(null);
}

class UIException implements Exception {
  UIException(this.message, [this.exception]);

  final String message;
  final Object exception;

  @override
  String toString() => message ?? exception?.toString() ?? 'UIException';
}
