import '../core/formatting.dart';
import '../models/brand.dart';
import '../models/car.dart';
import '../models/car_query.dart';
import '../models/page_result.dart';
import 'car_repository.dart';
import 'network_simulator.dart';
import 'repository_exception.dart';
import 'seed_data.dart';

class InMemoryCarRepository implements CarRepository {
  InMemoryCarRepository(
    this._net, {
    List<Car>? seed,
    List<Brand> brands = seedBrands,
  }) : _cars = [...(seed ?? seedCars)],
       _brandNames = {for (final b in brands) b.id: b.name} {
    _nextId = _cars.fold(0, (max, c) => c.id > max ? c.id : max) + 1;
  }

  final NetworkSimulator _net;
  final List<Car> _cars;

  /// Нужны для сортировки по марке: в самой записи хранится только brandId.
  final Map<int, String> _brandNames;
  late int _nextId;

  /// Сколько автомобилей числится за клиентом. Используется репозиторием
  /// клиентов, чтобы не дать стереть владельца вместе со ссылками на него.
  int countByClient(int clientId) =>
      _cars.where((c) => c.clientId == clientId).length;

  @override
  Future<PageResult<Car>> find(CarQuery q) async {
    await _net.roundTrip();

    var rows = _cars.where((c) => q.includeDeleted || !c.isDeleted).toList();

    final needle = q.search.trim();
    if (needle.isNotEmpty) {
      final plateNeedle = normalizePlate(needle);
      final textNeedle = needle.toLowerCase();
      rows = rows
          .where(
            (c) =>
                normalizePlate(c.plate).contains(plateNeedle) ||
                c.vin.toLowerCase().contains(textNeedle) ||
                c.model.toLowerCase().contains(textNeedle),
          )
          .toList();
    }
    if (q.brandId != null) {
      rows = rows.where((c) => c.brandId == q.brandId).toList();
    }
    if (q.fuel != null) {
      rows = rows.where((c) => c.fuel == q.fuel).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((c) => c.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((c) => c.year <= q.yearTo!).toList();
    }
    if (q.clientId != null) {
      rows = rows.where((c) => c.clientId == q.clientId).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'mileage' => a.mileage.compareTo(b.mileage),
        'brand' => _brandLabel(a).compareTo(_brandLabel(b)),
        _ => a.plate.compareTo(b.plate),
      };
      // При равенстве основного поля порядок задаёт id, иначе строки
      // с одинаковым годом «прыгали» бы между страницами.
      final ordered = result != 0 ? result : a.id.compareTo(b.id);
      return q.sortAscending ? ordered : -ordered;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    // num.clamp возвращает num, а sublist ждёт int — границу считаем явно.
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Car>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  String _brandLabel(Car c) =>
      '${_brandNames[c.brandId] ?? ''} ${c.model}'.toLowerCase();

  @override
  Future<Car?> findById(int id) async {
    await _net.roundTrip();
    for (final car in _cars) {
      if (car.id == id) return car;
    }
    return null;
  }

  @override
  Future<Car> create(Car car) async {
    await _net.roundTrip();
    // У новой записи ещё нет своего id, сравниваем со всеми.
    _checkUnique(car, exceptId: null);
    final created = car.copyWith(id: _nextId++);
    _cars.add(created);
    return created;
  }

  @override
  Future<Car> update(Car car) async {
    await _net.roundTrip();
    final i = _indexOf(car.id);
    _checkUnique(car, exceptId: car.id);
    _cars[i] = car;
    return car;
  }

  /// Госномер и VIN уникальны. На сервере это будет ответ 409.
  void _checkUnique(Car car, {required int? exceptId}) {
    for (final other in _cars) {
      if (other.id == exceptId) continue;
      if (normalizePlate(other.plate) == normalizePlate(car.plate)) {
        throw ConflictException('Госномер ${car.plate} уже зарегистрирован');
      }
      if (other.vin.toUpperCase() == car.vin.toUpperCase()) {
        throw ConflictException('VIN ${car.vin} уже зарегистрирован');
      }
    }
  }

  int _indexOf(int id) {
    final i = _cars.indexWhere((c) => c.id == id);
    if (i == -1) throw NotFoundException('Автомобиль $id не найден');
    return i;
  }

  @override
  Future<void> softDelete(int id) async {
    await _net.roundTrip();
    final i = _indexOf(id);
    _cars[i] = _cars[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await _net.roundTrip();
    _cars.removeAt(_indexOf(id));
  }

  @override
  Future<void> restore(int id) async {
    await _net.roundTrip();
    final i = _indexOf(id);
    _cars[i] = _cars[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await _net.roundTrip();
    var count = 0;
    final now = DateTime.now();
    for (final id in ids) {
      // В исходном варианте здесь было `!b[i].isDeleted`: обращение к i
      // внутри её же инициализатора и индексация объекта-модели.
      final i = _cars.indexWhere((c) => c.id == id && !c.isDeleted);
      if (i != -1) {
        _cars[i] = _cars[i].copyWith(deletedAt: now);
        count++;
      }
    }
    return count;
  }
}
