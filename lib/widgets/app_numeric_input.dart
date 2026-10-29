import 'package:flutter/services.dart';

/// Keeps numeric inputs numeric even when hardware keyboards or paste are used.
class AppNumericInput {
  static final digits = FilteringTextInputFormatter.digitsOnly;
  static final decimal = TextInputFormatter.withFunction((oldValue, next) {
    return RegExp(r'^\d*(?:\.\d*)?$').hasMatch(next.text) ? next : oldValue;
  });
}
