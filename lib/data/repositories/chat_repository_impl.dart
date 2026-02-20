import '../../domain/entities/message.dart';
import '../../domain/entities/messages_result.dart';
import '../../domain/entities/my_chats_result.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../services/chat_service.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._chatService);

  final ChatService _chatService;

  @override
  Future<MyChatsResult> getMyChats() async {
    final map = await _chatService.getMyChats();
    return MyChatsResult(map);
  }

  @override
  Future<MessagesResult> getMessages(String bookingId, {int page = 1, int limit = 50}) async {
    final map = await _chatService.getMessages(bookingId, page: page, limit: limit);
    return MessagesResult(map);
  }

  @override
  Future<Message?> sendMessage(String bookingId, String message, {String type = 'text'}) async {
    final map = await _chatService.sendMessage(bookingId, message, type: type);
    final chat = map['chat'];
    if (chat is Map<String, dynamic>) {
      return Message.fromJson(Map<String, dynamic>.from(chat));
    }
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      return Message.fromJson(Map<String, dynamic>.from(data));
    }
    if (map['id'] != null || map['message'] != null) {
      return Message.fromJson(Map<String, dynamic>.from(map));
    }
    return null;
  }

  @override
  Future<bool> isCustomerOnline(String bookingId) async {
    try {
      return await _chatService.isCustomerOnline(bookingId);
    } catch (_) {
      return false;
    }
  }
}
