import 'package:flutter/foundation.dart';

class KioskModeProvider extends ChangeNotifier {
  bool _isKioskModeEnabled = false;

  bool get isKioskModeEnabled => _isKioskModeEnabled;

  void enableKioskMode() {
    _isKioskModeEnabled = true;
    notifyListeners();
  }

  void disableKioskMode() {
    _isKioskModeEnabled = false;
    notifyListeners();
  }

  void updateKioskModeStatus(bool isEnabled) {
    _isKioskModeEnabled = isEnabled;
    notifyListeners();
  }
}
