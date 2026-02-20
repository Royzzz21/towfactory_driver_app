import 'package:flutter/material.dart';

import 'session_bloc.dart';

/// Listens to [SessionBloc] and notifies when session state changes.
/// Used as [GoRouter] refreshListenable so redirect runs on login/logout.
class SessionChangeNotifier extends ChangeNotifier {
  SessionChangeNotifier(SessionBloc sessionBloc) {
    sessionBloc.stream.listen((_) {
      notifyListeners();
    });
  }
}
