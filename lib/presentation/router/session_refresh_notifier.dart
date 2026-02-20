import 'package:flutter/material.dart';

/// Notifier used to refresh the router when session changes (login/logout).
class SessionRefreshNotifier extends ChangeNotifier {
  /// Call after session is set or cleared so the router re-runs redirect.
  void refresh() => notifyListeners();
}
