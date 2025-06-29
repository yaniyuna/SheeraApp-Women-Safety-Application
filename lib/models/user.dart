import 'dart:convert';

// Fungsi helper untuk mengubah objek User menjadi string JSON (untuk disimpan ke SharedPreferences)
String userToJson(User data) => json.encode(data.toJson());

class User {
  final int id;
  final String namaLengkap;
  final String email;
  final String nomorTelepon;
  final String role; // 'user' atau 'admin'
  final DateTime? emailVerifiedAt; // Bisa null jika email belum diverifikasi
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor untuk membuat objek User
  User({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.nomorTelepon,
    required this.role,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor: "Pabrik" yang membuat objek User dari data Map/JSON
  // penting untuk mengubah respons API menjadi objek.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      namaLengkap: json['nama_lengkap'],
      email: json['email'],
      nomorTelepon: json['nomor_telepon'],
      role: json['role'],
      // Cek jika 'email_verified_at' null sebelum di-parse
      emailVerifiedAt: json['email_verified_at'] == null
          ? null
          : DateTime.parse(json['email_verified_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'email': email,
      'nomor_telepon': nomorTelepon,
      'role': role,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}