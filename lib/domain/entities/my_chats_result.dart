import 'chat.dart';

/// Result of GET /chats/my.
/// Supports response shape: { data: [...] } or { chats: [...] } or { conversations: [...] }.
class MyChatsResult {
  const MyChatsResult(this.raw);

  final Map<String, dynamic> raw;

  List<dynamic> get _listRaw {
    if (raw['data'] is List<dynamic>) return raw['data'] as List<dynamic>;
    if (raw['chats'] is List<dynamic>) return raw['chats'] as List<dynamic>;
    if (raw['conversations'] is List<dynamic>) return raw['conversations'] as List<dynamic>;
    return <dynamic>[];
  }

  List<Chat> get data {
    return _listRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => Chat.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
