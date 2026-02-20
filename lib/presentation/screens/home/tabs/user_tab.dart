import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/colors_manager.dart';
import '../../../../core/theme/font_manager.dart';
import '../../../../domain/core/api_exception.dart';
import '../../../../domain/entities/my_user.dart';
import '../../../../domain/usecases/get_user_details_usecase.dart';
import '../../../bloc/session/session_bloc.dart';
import '../../../bloc/session/session_event.dart';
import '../../../bloc/session/session_state.dart';

/// User tab: loads and displays current user details from /auth/me.
/// Fetches from API when the tab is first built and every time the user opens this tab.
class UserTab extends StatefulWidget {
  const UserTab({
    super.key,
    required this.isSelected,
    required this.tabIndex,
  });

  final bool isSelected;
  final int tabIndex;

  @override
  State<UserTab> createState() => _UserTabState();
}

class _UserTabState extends State<UserTab> {
  MyUser? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  @override
  void didUpdateWidget(UserTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch when user switches to this tab (so details are always fresh)
    if (widget.isSelected && !oldWidget.isSelected) {
      _loadUserDetails();
    }
  }

  Future<void> _loadUserDetails() async {
    final sessionBloc = context.read<SessionBloc>();
    final state = sessionBloc.state;
    if (state is! SessionAuthenticated) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    final token = state.user.token;
    setState(() {
      _loading = true;
      _error = null;
      _user = null;
    });
    try {
      final user = await sl<GetUserDetailsUsecase>().call(token);
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        // 401 Unauthorized: try refresh; if refresh fails, SessionBloc will auto-logout
        if (e is ApiException && e.statusCode == 401) {
          context.read<SessionBloc>().add(const HandleUnauthorized());
          return;
        }
        setState(() {
          _loading = false;
          _error = ApiException.cleanMessage(e);
          _user = state.user;
        });
      }
    }
  }

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Not recorded';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final local = d.isUtc ? d.toLocal() : d;
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = _user;
    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 48, color: AppColors.errorMuted),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Unable to load profile',
                textAlign: TextAlign.center,
                style: AppFontManager.bodyMedium(color: AppColors.errorMuted),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadUserDetails,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final hasActivity = (user.lastLogin != null && user.lastLogin!.isNotEmpty) ||
        (user.createdAt != null && user.createdAt!.isNotEmpty) ||
        (user.updatedAt != null && user.updatedAt!.isNotEmpty);

    return RefreshIndicator(
      onRefresh: _loadUserDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name.substring(0, 1).toUpperCase()
                          : user.email.isNotEmpty
                              ? user.email.substring(0, 1).toUpperCase()
                              : '?',
                      style: AppFontManager.titleLarge(
                        color: theme.colorScheme.onPrimary,
                      ).copyWith(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name.isNotEmpty ? user.name : 'Driver',
                    style: AppFontManager.titleLarge(
                      color: theme.colorScheme.onSurface,
                    ).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  if (user.userType != null && user.userType!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.userType!.toLowerCase().replaceRange(0, 1, user.userType!.substring(0, 1).toUpperCase()),
                        style: AppFontManager.bodyMedium(
                          color: theme.colorScheme.primary,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Contact & account section
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Contact & account',
                style: AppFontManager.bodyMedium(
                  color: AppColors.errorMuted,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ListTileRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  _ListTileRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: (user.phone != null && user.phone!.isNotEmpty)
                        ? user.phone!
                        : 'Not provided',
                  ),
                  _ListTileRow(
                    icon: user.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                    label: 'Status',
                    value: user.isActive ? 'Active' : 'Inactive',
                    valueHighlight: user.isActive,
                  ),
                ],
              ),
            ),
            if (hasActivity) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Activity',
                  style: AppFontManager.bodyMedium(
                    color: AppColors.errorMuted,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ListTileRow(
                      icon: Icons.login_rounded,
                      label: 'Last login',
                      value: _formatDate(user.lastLogin),
                    ),
                    _ListTileRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Member since',
                      value: _formatDate(user.createdAt),
                    ),
                    _ListTileRow(
                      icon: Icons.update_rounded,
                      label: 'Profile updated',
                      value: _formatDate(user.updatedAt),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListTileRow extends StatelessWidget {
  const _ListTileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueHighlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool valueHighlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.errorMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFontManager.bodyMedium(color: AppColors.errorMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppFontManager.bodyMedium(
                    color: valueHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ).copyWith(
                    fontWeight: valueHighlight ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
