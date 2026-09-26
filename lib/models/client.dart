/// Клиент автосервиса — владелец одного или нескольких автомобилей.
class Client {
  final int id;
  final String lastName;
  final String firstName;
  final String middleName;

  /// Телефон в виде «+7 (916) 123-45-67».
  final String phone;
  final String email;

  /// Персональная скидка на работы, в процентах.
  final int discount;
  final DateTime registeredAt;
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.lastName,
    required this.firstName,
    this.middleName = '',
    required this.phone,
    required this.email,
    this.discount = 0,
    required this.registeredAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get fullName =>
      [lastName, firstName, middleName].where((s) => s.isNotEmpty).join(' ');

  /// «Иванов И. П.» — для колонок таблицы и выпадающих списков.
  String get shortName {
    final initials = [
      firstName,
      middleName,
    ].where((s) => s.isNotEmpty).map((s) => '${s[0]}.').join(' ');
    return initials.isEmpty ? lastName : '$lastName $initials';
  }

  Client copyWith({
    int? id,
    String? lastName,
    String? firstName,
    String? middleName,
    String? phone,
    String? email,
    int? discount,
    DateTime? registeredAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id ?? this.id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      discount: discount ?? this.discount,
      registeredAt: registeredAt ?? this.registeredAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
