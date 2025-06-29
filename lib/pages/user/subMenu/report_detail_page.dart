import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class ReportDetailPage extends StatelessWidget {
  final Map<String, dynamic> laporan;
  const ReportDetailPage({super.key, required this.laporan});

  @override
  Widget build(BuildContext context) {
    // Parsing data
    final judul = laporan['judul_laporan'] ?? 'Tanpa Judul';
    final deskripsi = laporan['deskripsi'] ?? 'Tidak ada deskripsi.';
    final status = laporan['status_laporan']?['nama_status'] ?? 'N/A';
    final waktuKejadian = DateTime.parse(laporan['waktu_kejadian']);
    final lat = double.tryParse(laporan['latitude'].toString()) ?? 0.0;
    final lon = double.tryParse(laporan['longitude'].toString()) ?? 0.0;
    
    // Cek apakah ada bukti foto
    final List<dynamic> buktiList = laporan['bukti_laporans'] ?? [];
    final String? fotoUrl = buktiList.isNotEmpty ? buktiList[0]['file_url'] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lon),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lon),
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.calendar_today_outlined, 'Waktu Kejadian', DateFormat('d MMMM yyyy, HH:mm').format(waktuKejadian)),
                  _buildDetailRow(Icons.flag_outlined, 'Status', status),
                  const Divider(height: 32),
                  const Text('Deskripsi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(deskripsi, style: const TextStyle(fontSize: 16, height: 1.5)),

                  if (fotoUrl != null) ...[
                    const Divider(height: 32),
                    const Text('Bukti Foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'http://192.168.43.45:8000$fotoUrl', 
                        fit: BoxFit.cover,
                        // Tampilkan loading indicator saat gambar dimuat
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        // Tampilkan icon error jika gambar gagal dimuat
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                        },
                      ),
                    ),
                  ],

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat baris detail agar rapi
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}