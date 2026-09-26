/// Ошибки слоя данных. Текст [message] рассчитан на показ пользователю.
sealed class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Запись не найдена (в API это будет код 404).
class NotFoundException extends RepositoryException {
  const NotFoundException(super.message);
}

/// Операция противоречит данным: дубль госномера, у клиента есть
/// автомобили (в API это будет код 409).
class ConflictException extends RepositoryException {
  const ConflictException(super.message);
}

/// Сервер недоступен. Пока данные в памяти, возникает только
/// при включённой имитации сбоя.
class NetworkException extends RepositoryException {
  const NetworkException(super.message);
}
