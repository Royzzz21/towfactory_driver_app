import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../core/utils/remember_me_storage.dart';
import '../../../presentation/bloc/session/session_bloc.dart';
import '../../../presentation/bloc/session/session_event.dart';
import '../../../presentation/bloc/session/session_state.dart';
import '../../bloc/login/login_bloc.dart';
import '../../bloc/login/login_event.dart';
import '../../bloc/login/login_state.dart';
import '../../../presentation/router/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final remember = await RememberMeStorage.getRememberMe();
    final email = await RememberMeStorage.getRememberedEmail();
    if (mounted) {
      setState(() {
        _rememberMe = remember;
        if (email != null && email.isNotEmpty) {
          _emailController.text = email;
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    context.read<LoginBloc>().add(
      SignWithEmailEvent(email: email, password: password),
    );
  }

  /// Maps API/network error messages to user-friendly text.
  static String _userFriendlyErrorMessage(String message) {
    final lower = message.toLowerCase();
    // API may return 201 Created on success; if old code showed it as error, don't show raw "Created"
    if (lower == 'created') {
      return 'Something went wrong. Please try again.';
    }
    if (lower.contains('unauthorized') ||
        lower.contains('401') ||
        lower.contains('invalid credentials') ||
        lower.contains('invalid email') ||
        lower.contains('wrong password')) {
      return 'Invalid email or password';
    }
    if (lower.contains('socket') ||
        lower.contains('connection') ||
        lower.contains('network') ||
        lower.contains('timed out')) {
      return 'Check your connection and try again';
    }
    if (lower.contains('server') || lower.contains('500') || lower.contains('503')) {
      return 'Something went wrong. Please try again later';
    }
    if (lower.contains('not found') || lower.contains('404')) {
      return 'Login service not available. Check that the server is running and the API URL is correct.';
    }
    return message.isNotEmpty ? message : 'Something went wrong';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
        listener: (BuildContext context, LoginState state) {
          if (state is LoginSuccess) {
            RememberMeStorage.saveRememberMe(
              remember: _rememberMe,
              email: _rememberMe ? _emailController.text.trim() : null,
            );
            context.read<SessionBloc>().add(SaveSessionEvent(state.user));
            ToastUtils.showSuccess(context, 'Successfully logged in');
          }
          if (state is LoginError && mounted) {
            final message = _userFriendlyErrorMessage(state.message);
            ToastUtils.showError(context, message);
          }
          if (state is LoginFormErrors && mounted) {
            final firstError = state.formErrors.values.isNotEmpty
                ? state.formErrors.values.first
                : 'Please check your entries';
            ToastUtils.showError(context, firstError);
          }
        },
        listenWhen: (LoginState previous, LoginState current) =>
            current is LoginSuccess || current is LoginError || current is LoginFormErrors,
        buildWhen: (LoginState previous, LoginState current) {
          if (current is LoginLoading) return true;
          if (current is LoginSuccess) return true; // Rebuild to clear loading spinner
          if (current is LoginError) return true; // Rebuild to stop loading on 401 etc.
          if (current is LoginFormErrors) return true;
          if (current is LoginInitial) return true;
          return false;
        },
        builder: (BuildContext context, LoginState state) {
          final isLoading = state is LoginLoading;
          final formErrors = state is LoginFormErrors ? state.formErrors : null;
          return BlocListener<SessionBloc, SessionState>(
            listenWhen: (SessionState previous, SessionState current) =>
                current is SessionAuthenticated,
            listener: (BuildContext context, SessionState sessionState) {
              if (sessionState is SessionAuthenticated && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  context.go(AppRoutes.home);
                });
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.backgroundDark,
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final screenHeight = constraints.maxHeight;
                    final screenWidth = constraints.maxWidth;
                    final isShortScreen = screenHeight < 600;
                    final horizontalPadding = screenWidth > 600 ? screenWidth * 0.15 : 24.0;
                    final logoHeight = isShortScreen ? screenHeight * 0.15 : screenHeight * 0.22;
                    final maxFormWidth = 480.0;

                    return Stack(
                      children: <Widget>[
                        SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            isShortScreen ? 16 : 24,
                            horizontalPadding,
                            100,
                          ),
                          physics: const ClampingScrollPhysics(),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxFormWidth),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Image.asset(
                                      'assets/images/logo.png',
                                      height: logoHeight.clamp(80.0, 200.0),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                    SizedBox(height: isShortScreen ? 12 : 24),
                                    Text(
                                      'Sign in to continue',
                                      textAlign: TextAlign.center,
                                      style: AppFontManager.bodyMedium(color: AppColors.textOnDark),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.textOnDark.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(28),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Icon(
                                              Icons.directions_car_outlined,
                                              size: 18,
                                              color: AppColors.textOnDark.withValues(alpha: 0.9),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Login as a driver',
                                              style: AppFontManager.bodyMedium(
                                                color: AppColors.textOnDark.withValues(alpha: 0.9),
                                              ).copyWith(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isShortScreen ? 24 : 48),
                                    AppTextField(
                                      label: 'Email',
                                      hint: 'you@example.com',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autocorrect: false,
                                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textOnDark),
                                      variant: AppTextFieldVariant.dark,
                                      errorText: formErrors?['email'] ?? formErrors?['Email'],
                                      validator: (String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      label: 'Password',
                                      controller: _passwordController,
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textOnDark),
                                      variant: AppTextFieldVariant.dark,
                                      errorText: formErrors?['password'] ?? formErrors?['Password'],
                                      validator: (String? value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter your password';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (bool? value) {
                                              setState(() => _rememberMe = value ?? false);
                                            },
                                            activeColor: AppColors.textOnDark,
                                            checkColor: AppColors.backgroundDark,
                                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                              if (states.contains(WidgetState.selected)) {
                                                return AppColors.textOnDark;
                                              }
                                              return AppColors.textOnDark.withValues(alpha: 0.5);
                                            }),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() => _rememberMe = !_rememberMe);
                                          },
                                          child: Text(
                                            'Remember me',
                                            style: AppFontManager.bodyMedium(
                                              color: AppColors.textOnDark.withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
                            color: AppColors.backgroundDark,
                            child: SafeArea(
                              top: false,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                                  child: AppButton(
                                    label: 'Sign in',
                                    onPressed: _submit,
                                    isLoading: isLoading,
                                    variant: AppButtonVariant.primary,
                                    backgroundColor: AppColors.textOnDark,
                                    foregroundColor: AppColors.backgroundDark,
                                    loadingColor: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
    );
  }
}
