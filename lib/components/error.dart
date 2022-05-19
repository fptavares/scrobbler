import 'dart:async';
import 'dart:io';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:scrobbler/main.dart';

import '../model/analytics.dart';

void displayAndLogError(Logger logger, Object e, StackTrace stackTrace, [String? message]) {
  final errorMessage = e is UIException
      ? e.message
      : message ??
          (e is SocketException && e.address != null
              ? 'Could not connect to ${e.address!.host} (${e.message})'
              : e.toString());

  if (e is! UIException) {
    logger.severe(errorMessage, e, stackTrace);
  } else if (e.exception != null) {
    logger.warning(errorMessage, e.exception, stackTrace);
  }

  displayError(errorMessage);
}

void displayError(String errorMessage) {
  final scaffoldMsg = ScrobblerApp.scaffoldMessengerKey.currentState;
  scaffoldMsg?.removeCurrentSnackBar();
  scaffoldMsg?.showSnackBar(SnackBar(
    content: Text(errorMessage),
    backgroundColor: Colors.red,
  ));
}

void displaySuccess(String message) {
  ScrobblerApp.scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: Colors.green,
  ));
}

Future<T?> handleFutureError<T>(Future<T> future, Logger logger,
    {String? error, String? success, String? trace}) async {
  Trace? callTrace;
  if (trace != null) {
    callTrace = analytics.newTrace(trace);
    callTrace.start();
  }

  try {
    final result = await future;
    if (success != null) {
      displaySuccess(success);
    }
    return result;
  } on Exception catch (e, stackTrace) {
    displayAndLogError(logger, e, stackTrace, error);
  } finally {
    callTrace?.stop();
  }
  return Future<T?>.value(null);
}

class UIException implements Exception {
  UIException(this.message, [this.exception]);

  final String message;
  final Object? exception;

  @override
  String toString() => message;
}
