import 'package:flutter/foundation.dart';

sealed class DetailState<T> {
  const DetailState();
}

final class DetailLoading<T> extends DetailState<T> {
  const DetailLoading();
}

final class DetailLoaded<T> extends DetailState<T> {
  const DetailLoaded(this.item);

  final T item;
}

/// Записи с таким идентификатором нет — адрес мог быть введён вручную.
final class DetailNotFound<T> extends DetailState<T> {
  const DetailNotFound();
}

final class DetailFailed<T> extends DetailState<T> {
  const DetailFailed(this.message);

  final String message;
}

/// Состояние экрана карточки. Источник данных передаётся функцией,
/// поэтому один класс обслуживает карточки всех сущностей.
class DetailNotifier<T> extends ChangeNotifier {
  DetailNotifier(this._loader);

  final Future<T?> Function() _loader;
  DetailState<T> _state = const DetailLoading();
  bool _disposed = false;

  DetailState<T> get state => _state;

  Future<void> load() async {
    _state = DetailLoading<T>();
    _notify();
    try {
      final item = await _loader();
      _state = item == null ? DetailNotFound<T>() : DetailLoaded<T>(item);
    } catch (e) {
      _state = DetailFailed<T>('Не удалось загрузить запись: $e');
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
