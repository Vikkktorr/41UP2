import '../models/brand.dart';
import 'network_simulator.dart';
import 'seed_data.dart';

abstract interface class BrandRepository {
  Future<List<Brand>> findAll();
}

class InMemoryBrandRepository implements BrandRepository {
  InMemoryBrandRepository(this._net);

  final NetworkSimulator _net;

  @override
  Future<List<Brand>> findAll() async {
    await _net.roundTrip();
    return [...seedBrands]..sort((a, b) => a.name.compareTo(b.name));
  }
}
