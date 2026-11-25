import 'package:flutter/foundation.dart';

class SyncStatusService {
  static final ValueNotifier<bool> isSynced = ValueNotifier<bool>(true);

  static void setSynced(bool synced) {
    if (isSynced.value != synced) {
      isSynced.value = synced;
    }
  }
}
