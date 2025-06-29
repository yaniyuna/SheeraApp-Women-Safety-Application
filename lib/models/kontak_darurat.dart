class KontakDarurat {
  final int id;
  final int userId;
  final String namaKontak;
  final String nomorTelepon;

  const KontakDarurat({
    required this.id,
    required this.userId,
    required this.namaKontak,
    required this.nomorTelepon,
  });

  // Factory constructor untuk mengubah JSON (Map) menjadi objek KontakDarurat
  factory KontakDarurat.fromJson(Map<String, dynamic> json) {
    return KontakDarurat(
      id: json["id"],
      userId: json["user_id"],
      // null-aware operator '??' untuk nilai default
      namaKontak: json["nama_kontak"] ?? 'Tanpa Nama',
      nomorTelepon: json["nomor_telepon"] ?? 'Tanpa Nomor',
    );
  }

  // Fungsi untuk mengubah objek menjadi Map (berguna untuk mengirim data ke API)
  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "nama_kontak": namaKontak,
        "nomor_telepon": nomorTelepon,
      };
}
