import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sheera/helpers/dbhelper.dart';
import 'package:sheera/models/laporan.dart';
import 'package:sheera/services/api_services.dart';
import 'package:geolocator/geolocator.dart';

class SyncService {
  final ApiServices _apiService = ApiServices();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> syncData(String token) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      print("Tidak ada koneksi internet. Sinkronisasi dibatalkan.");
      return;
    }

    print("Koneksi tersedia. Memulai proses sinkronisasi...");
    await _pushLaporanChanges(token);
    await _pullLaporanFromServer(token);
    print("Proses sinkronisasi selesai.");
  }

  Future<void> _pushLaporanChanges(String token) async {
    print("Mendorong perubahan laporan ke server...");
    final unsyncedLaporanMaps = await _dbHelper.getUnsyncedLaporan();
    
    if (unsyncedLaporanMaps.isEmpty) {
      print("Tidak ada data laporan lokal yang perlu di-push.");
      return;
    }

    for (var laporanMap in unsyncedLaporanMaps) {
      final laporan = Laporan.fromDbMap(laporanMap);

      try {
        if (laporan.actionStatus == 'CREATE') {
          print("Push CREATE untuk: ${laporan.judulLaporan}");

          File? imageFile;
          if (laporanMap['local_image_path'] != null && laporanMap['local_image_path'].isNotEmpty) {
            imageFile = File(laporanMap['local_image_path']);
            // Periksa apakah file tersebut benar-benar masih ada di perangkat
            if (!await imageFile.exists()) {
              print("Peringatan: File gambar di ${laporanMap['local_image_path']} tidak ditemukan. Mengirim tanpa gambar.");
              imageFile = null;
            }
          }

          final Position posisiLaporan = Position(
            latitude: laporan.latitude,
            longitude: laporan.longitude,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
          
          // API harus mengembalikan data yang baru dibuat, termasuk server_id
          final newLaporanFromServer = await _apiService.createLaporan(
            judul: laporan.judulLaporan,
            deskripsi: laporan.deskripsi,
            waktuKejadian: laporan.waktuKejadian,
            posisi: posisiLaporan,
            gambarBukti: imageFile,
            // latitude: laporan.latitude, 
            // longitude: laporan.longitude, 
            token: token,
          );
          
          await _dbHelper.updateLocalLaporanAfterCreate(
              laporan.id!, // id lokal
              newLaporanFromServer['id'] // id dari server
          );

        } else if (laporan.actionStatus == 'UPDATE') {
          print("Push UPDATE untuk: ${laporan.judulLaporan}");
          await _apiService.updateLaporan(
            id: laporan.serverId!,
            judul: laporan.judulLaporan,
            deskripsi: laporan.deskripsi,
            waktuKejadian: laporan.waktuKejadian,
            token: token,
          );
          await _dbHelper.markAsSynced(laporan.id!);

        } else if (laporan.actionStatus == 'DELETE') {
          print("Push DELETE untuk ID server: ${laporan.serverId}");
          await _apiService.deleteLaporan(id: laporan.serverId!, token: token);
          // Hapus permanen dari DB lokal setelah berhasil
          await _dbHelper.deleteLaporanPermanently(laporan.id!);
        }
      } catch (e) {
        print("Gagal push data laporan ID lokal ${laporan.id}: $e");
      }
    }
  }

  Future<void> _pullLaporanFromServer(String token) async {
    print("Menarik data laporan terbaru dari server...");
    try {
      final response = await _apiService.getLaporan(token);
      final List<dynamic> serverLaporanList = response['data'] ?? [];
      
      for (var laporanJson in serverLaporanList) {
        // Konversi JSON dari API menjadi objek LaporanModel
        final laporanModel = Laporan.fromApiJson(laporanJson);
        await _dbHelper.upsertLaporan(laporanModel.toDbMap());
      }
      
      print("Berhasil menarik dan menyimpan ${serverLaporanList.length} laporan dari server.");
    } catch (e) {
      print("Gagal menarik data dari server: $e");
    }
  }
}