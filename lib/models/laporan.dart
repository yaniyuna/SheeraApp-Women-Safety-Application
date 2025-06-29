class Laporan {
  //Properti untuk Sinkronisasi Lokal
  int? id;
  int? serverId;
  bool isSynced;
  String? actionStatus;

  //Properti dari API
  //final int userId;
  final int statusLaporanId; 
  final String statusNama; 
  final String judulLaporan;
  final String deskripsi;
  final double latitude;
  final double longitude;
  final DateTime waktuKejadian;
  final String? localImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Laporan({
    this.id,
    this.serverId,
    this.isSynced = false,
    this.actionStatus,
    //required this.userId,
    required this.statusLaporanId, 
    required this.statusNama,    
    required this.judulLaporan,
    required this.deskripsi,
    required this.latitude,
    required this.longitude,
    required this.waktuKejadian,
    this.localImagePath,
    
    required this.createdAt,
    required this.updatedAt,
  });

  // Fungsi utk "meratakan" data dari objek status yang terpisah
  factory Laporan.fromApiJson(Map<String, dynamic> json) {
    // Ambil data status dari objek bersarang (nested object)
    final statusData = json['status_laporan'] as Map<String, dynamic>?;

    return Laporan(
      serverId: json["id"],
      //userId: json["user_id"],
      judulLaporan: json["judul_laporan"],
      deskripsi: json["deskripsi"],
      latitude: double.tryParse(json["latitude"].toString()) ?? 0.0,
      longitude: double.tryParse(json["longitude"].toString()) ?? 0.0,
      waktuKejadian: DateTime.parse(json["waktu_kejadian"]),
      
      createdAt: DateTime.parse(json["created_at"]),
      updatedAt: DateTime.parse(json["updated_at"]),
      isSynced: true,
      //Denormalisasi
      statusLaporanId: statusData?['id'] ?? 0, // Ambil id dari nested object
      statusNama: statusData?['nama_status'] ?? 'N/A', // Ambil nama dari nested object
    );
  }

  // Fungsi untuk mengubah objek Laporan menjadi Map untuk disimpan ke SQFlite
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'server_id': serverId,
      'judul_laporan': judulLaporan,
      'deskripsi': deskripsi,
      'latitude': latitude,
      'longitude': longitude,
      'waktu_kejadian': waktuKejadian.toIso8601String(),
      'local_image_path': localImagePath,

      'is_synced': isSynced ? 1 : 0,
      'action_status': actionStatus,
      'status_laporan_id': statusLaporanId,
      'status_nama': statusNama,
    };
  }

  // Fungsi untuk membuat objek Laporan dari Map database (SQFlite)
  factory Laporan.fromDbMap(Map<String, dynamic> map) {
    return Laporan(
      id: map['id'],
      serverId: map['server_id'],
      isSynced: map['is_synced'] == 1,
      actionStatus: map['action_status'],
      judulLaporan: map['judul_laporan'],
      deskripsi: map['deskripsi'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      waktuKejadian: DateTime.parse(map['waktu_kejadian']),
      localImagePath: map['local_image_path'],
      
      // Ambil data status langsung dari kolomny
      statusLaporanId: map['status_laporan_id'] ?? 0,
      statusNama: map['status_nama'] ?? 'Lokal',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}