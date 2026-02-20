import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors_manager.dart';
import '../../../core/theme/font_manager.dart';
import '../../../domain/entities/chat.dart';
import '../../bloc/conversation_messages/conversation_messages_bloc.dart';
import '../../bloc/conversation_messages/conversation_messages_event.dart';
import '../../bloc/conversation_messages/conversation_messages_state.dart';

/// Conversation messages screen: chat thread for a conversation.
/// Uses [ConversationMessagesBloc] for load/send messages.
class ConversationMessagesScreen extends StatefulWidget {
  const ConversationMessagesScreen({
    super.key,
    required this.chat,
  });

  final Chat chat;

  @override
  State<ConversationMessagesScreen> createState() => _ConversationMessagesScreenState();
}

class _ConversationMessagesScreenState extends State<ConversationMessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _hasMarkedRead = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ConversationMessagesBloc>().add(const LoadConversationMessages());
      }
    });
  }

  void _onScroll() {
    if (!mounted) return;
    final bloc = context.read<ConversationMessagesBloc>();
    final state = bloc.state;
    if (state is! ConversationMessagesLoaded ||
        !state.hasMore ||
        state.isLoadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      bloc.add(const LoadMoreConversationMessages());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _typingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  /// App bar title: always "Customer".
  static String _title(Chat c) => 'Customer';

  static String _avatarLetter(Chat c) {
    if (c.customerName != null && c.customerName!.trim().isNotEmpty) {
      return c.customerName!.trim()[0].toUpperCase();
    }
    return 'C';
  }

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Formats as "Sat 3:22 PM" (day abbreviation + 12h time) in local time zone.
  static String _formatDateSeparator(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final local = d.isUtc ? d.toLocal() : d;
    final dayIndex = local.weekday - 1;
    final dayStr = dayIndex >= 0 && dayIndex < _weekdays.length ? _weekdays[dayIndex] : '';
    final hour12 = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final amPm = local.hour < 12 ? 'AM' : 'PM';
    final timeStr = '$hour12:${local.minute.toString().padLeft(2, '0')} $amPm';
    return '$dayStr $timeStr';
  }

  /// True if both ISO timestamps are on the same calendar day in local time zone.
  static bool _isSameDay(String? a, String? b) {
    if (a == null || b == null) return a == b;
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da == null || db == null) return false;
    final la = da.isUtc ? da.toLocal() : da;
    final lb = db.isUtc ? db.toLocal() : db;
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = widget.chat;
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8ED),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            BlocBuilder<ConversationMessagesBloc, ConversationMessagesState>(
              buildWhen: (prev, curr) {
                if (prev is ConversationMessagesLoaded && curr is ConversationMessagesLoaded) {
                  return prev.isOtherOnline != curr.isOtherOnline;
                }
                return false;
              },
              builder: (context, state) {
                final isOnline = state is ConversationMessagesLoaded && state.isOtherOnline;
                return Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      child: Text(
                        _avatarLetter(chat),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BlocBuilder<ConversationMessagesBloc, ConversationMessagesState>(
                buildWhen: (prev, curr) {
                  if (prev is ConversationMessagesLoaded && curr is ConversationMessagesLoaded) {
                    return prev.isOtherTyping != curr.isOtherTyping ||
                        prev.otherTypingName != curr.otherTypingName;
                  }
                  return false;
                },
                builder: (context, state) {
                  final isTyping = state is ConversationMessagesLoaded && state.isOtherTyping;
                  final typingName = state is ConversationMessagesLoaded ? state.otherTypingName : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _title(chat),
                        style: AppFontManager.bodyMedium(color: Colors.white)
                            .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isTyping)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${typingName ?? "Customer"} is typing...',
                            style: AppFontManager.bodyMedium(color: Colors.greenAccent).copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else if (chat.bookingNumber != null && chat.bookingNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            chat.bookingNumber!,
                            style: AppFontManager.bodyMedium(color: Colors.white70).copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: BlocListener<ConversationMessagesBloc, ConversationMessagesState>(
        listener: (BuildContext context, ConversationMessagesState state) {
          if (state is ConversationMessagesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state is ConversationMessagesLoaded &&
              state.snackbarMessage != null &&
              state.snackbarMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.snackbarMessage!),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.error,
              ),
            );
            context.read<ConversationMessagesBloc>().add(const ClearSnackbarMessage());
          }
          // Mark received messages as read once when conversation is loaded
          if (state is ConversationMessagesLoaded && !_hasMarkedRead) {
            for (final msg in state.messages.where((m) => !m.isFromMe && m.isRead != true)) {
              context.read<ConversationMessagesBloc>().add(MarkMessageAsRead(msg.id));
            }
            _hasMarkedRead = true;
          }
        },
        child: BlocBuilder<ConversationMessagesBloc, ConversationMessagesState>(
          builder: (BuildContext context, ConversationMessagesState state) {
            return Column(
              children: [
                Expanded(
                  child: _buildBody(context, theme, chat, state),
                ),
                _buildTypingIndicator(context),
                _buildSendBar(context, theme, chat),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    Chat chat,
    ConversationMessagesState state,
  ) {
    if (state is ConversationMessagesLoading || state is ConversationMessagesInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ConversationMessagesError) {
      final msg = state.message.toLowerCase();
      final isUnauthorized = msg.contains('unauthorized') || msg.contains('401') || msg.contains('not authenticated');
      final isValidation = msg.contains('validation');
      final title = isUnauthorized
          ? 'Session expired'
          : isValidation
              ? 'Couldn\'t load messages'
              : 'Something went wrong';
      final subtitle = isUnauthorized
          ? 'Please log in again to load messages.'
          : (state.message != title ? state.message : null);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorMuted),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppFontManager.bodyMedium(color: AppColors.errorMuted).copyWith(fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => context.read<ConversationMessagesBloc>().add(const LoadConversationMessages()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
              if (isUnauthorized) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (state is ConversationMessagesLoaded) {
      final messages = state.messages
          .where((m) {
            if (m.type?.toLowerCase() == 'status') return false;
            if (m.message.toLowerCase().contains('on my way')) return false;
            return true;
          })
          .toList();
      final hasMore = state.hasMore;
      final isLoadingMore = state.isLoadingMore;
      if (messages.isEmpty && !hasMore) {
        return _EmptyChatPlaceholder();
      }
      final itemCount = messages.isEmpty ? 1 : messages.length + (hasMore ? 1 : 0);
      return RefreshIndicator(
        onRefresh: () async {
          context.read<ConversationMessagesBloc>().add(const RefreshConversationMessages());
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          reverse: true,
          itemCount: itemCount,
          itemBuilder: (BuildContext context, int index) {
            if (messages.isEmpty) {
              return const SizedBox.shrink();
            }
            if (index == messages.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: isLoadingMore
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Loading messages...',
                              style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                                  .copyWith(fontSize: 13),
                            ),
                          ],
                        )
                      : TextButton(
                          onPressed: hasMore
                              ? () => context.read<ConversationMessagesBloc>().add(
                                    const LoadMoreConversationMessages(),
                                  )
                              : null,
                          child: Text(hasMore ? 'Load more' : ''),
                        ),
                ),
              );
            }
            final msg = messages[messages.length - 1 - index];
            final isOldestInList = index == messages.length - 1;
            final olderMessage = index + 1 < messages.length
                ? messages[messages.length - 2 - index]
                : null;
            final showDateSeparator = isOldestInList ||
                (olderMessage != null && !_isSameDay(msg.createdAt, olderMessage.createdAt));
            final dateLabel = showDateSeparator ? _formatDateSeparator(msg.createdAt) : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dateLabel.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Center(
                        child: Text(
                          dateLabel,
                          style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                              .copyWith(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  _ChatBubble(
                    text: msg.message,
                    isFromMe: msg.isFromMe,
                    senderName: msg.senderName,
                    isRead: msg.isRead,
                    createdAt: msg.createdAt,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _onTextChanged(BuildContext context) {
    _typingTimer?.cancel();
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      context.read<ConversationMessagesBloc>().add(const SetTyping(false));
      return;
    }
    _typingTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) context.read<ConversationMessagesBloc>().add(const SetTyping(true));
    });
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return BlocBuilder<ConversationMessagesBloc, ConversationMessagesState>(
      buildWhen: (prev, curr) {
        if (prev is ConversationMessagesLoaded && curr is ConversationMessagesLoaded) {
          return prev.isOtherTyping != curr.isOtherTyping;
        }
        return false;
      },
      builder: (context, state) {
        final isTyping = state is ConversationMessagesLoaded && state.isOtherTyping;
        final typingName = state is ConversationMessagesLoaded ? state.otherTypingName : null;
        if (!isTyping) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${typingName ?? "Customer"} is typing',
                      style: AppFontManager.bodyMedium(color: AppColors.errorMuted)
                          .copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    const _TypingDots(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSendBar(BuildContext context, ThemeData theme, Chat chat) {
    final canSend = chat.isBookingActive;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                readOnly: !canSend,
                decoration: InputDecoration(
                  hintText: canSend ? 'Type a message...' : 'Messages only for active bookings',
                  hintStyle: AppFontManager.bodyMedium(color: AppColors.errorMuted).copyWith(fontSize: 15),
                  filled: true,
                  fillColor: canSend ? const Color(0xFFE8E8ED) : theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _onTextChanged(context),
                onSubmitted: (_) => _sendMessage(context, chat),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: canSend ? () => _sendMessage(context, chat) : null,
              icon: const Icon(Icons.send_rounded, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: canSend ? AppColors.primary : AppColors.errorMuted,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context, Chat chat) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (!chat.isBookingActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only send messages for active bookings.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (text.toLowerCase().contains('on my way')) {
      _messageController.clear();
      return;
    }
    final bloc = context.read<ConversationMessagesBloc>();
    if (bloc.bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send: no booking'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    bloc.add(const SetTyping(false));
    _messageController.clear();
    bloc.add(SendConversationMessage(text));
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isFromMe,
    this.senderName,
    this.isRead,
    this.createdAt,
  });

  final String text;
  final bool isFromMe;
  final String? senderName;
  final bool? isRead;
  final String? createdAt;

  static String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final local = d.isUtc ? d.toLocal() : d;
    final hour12 = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final amPm = local.hour < 12 ? 'AM' : 'PM';
    return '$hour12:${local.minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = _formatTime(createdAt);
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (senderName != null && senderName!.trim().isNotEmpty && !isFromMe) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 2),
                child: Text(
                  senderName!,
                  style: AppFontManager.bodyMedium(color: AppColors.errorMuted).copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isFromMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isFromMe ? 18 : 4),
                  bottomRight: Radius.circular(isFromMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                text,
                style: AppFontManager.bodyMedium(
                  color: isFromMe ? AppColors.onPrimary : theme.colorScheme.onSurface,
                ).copyWith(fontSize: 15),
              ),
            ),
            if (isFromMe) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isRead == true ? Icons.done_all_rounded : Icons.done_rounded,
                  size: 14,
                  color: isRead == true
                      ? theme.colorScheme.primary
                      : AppColors.errorMuted,
                ),
              ),
            ],
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  timeStr,
                  style: AppFontManager.bodyMedium(color: AppColors.errorMuted).copyWith(fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyChatPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.errorMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'No messages in this thread',
              style: AppFontManager.bodyMedium(color: theme.colorScheme.onSurface)
                  .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Send a message below to start the conversation',
              textAlign: TextAlign.center,
              style: AppFontManager.bodyMedium(color: AppColors.errorMuted).copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.errorMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
