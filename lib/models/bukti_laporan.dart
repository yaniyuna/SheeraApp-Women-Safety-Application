class BuktiLaporan {
  final int id;
  final int laporanId;
  final String fileUrl;
  final String? tipeFile; // opsional karena mungkin tidak selalu ada

  // constructor 'const' untuk performa
  const BuktiLaporan({
    required this.id,
    required this.laporanId,
    required this.fileUrl,
    this.tipeFile,
  });

  // Factory constructor untuk mengubah JSON (Map) menjadi objek BuktiLaporan
  factory BuktiLaporan.fromJson(Map<String, dynamic> json) {
    return BuktiLaporan(
      id: json["id"], 
      laporanId: json["laporan_id"],
      fileUrl: json["file_url"] ?? '', 
      tipeFile: json["tipe_file"], 
    );
  }

  // Fungsi untuk mengubah objek menjadi Map
  Map<String, dynamic> toJson() => {
        "id": id,
        "laporan_id": laporanId,
        "file_url": fileUrl,
        "tipe_file": tipeFile,
      };
}
