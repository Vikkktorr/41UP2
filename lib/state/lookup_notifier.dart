import 'package:flutter/foundation.dart';

import '../models/brand.dart';
import '../models/client.dart';
import '../repositories/brand_repository.dart';
import '../repositories/client_repository.dart';

/// Справочники для подписей и выпадающих списков: марки и имена клиентов.
///
/// В записи автомобиля хранятся только brandId и clientId, а в таблице
/// нужно показать «Kia Rio» и «Иванов С. П.».
class LookupNotifier extends ChangeNotifier {
  LookupNotifier(this._brands, this._clients);

  final BrandRepository _brands;
  final ClientRepository _clients;

  List<Brand> _brandList = const [];
  Map<int, Brand> _brandById = const {};
  Map<int, Client> _clientById = const {};
  bool _loaded = false;

  List<Brand> get brands => _brandList;
  bool get loaded => _loaded;

  String brandName(int id) => _brandById[id]?.name ?? '—';
  Brand? brand(int id) => _brandById[id];
  Client? client(int id) => _clientById[id];
  String clientName(int id) => _clientById[id]?.shortName ?? 'Клиент #$id';

  Future<void> load() async {
    try {
      final brands = await _brands.findAll();
      final clients = await _clients.findAll();
      _brandList = brands;
      _brandById = {for (final b in brands) b.id: b};
      _clientById = {for (final c in clients) c.id: c};
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Без справочников список всё равно работает: вместо названий
      // покажутся номера. Повторная попытка — при следующей загрузке.
    }
  }
}
