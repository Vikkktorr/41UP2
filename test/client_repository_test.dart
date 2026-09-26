import 'package:autoservice_web/models/client_query.dart';
import 'package:autoservice_web/repositories/in_memory_car_repository.dart';
import 'package:autoservice_web/repositories/in_memory_client_repository.dart';
import 'package:autoservice_web/repositories/network_simulator.dart';
import 'package:autoservice_web/repositories/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryClientRepository repo;

  setUp(() {
    final net = NetworkSimulator(latency: Duration.zero);
    final cars = InMemoryCarRepository(net);
    repo = InMemoryClientRepository(net, carsOf: cars.countByClient);
  });

  test('поиск по фамилии без учёта регистра', () async {
    final page = await repo.find(const ClientQuery(search: 'кузн'));
    expect(page.items.single.lastName, 'Кузнецов');
  });

  test('поиск по телефону не зависит от скобок и дефисов', () async {
    final page = await repo.find(const ClientQuery(search: '925 345-67'));
    expect(page.items.single.lastName, 'Кузнецов');
  });

  test('сортировка по скидке по убыванию', () async {
    final page = await repo.find(
      const ClientQuery(sortField: 'discount', sortAscending: false),
    );
    expect(page.items.first.lastName, 'Соколов');
  });

  test('клиента с автомобилями нельзя стереть навсегда', () async {
    expect(() => repo.hardDelete(1), throwsA(isA<ConflictException>()));
    // У клиента 13 автомобилей нет.
    await repo.hardDelete(13);
    expect(await repo.findById(13), isNull);
  });

  test('deleteMany и восстановление', () async {
    expect(await repo.deleteMany([1, 2, 2]), 2);
    final visible = await repo.find(const ClientQuery(size: 50));
    expect(visible.items.any((c) => c.id == 1), isFalse);
    await repo.restore(1);
    expect((await repo.findById(1))!.isDeleted, isFalse);
  });
}
