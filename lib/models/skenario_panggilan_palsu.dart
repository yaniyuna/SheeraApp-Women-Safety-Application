class SkenarioPanggilanPalsu {
  final int id;
  final String judulSkenario;
  final String namaPenelepon;
  final String audioUrl;
  final String? teksSkrip; // Bisa null, jadi pakai '?'
  final bool isActive;

  const SkenarioPanggilanPalsu({
    required this.id,
    required this.judulSkenario,
    required this.namaPenelepon,
    required this.audioUrl,
    this.teksSkrip,
    required this.isActive,
  });

  factory SkenarioPanggilanPalsu.fromJson(Map<String, dynamic> json) {
    return SkenarioPanggilanPalsu(
      id: json["id"], // Langsung sebagai int
      judulSkenario: json["judul_skenario"],
      namaPenelepon: json["nama_penelepon"],
      audioUrl: json["audio_url"],
      teksSkrip: json["teks_skrip"], // Langsung sebagai String?
      // Konversi integer 0/1 dari API menjadi boolean true/false
      isActive: json["is_active"] == 1,
    );
  }

  // Fungsi toJson (biasanya tidak terlalu dibutuhkan di Flutter, tapi bagus untuk ada)
  Map<String, dynamic> toJson() => {
        "id": id,
        "judul_skenario": judulSkenario,
        "nama_penelepon": namaPenelepon,
        "audio_url": audioUrl,
        "teks_skrip": teksSkrip,
        "is_active": isActive ? 1 : 0, // Ubah boolean kembali menjadi integer
      };
}