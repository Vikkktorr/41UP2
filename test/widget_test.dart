import 'package:autoservice_web/app.dart';
import 'package:autoservice_web/repositories/network_simulator.dart';
import 'package:autoservice_web/widgets/entity_card_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Запускает приложение с заданным адресом и шириной окна.
Future<void> openApp(
  WidgetTester tester,
  String location, {
  Size size = const Size(1400, 900),
  NetworkSimulator? network,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    buildApp(
      network: network ?? NetworkSimulator(latency: Duration.zero),
      initialLocation: location,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('на широком окне список показан таблицей', (tester) async {
    await openApp(tester, '/cars');
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Записи 1–10 из 33'), findsOneWidget);
  });

  testWidgets('уже 600 пикселей вместо таблицы — карточки', (tester) async {
    await openApp(tester, '/cars', size: const Size(360, 800));
    expect(find.byType(DataTable), findsNothing);
    expect(find.byWidgetPredicate((w) => w is EntityCardList), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('адрес с условиями отбора восстанавливает список', (
    tester,
  ) async {
    await openApp(tester, '/cars?search=camry&brandId=4');
    expect(find.text('К001МР750'), findsOneWidget);
    expect(find.text('Записи 1–1 из 1'), findsOneWidget);
    // Поле поиска показывает значение из адреса.
    expect(find.widgetWithText(TextField, 'camry'), findsOneWidget);
  });

  testWidgets('пустой результат и ошибка выглядят по-разному', (tester) async {
    await openApp(tester, '/cars?search=zzzz');
    expect(find.text('Автомобили не найдены'), findsOneWidget);
    expect(find.text('Сбросить фильтры'), findsOneWidget);

    final net = NetworkSimulator(latency: Duration.zero)..failing = true;
    await openApp(tester, '/clients', network: net);
    expect(find.text('Ошибка загрузки'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    net.failing = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
  });

  testWidgets('щелчок по заголовку «Год» сортирует по году', (tester) async {
    await openApp(tester, '/cars');
    await tester.tap(find.text('Год').first);
    await tester.pumpAndSettle();
    // Самый старый автомобиль — Prius 2014 года.
    final firstCell = find.descendant(
      of: find.byType(DataTable),
      matching: find.text('В999ХХ77'),
    );
    expect(firstCell, findsOneWidget);
  });

  testWidgets('поиск срабатывает только после паузы во вводе', (tester) async {
    await openApp(tester, '/clients');
    await tester.enterText(find.byType(TextField).first, 'Кузнецов');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Записи 1–10 из 14'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Записи 1–1 из 1'), findsOneWidget);
  });

  testWidgets('флажки выделяют строки, появляется счётчик', (tester) async {
    await openApp(tester, '/cars');
    final boxes = find.byType(Checkbox);
    await tester.tap(boxes.at(1));
    await tester.tap(boxes.at(2));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано: 2'), findsOneWidget);
    expect(find.text('Удалить выбранные'), findsOneWidget);
  });

  testWidgets('неизвестный адрес ведёт на экран 404', (tester) async {
    await openApp(tester, '/qwerty');
    expect(find.text('404'), findsOneWidget);
  });

  testWidgets('карточка несуществующего автомобиля', (tester) async {
    await openApp(tester, '/cars/999');
    expect(find.text('Автомобиль №999 не найден'), findsOneWidget);
  });
}
