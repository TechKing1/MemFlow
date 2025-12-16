import 'package:flutter/material.dart';

class LandingViewModel extends ChangeNotifier {
  final VoidCallback onContinuePressed;

  LandingViewModel({required this.onContinuePressed});

  void handleContinue() {
    onContinuePressed();
  }
}
