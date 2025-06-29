class StatusLaporan {
  final int id;
  final String namaStatus;

  const StatusLaporan({
    required this.id,
    required this.namaStatus,
  });

  factory StatusLaporan.fromJson(Map<String, dynamic> json) {
    return StatusLaporan(
      id: json["id"], 
      namaStatus: json["nama_status"] ?? 'Status Tidak Diketahui',
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "nama_status": namaStatus,
      };
}