import '../core/formatting.dart';
import '../models/client.dart';
import '../models/client_query.dart';
import '../models/page_result.dart';
import 'client_repository.dart';
import 'network_simulator.dart';
import 'repository_exception.dart';
import 'seed_data.dart';

class InMemoryClientRepository implements ClientRepository {
  InMemoryClientRepository(
    this._net, {
    List<Client>? seed,
    int Function(int clientId)? carsOf,
  }) : _clients = [...(seed ?? seedClients)],
       _carsOf = carsOf ?? ((_) => 0) {
    _nextId = _clients.fold(0, (max, c) => c.id > max ? c.id : max) + 1;
  }

  final NetworkSimulator _net;
  final List<Client> _clients;

  /// Сколько автомобилей у клиента — чтобы не стереть владельца,
  /// на которого ссылаются автомобили.
  final int Function(int clientId) _carsOf;
  late int _nextId;

  @override
  Future<List<Client>> findAll() async {
    await _net.roundTrip();
    return List.unmodifiable(_clients);
  }

  @override
  Future<PageResult<Client>> find(ClientQuery q) async {
    await _net.roundTrip();

    var rows = _clients.where((c) => q.includeDeleted || !c.isDeleted).toList();

    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      // По телефону ищем только по цифрам: «916 123» найдёт
      // «+7 (916) 123-45-67» независимо от скобок и дефисов.
      final digits = digitsOnly(needle);
      rows = rows
          .where(
            (c) =>
                c.lastName.toLowerCase().contains(needle) ||
                (digits.length >= 3 && digitsOnly(c.phone).contains(digits)),
          )
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'registeredAt' => a.registeredAt.compareTo(b.registeredAt),
        'discount' => a.discount.compareTo(b.discount),
        _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
      final ordered = result != 0 ? result : a.id.compareTo(b.id);
      return q.sortAscending ? ordered : -ordered;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Client>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Client?> findById(int id) async {
    await _net.roundTrip();
    for (final client in _clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  @override
  Future<Client> create(Client client) async {
    await _net.roundTrip();
    // У новой записи ещё нет своего id, сравниваем со всеми.
    _checkUnique(client, exceptId: null);
    final created = client.copyWith(id: _nextId++);
    _clients.add(created);
    return created;
  }

  @override
  Future<Client> update(Client client) async {
    await _net.roundTrip();
    final i = _indexOf(client.id);
    _checkUnique(client, exceptId: client.id);
    _clients[i] = client;
    return client;
  }

  void _checkUnique(Client client, {required int? exceptId}) {
    final phone = digitsOnly(client.phone);
    for (final other in _clients) {
      if (other.id != exceptId && digitsOnly(other.phone) == phone) {
        throw ConflictException('Телефон ${client.phone} уже есть в базе');
      }
    }
  }

  int _indexOf(int id) {
    final i = _clients.indexWhere((c) => c.id == id);
    if (i == -1) throw NotFoundException('Клиент $id не найден');
    return i;
  }

  @override
  Future<void> softDelete(int id) async {
    await _net.roundTrip();
    final i = _indexOf(id);
    _clients[i] = _clients[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await _net.roundTrip();
    final i = _indexOf(id);
    final cars = _carsOf(id);
    if (cars > 0) {
      throw ConflictException(
        'Нельзя удалить навсегда: за клиентом числится '
        '$cars ${plural(cars, 'автомобиль', 'автомобиля', 'автомобилей')}',
      );
    }
    _clients.removeAt(i);
  }

  @override
  Future<void> restore(int id) async {
    await _net.roundTrip();
    final i = _indexOf(id);
    _clients[i] = _clients[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await _net.roundTrip();
    var count = 0;
    final now = DateTime.now();
    for (final id in ids) {
      final i = _clients.indexWhere((c) => c.id == id && !c.isDeleted);
      if (i != -1) {
        _clients[i] = _clients[i].copyWith(deletedAt: now);
        count++;
      }
    }
    return count;
  }
}
