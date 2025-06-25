import 'dart:async'; // <-- Import untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart'; // <-- Pastikan package ini ada
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:share_plus/share_plus.dart';

class Mappage extends StatefulWidget {
  const Mappage({super.key});

  @override
  State<Mappage> createState() => _MappageState();
}

class _MappageState extends State<Mappage> {
  // Controller untuk mengontrol peta (menggerakkan, zoom, dll)
  final MapController _mapController = MapController();

  // Variabel untuk menyimpan lokasi terkini dari GPS
  Position? _currentPosition;

  // Variabel untuk mengelola langganan stream lokasi
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationStream(); // Mulai mendengarkan lokasi saat halaman dibuka
  }

  @override
  void dispose() {
    // SANGAT PENTING: Hentikan langganan saat halaman ditutup
    // untuk mencegah kebocoran memori dan menghemat baterai.
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // Fungsi untuk memulai stream lokasi
  void _startLocationStream() {
    // Opsi untuk akurasi dan interval update
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update jika lokasi berubah minimal 10 meter
    );

    // Mulai "berlangganan" data posisi dari Geolocator
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) {
      if (position != null) {
        // Setiap kali ada data posisi baru yang masuk...
        setState(() {
          // 1. Perbarui state posisi saat ini
          _currentPosition = position;

          // 2. Perintahkan peta untuk bergerak ke lokasi baru
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            16.0, // Level zoom saat bergerak
          );
        });
      }
    });
  }

  Future<void> _onMyLocationMarkerTapped() async {
    if (_currentPosition == null) return;

    // Tampilkan loading spinner kecil di pop-up
    showModalBottomSheet(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );

    try {
      // 1. Ubah koordinat menjadi alamat menggunakan geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      String address = "Lokasi tidak diketahui";
      if (placemarks.isNotEmpty) {
        final pm = placemarks[0];
        // Gabungkan detail alamat menjadi satu string yang rapi
        address = "${pm.street}, ${pm.subLocality}, ${pm.locality}, ${pm.subAdministrativeArea}, ${pm.administrativeArea}";
      }

      // Tutup loading spinner
      if (mounted) Navigator.of(context).pop();

      // 2. Tampilkan pop-up (Bottom Sheet) dengan detail alamat dan tombol share
      _showShareBottomSheet(address);

    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Tutup loading jika error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mendapatkan detail alamat: $e")),
      );
    }
  }

  // Fungsi untuk menampilkan Bottom Sheet
  void _showShareBottomSheet(String address) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Lokasi Anda Saat Ini", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(address, style: const TextStyle(fontSize: 16))),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // 3. Panggil fungsi share saat tombol ditekan
                  _shareLocation(address);
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text("Bagikan Lokasi Saya"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk membagikan lokasi menggunakan package share_plus
  void _shareLocation(String address) {
    if (_currentPosition == null) return;
    
    final lat = _currentPosition!.latitude;
    final lon = _currentPosition!.longitude;
    
    // Buat link Google Maps
    final String googleMapsUrl = 'https://maps.google.com/?q=$lat,$lon';
    
    // Buat teks yang akan dibagikan
    final String shareText = 
        'TOLONG! SAYA DALAM KEADAAN DARURAT.\n\n'
        'Lokasi saya saat ini ada di:\n$address\n\n'
        'Lihat di peta:\n$googleMapsUrl';
    
    // Panggil fungsi share
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Keamanan (Live)'),
      ),
      body: FlutterMap(
        // Hubungkan map controller kita ke widget FlutterMap
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(-6.2088, 106.8456), // Posisi awal Jakarta
          initialZoom: 13.0,
        ),
        children: [
          // Lapisan Peta Dasar
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.sheera', // Ganti dengan package Anda
          ),

          // Lapisan Penanda (Markers)
          MarkerLayer(
            markers: [
              // Tambahkan marker lain jika perlu, misal titik aman, dll.

              // Marker untuk lokasi pengguna saat ini (dinamis)
              // Marker ini hanya akan muncul jika _currentPosition tidak null
              if (_currentPosition != null)
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  child: GestureDetector(
                    onTap: _onMyLocationMarkerTapped, // Panggil fungsi saat marker ditekan
                    child: Column(
                      children: [
                        const Icon(Icons.my_location, color: Colors.blue, size: 30.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Text('Anda', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}