import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/colors_manager.dart';
import '../../../core/theme/font_manager.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../router/app_router.dart';
import '../../bloc/booking/booking_bloc.dart';
import '../../bloc/booking/booking_event.dart';
import '../../bloc/booking/booking_state.dart';
import '../../bloc/session/session_bloc.dart';
import '../../bloc/session/session_state.dart';

/// Full details for a single booking. Receives [Booking] via route [extra].
class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({
    super.key,
    required this.booking,
  });

  final Booking booking;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _isCustomerOnline = false;
  /// Updated from bloc when status update succeeds and list is refetched.
  Booking? _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _checkOnlineStatus();
  }

  Future<void> _checkOnlineStatus() async {
    if (widget.booking.id.isEmpty) return;
    try {
      final chatRepo = sl<ChatRepository>();
      final isOnline = await chatRepo.isCustomerOnline(widget.booking.id);
      if (mounted) {
        setState(() => _isCustomerOnline = isOnline);
      }
    } catch (_) {
      // Ignore errors, keep default false
    }
  }

  Booking get booking => _currentBooking ?? widget.booking;

  static String formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final local = d.isUtc ? d.toLocal() : d;
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase().replaceAll('_', ' ');
  }

  static Color statusColor(String? status, ColorScheme scheme) {
    if (status == null || status.isEmpty) return AppColors.errorMuted;
    final s = status.toLowerCase();
    if (s == 'confirmed') return scheme.primary;
    if (s == 'arrived_pickup') return const Color(0xFF1565C0);
    if (s == 'ongoing' || s == 'active' || s == 'in_progress' || s == 'in progress') {
      return const Color(0xFF2E7D32);
    }
    if (s == 'arrived_dropoff') return const Color(0xFF6A1B9A);
    if (s == 'pending') return const Color(0xFFE65100);
    return AppColors.errorMuted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<BookingBloc, BookingState>(
      listener: (BuildContext context, BookingState state) {
        if (state is BookingLoaded) {
          final list = state.bookings.where((Booking b) => b.id == widget.booking.id).toList();
          if (list.isNotEmpty && mounted) {
            setState(() => _currentBooking = list.first);
          }
        }
      },
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          booking.bookingNumber ?? booking.id,
          style: AppFontManager.bodyMedium(color: Colors.white)
              .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStatusChip(theme),
                const Spacer(),
                if (booking.chatLink != null && booking.chatLink!.isNotEmpty)
                  _buildChatIconButton(context, theme),
              ],
            ),
            const SizedBox(height: 24),
            if (_hasCustomerOrVehicle()) _buildSectionTitle(context, 'Details'),
            if (_hasCustomerOrVehicle()) ...[
              const SizedBox(height: 12),
              _buildDetailsBlock(theme),
              const SizedBox(height: 24),
            ],
            if (_hasRoute()) _buildSectionTitle(context, 'Route'),
            if (_hasRoute()) ...[
              const SizedBox(height: 12),
              _buildRouteBlock(theme),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle(context, 'Schedule & cost'),
            const SizedBox(height: 12),
            _buildScheduleBlock(theme),
            if (_canArrivedPickup() || _canStartBooking() || _canArrivedDropoff() || _canComplete()) ...[
              const SizedBox(height: 24),
              _buildActionButtons(context, theme),
            ],
          ],
        ),
      ),
    ),
    );
  }

  bool _canArrivedPickup() {
    final s = booking.status?.toLowerCase() ?? '';
    return s == 'confirmed';
  }

  bool _canStartBooking() {
    final s = booking.status?.toLowerCase() ?? '';
    return s == 'arrived_pickup';
  }

  bool _canArrivedDropoff() {
    final s = booking.status?.toLowerCase() ?? '';
    return s == 'ongoing';
  }

  bool _canComplete() {
    final s = booking.status?.toLowerCase() ?? '';
    return s == 'arrived_dropoff';
  }

