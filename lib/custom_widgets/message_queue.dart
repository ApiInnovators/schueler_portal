import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:schueler_portal/globals.dart';

class MessageQueuer {
  static final List<String> _messageQueue = [];

  static void addMessageToQueue(String message, SnackBar snackBar) async {
    log("Adding $message: ${_messageQueue.contains(message)}");
    if (_messageQueue.contains(message)) {
      return;
    }

    _messageQueue.add(message);

    log("Snackbar current state: ${snackbarKey.currentState}");

    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 40));
      return snackbarKey.currentState == null;
    }).timeout(const Duration(seconds: 1));

    snackbarKey.currentState
        ?.showSnackBar(snackBar)
        .closed
        .then((value) => _messageQueue.remove(message));
  }
}
