@JS()
import 'dart:async';

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('captureFlutterApp')
external dynamic _captureFlutterApp();

Future<String> captureFlutterApp() async {
  try {
    final jsPromise = _captureFlutterApp();
    final result = await promiseToFuture<String>(jsPromise);
    return result;
  } catch (e) {
    rethrow;
  }
}