bool _hasCustomerOrVehicle() =>
      (booking.customerName != null && booking.customerName!.isNotEmpty) ||
      (booking.customerPhone != null && booking.customerPhone!.isNotEmpty) ||
      (booking.vehicleInfo != null && booking.vehicleInfo!.isNotEmpty);

  bool _hasRoute() =>
      (booking.pickupAddress != null && booking.pickupAddress!.isNotEmpty) ||
      (booking.dropoffAddress != null && booking.dropoffAddress!.isNotEmpty);

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
          .copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    final status = booking.status;
    if (status == null || status.isEmpty) return const SizedBox.shrink();
    final color = statusColor(status, theme.colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        capitalize(status),
        style: AppFontManager.bodyMedium(color: color).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildDetailsBlock(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking.customerName != null && booking.customerName!.isNotEmpty)
            _detailRowWithOnline(
              Icons.person_outline_rounded,
              'Customer',
              booking.customerName!,
              theme,
              _isCustomerOnline,
            ),
          if (booking.customerPhone != null && booking.customerPhone!.isNotEmpty) ...[
            if (booking.customerName != null && booking.customerName!.isNotEmpty) const SizedBox(height: 12),
            _detailRow(
              Icons.phone_outlined,
              'Phone',
              booking.customerPhone!,
              theme,
            ),
          ],
          if (booking.vehicleInfo != null && booking.vehicleInfo!.isNotEmpty) ...[
            if ((booking.customerName != null && booking.customerName!.isNotEmpty) ||
                (booking.customerPhone != null && booking.customerPhone!.isNotEmpty))
              const SizedBox(height: 12),
            _detailRow(
              Icons.directions_car_outlined,
              'Vehicle',
              booking.vehicleInfo!,
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.errorMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                    .copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRowWithOnline(IconData icon, String label, String value, ThemeData theme, bool isOnline) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.errorMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                    .copyWith(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  if (isOnline) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: AppFontManager.bodyMedium(color: Colors.green)
                          .copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _wazeUrlForAddress(String address) {
    final encoded = Uri.encodeQueryComponent(address);
    return 'https://waze.com/ul?q=$encoded&navigate=yes';
  }

  Future<void> _openInWaze(BuildContext context, String address) async {
    final uri = Uri.tryParse(_wazeUrlForAddress(address));
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Waze')),
        );
      }
    }
  }

  Widget _buildRouteBlock(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking.pickupAddress != null && booking.pickupAddress!.isNotEmpty)
            _routeRow(
              theme,
              Icons.trip_origin_rounded,
              theme.colorScheme.primary,
              'Pickup',
              booking.pickupAddress!,
              (BuildContext context) => _openInWaze(context, booking.pickupAddress!),
            ),
          if (booking.pickupAddress != null &&
              booking.pickupAddress!.isNotEmpty &&
              booking.dropoffAddress != null &&
              booking.dropoffAddress!.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 9, top: 12, bottom: 12),
              child: Icon(Icons.swap_vert_rounded, size: 20, color: AppColors.errorMuted),
            ),
          if (booking.dropoffAddress != null && booking.dropoffAddress!.isNotEmpty)
            _routeRow(
              theme,
              Icons.location_on_rounded,
              AppColors.errorMuted,
              'Drop-off',
              booking.dropoffAddress!,
              (BuildContext context) => _openInWaze(context, booking.dropoffAddress!),
            ),
        ],
      ),
    );
  }

  Widget _routeRow(
    ThemeData theme,
    IconData icon,
    Color iconColor,
    String label,
    String address,
    void Function(BuildContext) onOpenWaze,
  ) {
    return Builder(
      builder: (BuildContext context) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                        .copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                        .copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => onOpenWaze(context),
                    icon: Icon(Icons.navigation_rounded, size: 18, color: Colors.blue),
                    label: Text(
                      'Open in Waze',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _formatDistance(String? distance) {
    if (distance == null || distance.isEmpty) return '—';
    final trimmed = distance.trim();
    if (trimmed.isEmpty) return '—';
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed)) return '$trimmed km';
    return trimmed;
  }

  Widget _buildScheduleBlock(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking.scheduledAt != null && booking.scheduledAt!.isNotEmpty)
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 20, color: AppColors.errorMuted),
                const SizedBox(width: 12),
                Text(
                  formatDate(booking.scheduledAt),
                  style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                      .copyWith(fontSize: 14),
                ),
              ],
            ),
          if (booking.distance != null && booking.distance!.isNotEmpty) ...[
            if (booking.scheduledAt != null && booking.scheduledAt!.isNotEmpty) const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.straighten_rounded, size: 20, color: AppColors.errorMuted),
                const SizedBox(width: 12),
                Text(
                  '${_formatDistance(booking.distance)} to run',
                  style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                      .copyWith(fontSize: 14),
                ),
              ],
            ),
          ],
          if (booking.estimatedCost != null && booking.estimatedCost!.isNotEmpty) ...[
            if ((booking.scheduledAt != null && booking.scheduledAt!.isNotEmpty) ||
                (booking.distance != null && booking.distance!.isNotEmpty))
              const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated cost',
                  style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                      .copyWith(fontSize: 14),
                ),
                Text(
                  '₱${booking.estimatedCost}',
                  style: AppFontManager.bodyMedium(color: theme.colorScheme.primary)
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static const double _actionButtonHeight = 52;
  static const double _actionButtonRadius = 10;

  Widget _buildChatIconButton(BuildContext context, ThemeData theme) {
    return IconButton.filled(
      onPressed: () {
        context.push(AppRoutes.conversation, extra: Chat.fromBooking(booking));
      },
      icon: const Icon(Icons.chat_rounded, size: 24),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    Color confirmColor = const Color(0xFF1565C0),
    String confirmLabel = 'Confirm',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_canArrivedPickup())
          _buildFilledActionButton(
            context,
            icon: Icons.trip_origin_rounded,
            label: 'Arrived at pickup',
            color: const Color(0xFF1565C0),
            onPressed: () => _confirmAction(
              context,
              title: 'Arrived at Pickup?',
              message: 'Confirm that you have arrived at the pickup location.',
              confirmColor: const Color(0xFF1565C0),
              confirmLabel: 'Confirm',
              onConfirm: () {
                final sessionState = context.read<SessionBloc>().state;
                if (sessionState is SessionAuthenticated) {
                  context.read<BookingBloc>().add(ArrivedBooking(
                        bookingId: booking.id,
                        driverId: sessionState.user.id,
                        location: 'pickup',
                      ));
                }
              },
            ),
          ),
        if (_canStartBooking())
          _buildFilledActionButton(
            context,
            icon: Icons.play_arrow_rounded,
            label: 'Start towing',
            color: const Color(0xFF2E7D32),
            onPressed: () => _confirmAction(
              context,
              title: 'Start Towing?',
              message: 'Confirm that you are starting the towing service now.',
              confirmColor: const Color(0xFF2E7D32),
              confirmLabel: 'Start',
              onConfirm: () {
                final sessionState = context.read<SessionBloc>().state;
                if (sessionState is SessionAuthenticated) {
                  context.read<BookingBloc>().add(StartBooking(
                        bookingId: booking.id,
                        driverId: sessionState.user.id,
                      ));
                }
              },
            ),
          ),
        if (_canArrivedDropoff())
          _buildFilledActionButton(
            context,
            icon: Icons.location_on_rounded,
            label: 'Arrived at drop-off',
            color: const Color(0xFF6A1B9A),
            onPressed: () => _confirmAction(
              context,
              title: 'Arrived at Drop-off?',
              message: 'Confirm that you have arrived at the drop-off location.',
              confirmColor: const Color(0xFF6A1B9A),
              confirmLabel: 'Confirm',
              onConfirm: () {
                final sessionState = context.read<SessionBloc>().state;
                if (sessionState is SessionAuthenticated) {
                  context.read<BookingBloc>().add(ArrivedBooking(
                        bookingId: booking.id,
                        driverId: sessionState.user.id,
                        location: 'dropoff',
                      ));
                }
              },
            ),
          ),
        if (_canComplete())
          _buildFilledActionButton(
            context,
            icon: Icons.check_circle_rounded,
            label: 'Complete',
            color: const Color(0xFF2E7D32),
            onPressed: () => _confirmAction(
              context,
              title: 'Complete Booking?',
              message: 'Mark this booking as completed? This cannot be undone.',
              confirmColor: const Color(0xFF2E7D32),
              confirmLabel: 'Complete',
              onConfirm: () {
                final sessionState = context.read<SessionBloc>().state;
                if (sessionState is SessionAuthenticated) {
                  context.read<BookingBloc>().add(CompleteBooking(
                        bookingId: booking.id,
                        driverId: sessionState.user.id,
                      ));
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilledActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: _actionButtonHeight,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_actionButtonRadius)),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
