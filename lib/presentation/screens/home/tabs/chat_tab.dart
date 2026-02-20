import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors_manager.dart';
import '../../../router/app_router.dart';
import '../../../../core/theme/font_manager.dart';
import '../../../../domain/entities/chat.dart';
import '../../../bloc/conversation/conversation_bloc.dart';
import '../../../bloc/conversation/conversation_event.dart';
import '../../../bloc/conversation/conversation_state.dart';

/// Chat tab: list of conversations from GET /chats/my via [ConversationBloc].
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  @override
  void initState() {
    super.initState();
    context.read<ConversationBloc>().add(const LoadConversations());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<ConversationBloc, ConversationState>(
      builder: (BuildContext context, ConversationState state) {
        final conversations = state is ConversationLoaded ? state.conversations : <Chat>[];
        final isLoading = state is ConversationLoading;
        final isError = state is ConversationError;

        if (isLoading && conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (isError) {
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
                    onPressed: () => context.read<ConversationBloc>().add(const LoadConversations()),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ConversationBloc>().add(const RefreshConversations());
            try {
              await context.read<ConversationBloc>().stream
                  .where((ConversationState s) => s is ConversationLoaded || s is ConversationError)
                  .first
                  .timeout(const Duration(seconds: 15));
            } on TimeoutException {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request timed out. Check your connection and try again.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    'Chat',
                    style: AppFontManager.titleLarge(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Conversations with customers from your bookings.',
                    style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                        .copyWith(fontSize: 13),
                  ),
                ),
              ),
              if (conversations.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 80,
                            color: AppColors.errorMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No conversations yet',
                            style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                                .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Open chat from a booking in the Booking tab to start a conversation.',
                            style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                                .copyWith(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return _ConversationTile(
                          chat: conversations[index],
                          onTap: () => context.push(AppRoutes.conversation, extra: conversations[index]),
                        );
                      },
                      childCount: conversations.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.chat,
    required this.onTap,
  });

  final Chat chat;
  final VoidCallback onTap;

  static String _title(Chat c) {
    if (c.customerName != null && c.customerName!.trim().isNotEmpty) {
      return c.customerName!.trim();
    }
    if (c.bookingNumber != null && c.bookingNumber!.trim().isNotEmpty) {
      return 'Booking ${c.bookingNumber}';
    }
    return 'Conversation';
  }

  static String _lastMessageText(Chat c) {
    final msg = c.lastMessage?.trim();
    if (msg != null && msg.isNotEmpty) return msg;
    return 'No recent messages';
  }

  static String? _lastMessageTimeAgo(Chat c) {
    final at = c.lastMessageAt?.trim();
    if (at == null || at.isEmpty) return null;
    final d = DateTime.tryParse(at);
    if (d == null) return null;
    final local = d.isUtc ? d.toLocal() : d;
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    if (diff.inSeconds > 0) return '${diff.inSeconds}s ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _lastMessageTimeAgo(chat);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.chat_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  if (chat.isOnline == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.cardColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title(chat),
                      style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _lastMessageText(chat),
                            style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                                .copyWith(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeAgo != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeAgo,
                            style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                                .copyWith(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    if (!chat.isBookingActive) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Booking not active — view only',
                        style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                            .copyWith(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.errorMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
