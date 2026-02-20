import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/conversation_repository.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._chatRepository);

  final ChatRepository _chatRepository;

  @override
  Future<List<Chat>> getMyConversations() async {
    final result = await _chatRepository.getMyChats();
    return result.data;
  }
}
