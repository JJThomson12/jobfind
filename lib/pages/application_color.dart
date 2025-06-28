import 'package:flutter/material.dart';

class AplicationColor with ChangeNotifier {
  bool _isLightBlue = true;

  bool get isLightBlue => _isLightBlue;
  set isLightBlue(bool value) {
    _isLightBlue = value;
    notifyListeners();
  }

  Color get color => _isLightBlue ? Colors.lightBlue : Colors.amber;
}
