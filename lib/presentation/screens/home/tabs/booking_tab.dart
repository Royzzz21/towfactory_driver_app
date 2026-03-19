import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/colors_manager.dart';
import '../../../../core/theme/font_manager.dart';
import '../../../../domain/entities/booking.dart';
import '../../../bloc/booking/booking_bloc.dart';
import '../../../bloc/booking/booking_event.dart';
import '../../../bloc/booking/booking_state.dart';
import '../../../bloc/session/session_bloc.dart';
import '../../../bloc/session/session_state.dart';
import '../../../../services/driver_location_service.dart';

/// Booking tab: displays "my" bookings list via [BookingBloc].
class BookingTab extends StatefulWidget {
  const BookingTab({super.key});

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _maybeLoadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _maybeLoadBookings() {
    final sessionState = context.read<SessionBloc>().state;
    if (sessionState is SessionAuthenticated) {
      context.read<BookingBloc>().add(LoadBookings(driverId: sessionState.user.id));
    }
  }

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final local = d.isUtc ? d.toLocal() : d;
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDistance(String? distance) {
    if (distance == null || distance.isEmpty) return '—';
    final trimmed = distance.trim();
    if (trimmed.isEmpty) return '—';
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed)) return '$trimmed km';
    return trimmed;
  }

  Widget _buildBookingList({
    required BuildContext context,
    required ThemeData theme,
    required List<Booking> bookings,
    required String? activeBookingId,
    required bool hasMore,
    required bool isLoadingMore,
  }) {
    final itemCount = bookings.isEmpty ? 1 : bookings.length + (hasMore ? 1 : 0);
    return RefreshIndicator(
      onRefresh: () async {
        final sessionState = context.read<SessionBloc>().state;
        if (sessionState is SessionAuthenticated) {
          context.read<BookingBloc>().add(RefreshBookings(driverId: sessionState.user.id));
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          if (bookings.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded, size: 64, color: AppColors.errorMuted),
                    SizedBox(height: 16),
                    Text(
                      'No bookings yet',
                      style: TextStyle(color: AppColors.errorMuted),
                    ),
                  ],
                ),
              ),
            );
          }
          if (index == bookings.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: isLoadingMore
                    ? const SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: hasMore
                            ? () {
                                final sessionState = context.read<SessionBloc>().state;
                                if (sessionState is SessionAuthenticated) {
                                  context.read<BookingBloc>().add(
                                        LoadMoreBookings(driverId: sessionState.user.id),
                                      );
                                }
                              }
                            : null,
                        child: Text(hasMore ? 'Load more' : ''),
                      ),
              ),
            );
          }
          final booking = bookings[index];
          final isActive = activeBookingId != null && activeBookingId == booking.id;
          final isPending = booking.status != null &&
              booking.status!.toLowerCase() == 'pending';
          final canAccept = isPending && (activeBookingId == null || activeBookingId == booking.id);
          final activeBookingBlocked = isPending && activeBookingId != null && activeBookingId != booking.id;
          return _BookingCard(
            booking: booking,
            theme: theme,
            formatDate: _formatDate,
            formatDistance: _formatDistance,
            isActive: isActive,
            isPending: isPending,
            canAccept: canAccept,
            activeBookingBlocked: activeBookingBlocked,
            onTap: () => context.push('/booking/${booking.id}', extra: booking),
            onAccept: canAccept
                ? () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('Accept Booking?',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text(
                            'Are you sure you want to accept this booking?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.grey)),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Accept'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final sessionState = context.read<SessionBloc>().state;
                      if (sessionState is SessionAuthenticated) {
                        context.read<BookingBloc>().add(AcceptBooking(
                              bookingId: booking.id,
                              driverId: sessionState.user.id,
                            ));
                      }
                    }
                  }
                : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (BuildContext context, BookingState state) {
        if (state is AcceptBookingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is BookingLoaded) {
          final locationService = sl<DriverLocationService>();
          final sessionState = context.read<SessionBloc>().state;
          if (sessionState is SessionAuthenticated && !locationService.isTracking) {
            locationService.start(sessionState.user.id);
          }
        }
      },
      builder: (BuildContext context, BookingState state) {
        if (state is BookingLoading && !state.isLoadMore) {
          return _BookingSkeletonList(theme: theme);
        }
        if (state is AcceptBookingLoading || state is AcceptBookingSuccess) {
          return _BookingSkeletonList(theme: theme);
        }
        if (state is BookingError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorMuted),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppFontManager.bodyMedium(color: AppColors.errorMuted),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => _maybeLoadBookings(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final allBookings = state is BookingLoaded ? state.bookings : <Booking>[];
        final activeBookingId = state is BookingLoaded ? state.activeBookingId : null;
        final hasMore = state is BookingLoaded && state.hasMore;
        final isLoadingMore = state is BookingLoaded && state.isFetchingMore;

        final scheduledBookings = allBookings;
        final priorityBookings = allBookings.where((b) => b.isPriority).toList();

        return Column(
          children: [
            Container(
              color: theme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: AppFontManager.bodyMedium(color: theme.colorScheme.primary)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: [
                  const Tab(text: 'Scheduled'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Priority'),
                        if (priorityBookings.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${priorityBookings.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingList(
                    context: context,
                    theme: theme,
                    bookings: scheduledBookings,
                    activeBookingId: activeBookingId,
                    hasMore: hasMore,
                    isLoadingMore: isLoadingMore,
                  ),
                  _buildBookingList(
                    context: context,
                    theme: theme,
                    bookings: priorityBookings,
                    activeBookingId: activeBookingId,
                    hasMore: false,
                    isLoadingMore: false,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Skeleton loading ─────────────────────────────────────────────────────────

class _BookingSkeletonList extends StatelessWidget {
  const _BookingSkeletonList({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: 3,
        itemBuilder: (_, __) => _BookingSkeletonCard(theme: theme),
      ),
    );
  }
}

class _BookingSkeletonCard extends StatelessWidget {
  const _BookingSkeletonCard({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: booking number + status chip
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 16,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Container(
                  height: 24,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Vehicle info row
            Row(
              children: [
                Container(width: 20, height: 20, color: Colors.black),
                const SizedBox(width: 6),
                Container(
                  height: 13,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Route block
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 20, height: 20, color: Colors.black),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 13,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(width: 20, height: 20, color: Colors.black),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 13,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Footer: date + distance + price
            Row(
              children: [
                Container(
                  height: 12,
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 20,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Booking card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.theme,
    required this.formatDate,
    required this.formatDistance,
    this.isActive = false,
    this.isPending = false,
    this.canAccept = false,
    this.activeBookingBlocked = false,
    this.onTap,
    this.onAccept,
  });

  final Booking booking;
  final ThemeData theme;
  final String Function(String?) formatDate;
  final String Function(String?) formatDistance;
  final bool isActive;
  final bool isPending;
  final bool canAccept;
  final bool activeBookingBlocked;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;

  static const double _cardRadius = 16;
  static const double _chipRadius = 8;
  static const double _iconSize = 20;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF047857); // emerald
      case 'arrived_pickup':
        return const Color(0xFF0369A1); // sky blue
      case 'ongoing':
        return const Color(0xFF6D28D9); // violet
      case 'arrived_dropoff':
        return const Color(0xFFBE123C); // rose
      case 'pending':
        return const Color(0xFFB45309); // amber
      case 'completed':
        return const Color(0xFF047857); // emerald
      case 'cancelled':
      case 'no_show':
        return AppColors.errorMuted;
      default:
        return AppColors.errorMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute = (booking.pickupAddress != null && booking.pickupAddress!.isNotEmpty) ||
        (booking.dropoffAddress != null && booking.dropoffAddress!.isNotEmpty);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(
          color: isActive ? theme.colorScheme.primary : Colors.black.withValues(alpha: 0.08),
          width: isActive ? 2 : 1,
        ),
      ),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: booking number + chips
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.bookingNumber ?? booking.id,
                      style: AppFontManager.bodyMedium(color: theme.colorScheme.primary)
                          .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (booking.isPriority) ...[
                    _buildChip('Priority', Colors.red, false),
                    const SizedBox(width: 6),
                  ],
                  if (isActive) _buildChip('Active', theme.colorScheme.primary, true),
                  if (isActive) const SizedBox(width: 6),
                  if (booking.status != null && booking.status!.isNotEmpty)
                    _buildChip(
                      _capitalize(booking.status!),
                      _statusColor(booking.status!),
                      false,
                    ),
                ],
              ),
              // Customer + vehicle (compact)
              if (booking.customerName != null && booking.customerName!.isNotEmpty ||
                  booking.vehicleInfo != null && booking.vehicleInfo!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (booking.customerName != null && booking.customerName!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline_rounded, size: _iconSize, color: AppColors.errorMuted),
                          const SizedBox(width: 6),
                          Text(
                            booking.customerName!,
                            style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                                .copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    if (booking.vehicleInfo != null && booking.vehicleInfo!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car_outlined, size: _iconSize, color: AppColors.errorMuted),
                          const SizedBox(width: 6),
                          Text(
                            booking.vehicleInfo!,
                            style: AppFontManager.bodyMedium(color: AppColors.errorMuted).copyWith(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
              // Route block (pickup → dropoff)
              if (hasRoute) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (booking.pickupAddress != null && booking.pickupAddress!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.trip_origin_rounded, size: _iconSize, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                booking.pickupAddress!,
                                style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                                    .copyWith(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (booking.pickupAddress != null &&
                          booking.pickupAddress!.isNotEmpty &&
                          booking.dropoffAddress != null &&
                          booking.dropoffAddress!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                          child: Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.errorMuted),
                        ),
                      if (booking.dropoffAddress != null && booking.dropoffAddress!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_rounded, size: _iconSize, color: AppColors.errorMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                booking.dropoffAddress!,
                                style: AppFontManager.bodyMedium(color: AppColors.errorMuted).copyWith(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
              // Footer: date + distance + price
              const SizedBox(height: 16),
              Builder(builder: (context) {
                final baseCost = double.tryParse(booking.estimatedCost ?? '') ?? 0;
                final addOnsTotal = booking.addOns.fold<double>(
                  0,
                  (sum, a) => sum + (a['price'] is num ? (a['price'] as num).toDouble() : 0),
                );
                final total = baseCost + addOnsTotal;
                final hasAddOns = addOnsTotal > 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (booking.scheduledAt != null && booking.scheduledAt!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded, size: 16, color: AppColors.errorMuted),
                              const SizedBox(width: 6),
                              Text(
                                formatDate(booking.scheduledAt),
                                style: AppFontManager.bodyMedium(color: AppColors.errorMuted).copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        if (booking.distance != null && booking.distance!.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.straighten_rounded, size: 16, color: AppColors.errorMuted),
                              const SizedBox(width: 4),
                              Text(
                                formatDistance(booking.distance),
                                style: AppFontManager.bodyMedium(color: AppColors.errorMuted).copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        if (booking.estimatedCost != null && booking.estimatedCost!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (hasAddOns)
                                Text(
                                  '₱${baseCost % 1 == 0 ? baseCost.toInt() : baseCost}',
                                  style: AppFontManager.bodyMedium(color: AppColors.errorMuted).copyWith(
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                '₱${total % 1 == 0 ? total.toInt() : total}',
                                style: AppFontManager.bodyMedium(color: theme.colorScheme.primary).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (hasAddOns) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: booking.addOns
                            .where((a) => a['price'] is num && (a['price'] as num) > 0)
                            .map((a) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+₱${(a['price'] as num).toInt()} ${a['name'] ?? ''}',
                                    style: AppFontManager.bodyMedium(color: theme.colorScheme.primary)
                                        .copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                );
              }),
              // Message when pending but another booking is active
              if (activeBookingBlocked) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(_chipRadius),
                  ),
                  child: Text(
                    'Cancel or finish your current booking first',
                    style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                        .copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              // Accept button when pending and no other active booking
              if (canAccept && onAccept != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_chipRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isPrimary ? 0.15 : 0.12),
        borderRadius: BorderRadius.circular(_chipRadius),
      ),
      child: Text(
        label,
        style: AppFontManager.bodyMedium(color: color).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase().replaceAll('_', ' ');
  }
}
