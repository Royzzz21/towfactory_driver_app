/// Generic API response wrapper (data + optional message).
class BaseResponse<T> {
  const BaseResponse({required this.data, this.message});

  final T data;
  final String? message;

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final data = json['data'];
    final message = json['message'] as String?;
    return BaseResponse<T>(
      data: data is Map<String, dynamic> ? fromJsonT(data) : fromJsonT(json),
      message: message,
    );
  }
}
