import 'package:dio/dio.dart';
import 'dart:io'; // Untuk mengenali tipe data File
import 'package:geolocator/geolocator.dart'; // Untuk mengenali tipe data Position

class ApiServices {
  
  static const String baseUrl = 'http://192.168.43.45:8000';
  //static const String baseUrl = 'http://192.168.1.3:8000';

  final Dio _dio = Dio(BaseOptions(baseUrl: '$baseUrl/api'));

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

  Future<void> addKontak({
    required String namaKontak,
    required String nomorTelepon,
    required String token,
  }) async {
    try {
      await _dio.post(
        '/kontak-darurat',
        data: {
          'nama_kontak': namaKontak,
          'nomor_telepon': nomorTelepon,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      String errorMessage = 'Gagal menambahkan kontak. Silakan coba lagi.';

      if (e.response != null && e.response?.data != null) {
        var responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('errors')) {
              final errors = responseData['errors'] as Map<String, dynamic>;
              errorMessage = errors.values.first[0];
            } else if (responseData.containsKey('message')) {
              errorMessage = responseData['message'];
            }
        } 
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
    required int id,
    required String namaKontak,
    required String nomorTelepon,
    required String token,
  }) async {
    try {
      await _dio.put(
        '/kontak-darurat/$id',
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

  Future<Map<String, dynamic>> createLaporan({
    required String judul,
    required String deskripsi,
    required DateTime waktuKejadian,
    required Position posisi,
    File? gambarBukti,
    required String token, 
  }) async {
    final formData = FormData.fromMap({
      'judul_laporan': judul,
      'deskripsi': deskripsi,
      'waktu_kejadian': waktuKejadian.toIso8601String(),
      'latitude': posisi.latitude,
      'longitude': posisi.longitude,
    });

    if (gambarBukti != null) {
      formData.files.add(MapEntry(
        'bukti[]',
        await MultipartFile.fromFile(gambarBukti.path),
      ));
    }

    try {
      final response = await _dio.post(
        '/laporan',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data['data'];

    } on DioException catch (e) {
      throw Exception("Gagal mengirim laporan: ${e.response?.data}");
    }
  }
  
  Future<Map<String, dynamic>> getLaporan(String token, {
    int page = 1,
    String? searchQuery,
    int? statusId,
  }) async {
    try {
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
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      print(e);
      throw Exception('Gagal mengambil data laporan');
    }
  }

  Future<void> deleteLaporan({
    required int id,
    required String token,
  }) async {
    try {
      await _dio.delete(
        '/laporan/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception("Gagal menghapus laporan: ${e.response?.data['message'] ?? 'Error tidak diketahui'}");
    }
  }

  Future<void> updateLaporan({
    required int id,
    required String judul,
    required String deskripsi,
    required DateTime waktuKejadian,
    required String token,
  }) async {
    try {
      await _dio.post(
        '/laporan/$id',
        data: {
          'judul_laporan': judul,
          'deskripsi': deskripsi,
          'waktu_kejadian': waktuKejadian.toIso8601String(),
          '_method': 'PUT',
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
      return response.data; 
    } on DioException catch (e) {
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
    required int id,
    required int statusId,
    required String token,
  }) async {
    try {
      await _dio.patch(
        '/admin/laporan/$id/status',
        data: {
          'status_laporan_id': statusId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception("Gagal mengubah status: ${e.response?.data['message']}");
    }
  }
}