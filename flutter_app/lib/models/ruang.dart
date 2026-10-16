class Ruang {
  final int id;
  final String namaRuang;

  Ruang({
    required this.id,
    required this.namaRuang,
  });

  factory Ruang.fromJson(Map<String, dynamic> json) {
    return Ruang(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      namaRuang: json['nama_ruang'] ?? '',
    );
  }
}
