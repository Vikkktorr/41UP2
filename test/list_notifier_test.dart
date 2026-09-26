import 'package:autoservice_web/models/car_query.dart';
import 'package:autoservice_web/repositories/in_memory_car_repository.dart';
import 'package:autoservice_web/repositories/network_simulator.dart';
import 'package:autoservice_web/state/car_list_notifier.dart';
import 'package:autoservice_web/state/list_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NetworkSimulator net;
  late CarListNotifier notifier;

  setUp(() {
    net = NetworkSimulator(latency: Duration.zero);
    notifier = CarListNotifier(InMemoryCarRepository(net));
  });

  test('загрузка проходит через состояние loading к loaded', () async {
    final states = <Type>[];
    notifier.addListener(() => states.add(notifier.state.runtimeType));
    await notifier.load();
    expect(states.first.toString(), startsWith('ListLoading'));
    expect(notifier.state, isA<ListLoaded>());
  });

  test('пустой результат — это успех, а не ошибка', () async {
    await notifier.applyQuery(const CarQuery(search: 'нет-такого'));
    final state = notifier.state as ListLoaded;
    expect(state.page.items, isEmpty);
  });

  test('сбой сети переводит в состояние ошибки', () async {
    net.failing = true;
    await notifier.load();
    expect(notifier.state, isA<ListFailed>());
    net.failing = false;
    await notifier.load();
    expect(notifier.state, isA<ListLoaded>());
  });

  test('смена условий отбора сбрасывает выделение', () async {
    await notifier.load();
    notifier.toggleSelection(1);
    notifier.toggleSelection(2);
    expect(notifier.selected, {1, 2});
    await notifier.applyQuery(const CarQuery(brandId: 1));
    expect(notifier.hasSelection, isFalse);
  });

  test('удаление выбранных убирает их из списка', () async {
    await notifier.load();
    final before = notifier.page!.total;
    notifier.setPageSelection(true);
    expect(notifier.selected.length, 10);
    final deleted = await notifier.deleteSelected();
    expect(deleted, 10);
    expect(notifier.page!.total, before - 10);
    expect(notifier.hasSelection, isFalse);
  });
}
