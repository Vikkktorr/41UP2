import 'package:autoservice_web/core/formatting.dart';
import 'package:autoservice_web/models/client.dart';
import 'package:autoservice_web/models/page_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('госномер: латиница превращается в кириллицу, пробелы убираются', () {
    expect(normalizePlate('a 123 bc 77'), 'А123ВС77');
    expect(normalizePlate('А123ВС77'), 'А123ВС77');
  });

  test('склонение после числа', () {
    String cars(int n) => plural(n, 'автомобиль', 'автомобиля', 'автомобилей');
    expect(cars(1), 'автомобиль');
    expect(cars(3), 'автомобиля');
    expect(cars(5), 'автомобилей');
    expect(cars(11), 'автомобилей');
    expect(cars(21), 'автомобиль');
    expect(cars(24), 'автомобиля');
  });

  test('пробег с разделением разрядов', () {
    expect(formatMileage(125000).replaceAll(' ', ' '), '125 000 км');
  });

  test('короткое имя клиента', () {
    final client = Client(
      id: 1,
      lastName: 'Иванов',
      firstName: 'Сергей',
      middleName: 'Петрович',
      phone: '',
      email: '',
      registeredAt: DateTime(2020),
    );
    expect(client.shortName, 'Иванов С. П.');
  });

  test('PageResult: число страниц и границы записей', () {
    const page = PageResult(items: [1, 2, 3, 4], page: 4, size: 10, total: 34);
    expect(page.totalPages, 4);
    expect((page.firstIndex, page.lastIndex), (31, 34));
    expect(page.hasNext, isFalse);
    expect(PageResult<int>.empty().totalPages, 1);
  });
}
