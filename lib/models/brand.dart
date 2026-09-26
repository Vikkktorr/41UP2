/// Марка автомобиля — справочник, на который ссылается [Car.brandId].
class Brand {
  final int id;
  final String name;
  final String country;

  const Brand({required this.id, required this.name, required this.country});
}
