import 'package:flutter/material.dart';

/// Search field state for the dashboard.
class FerretDashboardSearch {
  final controller = TextEditingController();
  final focus = FocusNode();
  bool open = false;

  void dispose() {
    controller.dispose();
    focus.dispose();
  }

  void toggle(void Function() refresh) {
    open = !open;
    refresh();
    if (open) {
      WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
    } else {
      focus.unfocus();
    }
  }
}
