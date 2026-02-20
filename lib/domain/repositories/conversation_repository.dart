import '../entities/chat.dart';

/// Repository interface for conversations (my chats list).
abstract class ConversationRepository {
  /// Fetches "my" conversations. Throws [ApiException] on failure.
  Future<List<Chat>> getMyConversations();
}
