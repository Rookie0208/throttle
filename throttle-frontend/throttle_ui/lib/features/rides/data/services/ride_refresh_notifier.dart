import 'package:flutter/foundation.dart';

class RideRefreshNotifier {
  RideRefreshNotifier._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void notify() {
    revision.value++;
  }
}
