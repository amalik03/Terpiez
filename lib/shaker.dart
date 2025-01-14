import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

class Shaker extends ChangeNotifier {
  late StreamSubscription<UserAccelerometerEvent> _streamSubscription;
  bool _isShaking = false;
  bool get isShaking => _isShaking;
  double? accel;

  Shaker() {
    _streamSubscription = userAccelerometerEventStream().listen((event) {
      double accel =
          ((event.x * event.x) + (event.y * event.y) + (event.z * event.z));
      if (sqrt(accel) >= 10.0 && _isShaking == false) {
        _isShaking = true;
        notifyListeners();
      } else if (_isShaking == true) {
        _isShaking = false;
        notifyListeners();
      }
    });
  }
  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}
