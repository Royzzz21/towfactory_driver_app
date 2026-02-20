import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../presentation/bloc/session/session_bloc.dart';
import '../../../presentation/bloc/session/session_state.dart';
import '../../../presentation/router/app_router.dart';

/// Splash screen shown on app start. Waits for session check then navigates to home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _minDisplayDuration = Duration(milliseconds: 1500);
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(_minDisplayDuration, () {
      if (!mounted) return;
      setState(() => _minTimeElapsed = true);
      if (mounted) _maybeNavigate(context.read<SessionBloc>().state);
    });
  }

  void _maybeNavigate(SessionState sessionState) {
    if (!mounted || !_minTimeElapsed) return;
    if (sessionState is SessionInitial) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listener: (BuildContext context, SessionState state) {
        _maybeNavigate(state);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.png',
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                    'DRIVER APP',
                    style: AppFontManager.titleLarge(color: AppColors.textOnDark),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnDark.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
