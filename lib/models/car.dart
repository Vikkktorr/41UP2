import 'fuel_type.dart';

/// Автомобиль клиента. Основная сущность списка.
///
/// Связи: [brandId] — многие к одному с маркой, [clientId] — многие к одному
/// с владельцем.
class Car {
  final int id;

  /// Госномер в виде «А123ВС777», без пробелов.
  final String plate;
  final String vin;
  final int brandId;
  final String model;
  final int year;

  /// Пробег в километрах.
  final int mileage;
  final FuelType fuel;
  final int clientId;
  final DateTime? deletedAt;

  const Car({
    required this.id,
    required this.plate,
    required this.vin,
    required this.brandId,
    required this.model,
    required this.year,
    required this.mileage,
    required this.fuel,
    required this.clientId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Car copyWith({
    int? id,
    String? plate,
    String? vin,
    int? brandId,
    String? model,
    int? year,
    int? mileage,
    FuelType? fuel,
    int? clientId,
    DateTime? deletedAt,
    // Без этого флага нельзя отличить «не менять deletedAt» от «сбросить
    // в null»: в обоих случаях параметр deletedAt равен null.
    bool clearDeletedAt = false,
  }) {
    return Car(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      vin: vin ?? this.vin,
      brandId: brandId ?? this.brandId,
      model: model ?? this.model,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      fuel: fuel ?? this.fuel,
      clientId: clientId ?? this.clientId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
