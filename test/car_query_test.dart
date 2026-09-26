import 'package:autoservice_web/models/car_query.dart';
import 'package:autoservice_web/models/client_query.dart';
import 'package:autoservice_web/models/fuel_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CarQuery и адрес', () {
    test('умолчания не попадают в адрес', () {
      expect(const CarQuery().toLocation(), '/cars');
    });

    test('все условия переживают путь в адрес и обратно', () {
      const query = CarQuery(
        search: 'камри',
        brandId: 4,
        fuel: FuelType.hybrid,
        yearFrom: 2015,
        yearTo: 2022,
        clientId: 3,
        sortField: 'year',
        sortAscending: false,
        page: 3,
        size: 25,
        includeDeleted: true,
      );
      final uri = Uri.parse(query.toLocation());
      expect(uri.queryParameters['sort'], 'year,desc');
      expect(CarQuery.fromQueryParameters(uri.queryParameters), query);
    });

    test('мусор в адресе заменяется умолчаниями', () {
      final query = CarQuery.fromQueryParameters({
        'page': '-5',
        'size': '999',
        'sort': 'price,desc',
        'fuel': 'steam',
        'brandId': 'abc',
      });
      expect(query.page, 1);
      expect(query.size, 10);
      expect(query.sortField, 'plate');
      expect(query.sortAscending, isFalse);
      expect(query.fuel, isNull);
      expect(query.brandId, isNull);
    });

    test('смена фильтра возвращает на первую страницу', () {
      const onPage5 = CarQuery(page: 5);
      expect(onPage5.copyWith(search: 'Kia').page, 1);
      expect(onPage5.copyWith(page: 6).page, 6);
    });

    test('copyWith отличает «не передан» от «сбросить в null»', () {
      const query = CarQuery(brandId: 2, yearFrom: 2018);
      expect(query.copyWith(search: 'x').brandId, 2);
      expect(query.copyWith(brandId: null).brandId, isNull);
      expect(query.copyWith(brandId: null).yearFrom, 2018);
    });

    test('повторный щелчок по колонке меняет направление', () {
      const query = CarQuery();
      final byYear = query.sortedBy('year');
      expect((byYear.sortField, byYear.sortAscending), ('year', true));
      final byYearDesc = byYear.sortedBy('year');
      expect(byYearDesc.sortAscending, isFalse);
      expect(byYearDesc.sortedBy('mileage').sortAscending, isTrue);
    });

    test('cleared сбрасывает фильтры, но сохраняет сортировку', () {
      const query = CarQuery(
        search: 'a',
        brandId: 1,
        sortField: 'year',
        size: 50,
      );
      final cleared = query.cleared();
      expect(cleared.hasFilters, isFalse);
      expect((cleared.sortField, cleared.size), ('year', 50));
    });
  });

  test('ClientQuery проходит путь в адрес и обратно', () {
    const query = ClientQuery(
      search: 'Иван',
      sortField: 'discount',
      sortAscending: false,
      page: 2,
    );
    final uri = Uri.parse(query.toLocation());
    expect(uri.path, '/clients');
    expect(ClientQuery.fromQueryParameters(uri.queryParameters), query);
  });
}
