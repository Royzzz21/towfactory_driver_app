import '../entities/message.dart';
import '../entities/messages_result.dart';
import '../entities/my_chats_result.dart';

/// Repository interface for chat/conversations.
abstract class ChatRepository {
  /// Fetches "my" chats/conversations. Throws [ApiException] on failure.
  Future<MyChatsResult> getMyChats();

  /// Fetches messages for a booking. Throws [ApiException] on failure.
  Future<MessagesResult> getMessages(String bookingId, {int page = 1, int limit = 50});

  /// Sends a message (POST /chats). Returns the created [Message] if response contains it. Throws [ApiException] on failure.
  Future<Message?> sendMessage(String bookingId, String message, {String type = 'text'});

  /// Checks if customer is online for a booking. Returns [false] on error.
  Future<bool> isCustomerOnline(String bookingId);
}
