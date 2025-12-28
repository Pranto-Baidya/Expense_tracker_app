import 'package:flutter/material.dart';

class SearchCallbackHelper {
  static BuildContext? _context;

  static void register(BuildContext context) {
    _context = context;
  }

  static void clear() {
    _context = null;
  }

  static BuildContext? get context => _context;
}