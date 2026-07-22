import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void selectIndex(int index) {
    if (index == _currentIndex) {
      return;
    }

    _currentIndex = index;
    notifyListeners();
  }
}
