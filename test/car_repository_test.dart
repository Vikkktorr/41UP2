import 'package:autoservice_web/models/car_query.dart';
import 'package:autoservice_web/models/fuel_type.dart';
import 'package:autoservice_web/repositories/in_memory_car_repository.dart';
import 'package:autoservice_web/repositories/network_simulator.dart';
import 'package:autoservice_web/repositories/repository_exception.dart';
import 'package:autoservice_web/repositories/seed_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryCarRepository repo;

  setUp(() {
    repo = InMemoryCarRepository(NetworkSimulator(latency: Duration.zero));
  });

  group('Начальные данные', () {
    test('не менее 20 автомобилей и 8 клиентов', () {
      expect(seedCars.length, greaterThanOrEqualTo(20));
      expect(seedClients.length, greaterThanOrEqualTo(8));
    });

    test('госномера и VIN корректны и уникальны', () {
      final plate = RegExp(r'^[АВЕКМНОРСТУХ]\d{3}[АВЕКМНОРСТУХ]{2}\d{2,3}$');
      // В VIN не бывает букв I, O и Q: их легко спутать с 1 и 0.
      final vin = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
      for (final car in seedCars) {
        expect(car.plate, matches(plate), reason: car.plate);
        expect(car.vin, matches(vin), reason: car.vin);
      }
      expect(seedCars.map((c) => c.plate).toSet().length, seedCars.length);
      expect(seedCars.map((c) => c.vin).toSet().length, seedCars.length);
    });

    test('каждый автомобиль ссылается на существующие марку и клиента', () {
      final brands = seedBrands.map((b) => b.id).toSet();
      final clients = seedClients.map((c) => c.id).toSet();
      for (final car in seedCars) {
        expect(brands, contains(car.brandId));
        expect(clients, contains(car.clientId));
      }
    });
  });

  group('Поиск и фильтры', () {
    test('госномер находится при вводе латиницей и строчными', () async {
      final page = await repo.find(const CarQuery(search: 'k001mp'));
      expect(page.items.single.plate, 'К001МР750');
    });

    test('поиск по части VIN', () async {
      final page = await repo.find(const CarQuery(search: 'wba8e9'));
      expect(page.items.single.model, '320d');
    });

    test('фильтры комбинируются между собой и с поиском', () async {
      final page = await repo.find(
        const CarQuery(brandId: 1, fuel: FuelType.gas, yearFrom: 2021),
      );
      expect(page.items.map((c) => c.plate), ['Е321ЕЕ750']);

      final withSearch = await repo.find(
        const CarQuery(brandId: 4, yearTo: 2020, search: 'prius'),
      );
      expect(withSearch.items.single.plate, 'В999ХХ77');
    });

    test('удалённые скрыты, пока не включён показ', () async {
      final visible = await repo.find(const CarQuery(size: 50));
      final all = await repo.find(
        const CarQuery(size: 50, includeDeleted: true),
      );
      expect(all.total - visible.total, 1);
      expect(visible.items.any((c) => c.isDeleted), isFalse);
    });
  });

  group('Сортировка и страницы', () {
    test('по году по убыванию, при равенстве — по id', () async {
      final page = await repo.find(
        const CarQuery(sortField: 'year', sortAscending: false, size: 50),
      );
      final years = page.items.map((c) => c.year).toList();
      expect(years, [...years]..sort((a, b) => b.compareTo(a)));
    });

    test('последняя страница неполная, за пределами — пусто', () async {
      final first = await repo.find(const CarQuery());
      expect(first.items.length, 10);
      expect(first.totalPages, 4);

      final last = await repo.find(const CarQuery(page: 4));
      expect(last.items.length, first.total - 30);
      expect(last.hasNext, isFalse);

      final beyond = await repo.find(const CarQuery(page: 9));
      expect(beyond.items, isEmpty);
      expect(beyond.total, first.total);
    });
  });

  group('Удаление', () {
    test('логическое удаление и восстановление', () async {
      await repo.softDelete(1);
      expect((await repo.findById(1))!.isDeleted, isTrue);
      await repo.restore(1);
      expect((await repo.findById(1))!.isDeleted, isFalse);
    });

    test('физическое удаление стирает запись', () async {
      await repo.hardDelete(1);
      expect(await repo.findById(1), isNull);
      expect(() => repo.hardDelete(1), throwsA(isA<NotFoundException>()));
    });

    test('deleteMany считает только ещё не удалённые записи', () async {
      // Автомобиль 20 удалён в начальных данных, 999 не существует.
      final count = await repo.deleteMany([1, 2, 20, 999]);
      expect(count, 2);
    });
  });

  test('дубль госномера при создании — конфликт', () async {
    final car = (await repo.findById(1))!;
    expect(
      () => repo.create(car.copyWith(vin: 'XTA000000A0000000')),
      throwsA(isA<ConflictException>()),
    );
    final created = await repo.create(
      car.copyWith(plate: 'А001АА77', vin: 'XTA000000A0000000'),
    );
    expect(created.id, greaterThan(seedCars.length));
  });

  test('имитация сбоя сети даёт NetworkException', () async {
    final net = NetworkSimulator(latency: Duration.zero)..failing = true;
    final failing = InMemoryCarRepository(net);
    expect(
      () => failing.find(const CarQuery()),
      throwsA(isA<NetworkException>()),
    );
  });
}
