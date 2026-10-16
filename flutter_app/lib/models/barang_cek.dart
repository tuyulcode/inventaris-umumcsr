class BarangCek {
  final int id;
  final String formattedCode;
  final String namaBarang;
  final String kondisi;
  final bool isChecked;
  final String? kondisiTemuan;
  final String? statusReview;
  final int? idPetugas;
  final String? namaPetugas;

  BarangCek({
    required this.id,
    required this.formattedCode,
    required this.namaBarang,
    required this.kondisi,
    required this.isChecked,
    this.kondisiTemuan,
    this.statusReview,
    this.idPetugas,
    this.namaPetugas,
  });

  factory BarangCek.fromJson(Map<String, dynamic> json) {
    return BarangCek(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      formattedCode: json['formatted_code'] ?? '',
      namaBarang: json['nama_barang'] ?? '',
      kondisi: json['kondisi'] ?? '-',
      isChecked: json['is_checked'] == true,
      kondisiTemuan: json['kondisi_temuan'],
      statusReview: json['status_review'],
      idPetugas: json['id_petugas'] == null
          ? null
          : (json['id_petugas'] is int
              ? json['id_petugas']
              : int.tryParse(json['id_petugas'].toString())),
      namaPetugas: json['nama_petugas'],
    );
  }
}
