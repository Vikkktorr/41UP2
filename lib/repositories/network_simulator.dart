import 'package:flutter/foundation.dart';

import 'repository_exception.dart';

/// Имитация сети для репозиториев в памяти.
///
/// Задержка нужна, чтобы индикатор загрузки было видно; флаг [failing]
/// позволяет проверить экран ошибки, не дожидаясь настоящего сервера.
class NetworkSimulator extends ChangeNotifier {
  NetworkSimulator({this.latency = const Duration(milliseconds: 250)});

  final Duration latency;
  bool _failing = false;
  bool _slow = false;

  bool get failing => _failing;

  /// Медленная сеть: ответ приходит через шесть секунд — так индикатор
  /// загрузки успевает рассмотреть.
  bool get slow => _slow;

  set slow(bool value) {
    if (_slow == value) return;
    _slow = value;
    notifyListeners();
  }

  set failing(bool value) {
    if (_failing == value) return;
    _failing = value;
    notifyListeners();
  }

  /// Вызывается в начале каждой операции репозитория.
  Future<void> roundTrip() async {
    final delay = _slow ? const Duration(seconds: 6) : latency;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (_failing) {
      throw const NetworkException(
        'Сервер не отвечает. Проверьте подключение.',
      );
    }
  }
}
