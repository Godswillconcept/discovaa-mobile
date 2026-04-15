class ApiErrorPayload {
  final String? code;
  final String? message;
  final Map<String, dynamic>? details;

  const ApiErrorPayload({this.code, this.message, this.details});

  factory ApiErrorPayload.fromJson(Map<String, dynamic> json) {
    return ApiErrorPayload(
      code: json['code']?.toString(),
      message:
          json['message']?.toString() ??
          json['detail']?.toString() ??
          json['error']?.toString(),
      details: json,
    );
  }
}

class PaginationMeta {
  final int count;
  final String? next;
  final String? previous;

  const PaginationMeta({
    required this.count,
    this.next,
    this.previous,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      count: _asInt(json['count']),
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
    );
  }
}

class ApiMeta {
  final PaginationMeta? pagination;
  final Map<String, dynamic>? raw;

  const ApiMeta({this.pagination, this.raw});

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      pagination: json['pagination'] is Map<String, dynamic>
          ? PaginationMeta.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
      raw: json,
    );
  }
}

class ApiEnvelope<T> {
  final bool success;
  final T data;
  final ApiMeta? meta;
  final ApiErrorPayload? error;

  const ApiEnvelope({
    required this.success,
    required this.data,
    this.meta,
    this.error,
  });

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic rawData) decoder,
  ) {
    return ApiEnvelope(
      success: json['success'] == true,
      data: decoder(json['data']),
      meta: json['meta'] is Map<String, dynamic>
          ? ApiMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      error: json['error'] is Map<String, dynamic>
          ? ApiErrorPayload.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiListEnvelope<T> extends ApiEnvelope<List<T>> {
  const ApiListEnvelope({
    required super.success,
    required super.data,
    super.meta,
    super.error,
  });

  factory ApiListEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) decoder,
  ) {
    final rawData = json['data'];
    final items = <T>[];

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          items.add(decoder(item));
        }
      }
    } else if (rawData is Map<String, dynamic> && rawData['results'] is List) {
      for (final item in rawData['results'] as List<dynamic>) {
        if (item is Map<String, dynamic>) {
          items.add(decoder(item));
        }
      }
    }

    return ApiListEnvelope(
      success: json['success'] == true,
      data: items,
      meta: json['meta'] is Map<String, dynamic>
          ? ApiMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      error: json['error'] is Map<String, dynamic>
          ? ApiErrorPayload.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
