class Unit {
  final int id;
  final String namaUnit;

  Unit({
    required this.id,
    required this.namaUnit,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      namaUnit: json['nama_unit'] ?? '',
    );
  }
}
