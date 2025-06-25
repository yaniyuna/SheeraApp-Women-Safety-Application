import 'package:dio/dio.dart';
import 'dart:io'; // Untuk mengenali tipe data File
import 'package:geolocator/geolocator.dart'; // Untuk mengenali tipe data Position

class ApiServices {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.43.45:8000/api',
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json', 
  }, 
  ));

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {

      if (e.response != null) {
        print('--- SERVER MERESPONS DENGAN ERROR ---');
        print('Status Code: ${e.response?.statusCode}');
        print('Data Response: ${e.response?.data}');
        
        String errorMessage = "Terjadi error dari server (Kode: ${e.response?.statusCode})";

        if (e.response?.data is Map && e.response?.data['message'] != null) {
           errorMessage = e.response?.data['message'];
        }
        throw Exception(errorMessage);

      } else {
        print('--- SERVER TIDAK MERESPONS ---');
        print('Error Dio: ${e.message}');
        throw Exception('Gagal terhubung ke server. Periksa koneksi dan alamat IP.');
      }
    }
  }

  Future<Map<String, dynamic>> register({
    required String namaLengkap,
    required String email,
    required String nomorTelepon,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
       final response = await _dio.post('/register', data: {
        'nama_lengkap': namaLengkap,
        'email': email,
        'nomor_telepon': nomorTelepon,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      return response.data;
    } on DioException catch (e) {
       if (e.response != null) {
         throw Exception("Gagal mendaftar: ${e.response?.data}");
       } else {
         throw Exception('Gagal terhubung ke server. Periksa koneksi Anda.');
       }
    }
  }

  Future<void> logout(String token) async {
    try {
      await _dio.post(
        '/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('Request logout berhasil dikirim ke server.');
    } catch (e) {
      print('Gagal mengirim request logout ke server. Error: $e');
    }
  }

  Future<List<dynamic>> getKontak(String token) async {
    try {
      final response = await _dio.get(
        '/kontak-darurat',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      print(e);
      return [];
    }
  }

  // lib/services/api_service.dart

  // GANTI SELURUH METHOD addKontak ANDA DENGAN INI
  Future<void> addKontak({
    required String namaKontak,
    required String nomorTelepon,
    required String token,
  }) async {
    try {
      // Bagian ini tidak berubah, hanya mengirim data
      await _dio.post(
        '/kontak-darurat',
        data: {
          'nama_kontak': namaKontak,
          'nomor_telepon': nomorTelepon,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      // --- PERBAIKAN UTAMA ADA DI BLOK CATCH INI ---
      String errorMessage = 'Gagal menambahkan kontak. Silakan coba lagi.';

      if (e.response != null && e.response?.data != null) {
        var responseData = e.response!.data;

        // Cek jika respons adalah Map (kasus error validasi normal dari Laravel)
        if (responseData is Map<String, dynamic>) {
            // Cek jika ada key 'errors' untuk pesan validasi yang lebih spesifik
            if (responseData.containsKey('errors')) {
              final errors = responseData['errors'] as Map<String, dynamic>;
              // Ambil pesan error pertama dari field pertama yang error
              errorMessage = errors.values.first[0];
            } else if (responseData.containsKey('message')) {
              errorMessage = responseData['message'];
            }
        } 
        // Cek jika respons adalah List (kasus yang terjadi pada Anda)
        else if (responseData is List) {
          if (responseData.isNotEmpty && responseData[0] is Map) {
             final errorMap = responseData[0] as Map<String, dynamic>;
             errorMessage = errorMap['message'] ?? 'Error tidak diketahui dari server.';
          }
        }
      } else {
        errorMessage = 'Gagal terhubung ke server. Periksa koneksi Anda.';
      }

      throw Exception(errorMessage);
    }
  }

  Future<void> updateKontak({
    required int id, // Kita butuh ID kontak yang akan diupdate
    required String namaKontak,
    required String nomorTelepon,
    required String token,
  }) async {
    try {
      await _dio.put(
        '/kontak-darurat/$id', // Kirim request PUT ke endpoint dengan ID
        data: {
          'nama_kontak': namaKontak,
          'nomor_telepon': nomorTelepon,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception("Gagal mengupdate kontak: ${e.response?.data['message']}");
    }
  }

  Future<void> deleteKontak({
    required int id,
    required String token,
  }) async {
    try {
      await _dio.delete(
        '/kontak-darurat/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception("Gagal menghapus kontak: ${e.response?.data['message']}");
    }
  }

  // 1. FUNGSI UNTUK MENGIRIM LAPORAN BARU (TERMASUK FILE)
  Future<void> createLaporan({
    required String judul,
    required String deskripsi,
    required DateTime waktuKejadian,
    required Position posisi,
    File? gambarBukti, // Gambar bersifat opsional
    required String token,
  }) async {
    // Untuk mengirim file, kita harus menggunakan FormData, bukan Map biasa
    final formData = FormData.fromMap({
      'judul_laporan': judul,
      'deskripsi': deskripsi,
      'waktu_kejadian': waktuKejadian.toIso8601String(),
      'latitude': posisi.latitude,
      'longitude': posisi.longitude,
    });

    // Jika ada gambar yang dipilih, lampirkan ke form data
    if (gambarBukti != null) {
      formData.files.add(MapEntry(
        'bukti[]', // Nama field ini harus cocok dengan yang di backend Laravel
        await MultipartFile.fromFile(gambarBukti.path),
      ));
    }

    try {
      await _dio.post(
        '/laporan',
        data: formData, // Kirim data sebagai FormData
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      // Penanganan error
      throw Exception("Gagal mengirim laporan: ${e.response?.data}");
    }
  }

  // 2. FUNGSI UNTUK MENGAMBIL DAFTAR LAPORAN MILIK USER
  Future<Map<String, dynamic>> getLaporan(String token, {
  int page = 1, // Halaman default adalah 1
  String? searchQuery,
  int? statusId,
}) async {
  try {
    // Siapkan semua parameter yang mungkin dikirim
    final Map<String, dynamic> queryParams = {
      'page': page,
    };
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }
    if (statusId != null) {
      queryParams['status_id'] = statusId;
    }

    final response = await _dio.get(
      '/laporan',
      queryParameters: queryParams, // Kirim parameter ke API
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    // Kembalikan seluruh objek respons dari Laravel, bukan hanya data
    // karena kita butuh info 'last_page', dll.
    return response.data;
  } catch (e) {
    print(e);
    throw Exception('Gagal mengambil data laporan');
  }
}


  // 3. FUNGSI UNTUK MENGHAPUS LAPORAN
  Future<void> deleteLaporan({
    required int id,
    required String token,
  }) async {
    try {
      // Kirim request DELETE ke endpoint dengan ID
      await _dio.delete(
        '/laporan/$id', // Pastikan endpoint ini cocok dengan route di Laravel
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      // Lempar kembali pesan error yang jelas
      throw Exception("Gagal menghapus laporan: ${e.response?.data['message'] ?? 'Error tidak diketahui'}");
    }
  }

  Future<void> updateLaporan({
    required int id,
    required String judul,
    required String deskripsi,
    required DateTime waktuKejadian,
    // Note: Mengirim file saat update lebih kompleks, untuk saat ini kita fokus pada data teks
    required String token,
  }) async {
    try {
      // Laravel bisa menangani PUT request via POST dengan field _method
      // Ini lebih mudah untuk konsistensi, terutama jika nanti ada file.
      await _dio.post(
        '/laporan/$id', // Endpoint update biasanya menyertakan ID
        data: {
          'judul_laporan': judul,
          'deskripsi': deskripsi,
          'waktu_kejadian': waktuKejadian.toIso8601String(),
          '_method': 'PUT', // Memberitahu Laravel ini adalah request PUT
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception("Gagal mengupdate laporan: ${e.response?.data}");
    }
  }

  Future<List<dynamic>> getSkenarios(String token) async {
    try {
      final response = await _dio.get(
        '/skenario-panggilan',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // API Anda mengembalikan List secara langsung
      return response.data; 
    // Kode BARU yang lebih baik
    } on DioException catch (e) {
      // Sekarang kita lempar kembali errornya agar bisa ditangkap oleh UI
      print("Error saat getSkenarios: ${e.response?.data ?? e.message}");
      throw Exception('Gagal memuat skenario panggilan.');
    }
  }

  Future<Map<String, dynamic>> getCommunityAlerts(String token, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/laporan',
        queryParameters: {
          'view': 'community',
          'page': page,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      throw Exception('Gagal memuat community alert');
    }
  }

  Future<void> updateLaporanStatus({
    required int id, // ID laporan yang akan diubah
    required int statusId, // ID status yang baru
    required String token,
  }) async {
    try {
      // Kita gunakan PATCH karena hanya mengubah sebagian data
      await _dio.patch(
        '/admin/laporan/$id/status', // Endpoint khusus admin
        data: {
          'status_laporan_id': statusId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      // Lempar error agar bisa ditangani di UI
      throw Exception("Gagal mengubah status: ${e.response?.data['message']}");
    }
  }

}