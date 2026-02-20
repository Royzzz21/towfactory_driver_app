import 'message.dart';

/// Result of GET /bookings/:id/messages (data + meta).
class MessagesResult {
  const MessagesResult(this.raw);

  final Map<String, dynamic> raw;

  List<dynamic> get _listRaw {
    if (raw['data'] is List<dynamic>) return raw['data'] as List<dynamic>;
    if (raw['messages'] is List<dynamic>) return raw['messages'] as List<dynamic>;
    return <dynamic>[];
  }

  List<Message> get data {
    return _listRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> get meta =>
      raw['meta'] is Map<String, dynamic> ? raw['meta'] as Map<String, dynamic> : <String, dynamic>{};

  int get total {
    final m = meta;
    if (m['total'] is int) return m['total'] as int;
    if (m['total'] is num) return (m['total'] as num).toInt();
    return 0;
  }

  int get page {
    final m = meta;
    if (m['page'] is int) return m['page'] as int;
    if (m['page'] is num) return (m['page'] as num).toInt();
    return 1;
  }

  int get totalPages {
    final m = meta;
    if (m['totalPages'] is int) return m['totalPages'] as int;
    if (m['total_pages'] is int) return m['total_pages'] as int;
    if (m['totalPages'] is num) return (m['totalPages'] as num).toInt();
    if (m['total_pages'] is num) return (m['total_pages'] as num).toInt();
    return 1;
  }
}
