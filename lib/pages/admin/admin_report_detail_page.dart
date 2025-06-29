import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sheera/providers/auth_provider.dart';
import 'package:sheera/services/api_services.dart';

class AdminReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> laporan;
  const AdminReportDetailPage({super.key, required this.laporan});

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {
  final ApiServices _apiService = ApiServices();
  late int _selectedStatusId;
  bool _isUpdating = false;

  // Opsi status untuk dropdown
  final Map<String, int> _statusOptions = {
    'Baru': 1,
    'Diverifikasi': 2,
    'Ditindaklanjuti': 3,
    'Selesai': 4,
  };

  @override
  void initState() {
    super.initState();
    _selectedStatusId = widget.laporan['status_laporan_id'];
  }

  // Fungsi untuk memanggil API dan mengubah status
  Future<void> _updateStatus() async {
    setState(() { _isUpdating = true; });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      await _apiService.updateLaporanStatus(
        id: widget.laporan['id'],
        statusId: _selectedStatusId,
        token: authProvider.token!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status berhasil diubah!'), backgroundColor: Colors.green),
      );
      // Kirim sinyal 'true' saat kembali untuk memberitahu halaman daftar utk refresh
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() { _isUpdating = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // Parsing data
    final judul = widget.laporan['judul_laporan'] ?? 'Tanpa Judul';
    final deskripsi = widget.laporan['deskripsi'] ?? 'Tidak ada deskripsi.';
    final pelapor = widget.laporan['user']?['nama_lengkap'] ?? 'Anonim';
    final waktuKejadian = DateTime.parse(widget.laporan['waktu_kejadian']);
    final lat = double.tryParse(widget.laporan['latitude'].toString()) ?? 0.0;
    final lon = double.tryParse(widget.laporan['longitude'].toString()) ?? 0.0;
    
    final List<dynamic> buktiList = widget.laporan['bukti_laporans'] ?? [];
    final String? fotoUrl = buktiList.isNotEmpty ? buktiList[0]['file_url'] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Laporan')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lon),
                  initialZoom: 16.0,
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
                        child: const Icon(Icons.location_pin, color: Colors.red, size: 50),
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
                  _buildInfoRow(Icons.person_outline, 'Dilaporkan oleh', pelapor),
                  _buildInfoRow(Icons.calendar_today_outlined, 'Waktu Kejadian', DateFormat('d MMMM yyyy, HH:mm').format(waktuKejadian)),
                  const Divider(height: 32),
                  //utk foto
                  if (fotoUrl != null) ...[
                    const Text('Bukti Foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${ApiServices.baseUrl}$fotoUrl',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (context, error, stack) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                      ),
                    ),
                    const Divider(height: 32),
                  ],
          
                  const Text('Deskripsi Lengkap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(deskripsi, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const Divider(height: 32),

                  //ubh status
                  const Text('Tindakan Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: _selectedStatusId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _statusOptions.entries.map((entry) {
                        return DropdownMenuItem<int>(value: entry.value, child: Text(entry.key));
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) setState(() { _selectedStatusId = newValue; });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _updateStatus,
                    icon: _isUpdating ? const SizedBox.shrink() : const Icon(Icons.save_as_outlined),
                    label: _isUpdating
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : const Text('Simpan Status'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat baris info yang rapi
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$title\n', style: const TextStyle(color: Colors.grey)),
              TextSpan(text: value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ]),
          )),
        ],
      ),
    );
  }
}

