sealed class ConditionalResponse<T> {
  const ConditionalResponse({required this.etag});

  final String? etag;

  bool get isNotModified;
}

final class ModifiedResponse<T> extends ConditionalResponse<T> {
  const ModifiedResponse({required this.value, required super.etag});

  final T value;

  @override
  bool get isNotModified => false;
}

final class NotModifiedResponse<T> extends ConditionalResponse<T> {
  const NotModifiedResponse({required super.etag});

  @override
  bool get isNotModified => true;
}
