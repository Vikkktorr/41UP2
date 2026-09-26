import 'car.dart';
import 'client.dart';

/// Карточка клиента вместе с его автомобилями.
class ClientDetails {
  final Client client;
  final List<Car> cars;

  const ClientDetails({required this.client, required this.cars});
}
