import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Untuk lokasi
import 'package:image_picker/image_picker.dart'; // Untuk gambar
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sheera/providers/auth_provider.dart';
//import 'package:sheera/services/api_services.dart'; // Untuk format tanggal
import 'package:sheera/models/laporan.dart';
import 'package:sheera/helpers/dbhelper.dart';

class ReportFormPage extends StatefulWidget {
  final Laporan? laporan;
  const ReportFormPage({super.key, this.laporan});

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  // GlobalKey untuk validasi form
  final _formKey = GlobalKey<FormState>();

  // Controller untuk input teks
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _dbHelper = DatabaseHelper();

  // Variabel untuk menyimpan data interaktif
  DateTime? _selectedDateTime;
  Position? _currentPosition;
  File? _pickedImage;

  // Variabel untuk state loading saat submit
  bool _isLoading = false;
  bool get _isEditing => widget.laporan != null;

  @override
  void initState() {
    super.initState();

    // Cek apakah ini mode edit
    if (_isEditing) {
      print('--- Form dalam mode EDIT untuk Laporan ID: ${widget.laporan!.id} ---');

      _titleController.text = widget.laporan!.judulLaporan;
      _descriptionController.text = widget.laporan!.deskripsi;

      _selectedDateTime = widget.laporan!.waktuKejadian;
      _currentPosition = Position(
        latitude: widget.laporan!.latitude,
        longitude: widget.laporan!.longitude,
        timestamp: widget.laporan!.waktuKejadian,
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0
      );

      if (widget.laporan!.localImagePath != null && widget.laporan!.localImagePath!.isNotEmpty) {
        _pickedImage = File(widget.laporan!.localImagePath!);
      }
    }
  }

  // Fungsi untuk menampilkan pemilih tanggal dan waktu
  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Fungsi untuk mendapatkan lokasi GPS saat ini
  Future<void> _getCurrentLocation() async {
    // Pastikan permission sudah dihandle
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Layanan lokasi tidak aktif. Mohon aktifkan.')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Izin lokasi ditolak permanen, tidak bisa meminta lagi.')));
      return;
    } 

    setState(() { _isLoading = true; });
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // Fungsi untuk memilih gambar
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _pickedImage = File(pickedFile.path);
                      });
                    }
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                   final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      setState(() {
                        _pickedImage = File(pickedFile.path);
                      });
                    }
                    Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveReportToLocalDb() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon pilih waktu kejadian.')));
      return;
    }
    
    // Untuk lokasi, saat create wajib, saat edit tidak
    if (!_isEditing && _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon ambil lokasi kejadian.')));
      return;
    }

    setState(() { _isLoading = true; });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isEditing) {
        final updatedLaporan = Laporan(
          id: widget.laporan!.id,
          serverId: widget.laporan!.serverId,
          judulLaporan: _titleController.text,
          deskripsi: _descriptionController.text,
          waktuKejadian: _selectedDateTime!,
          localImagePath: _pickedImage?.path, // Simpan path gambar yang mungkin baru
          actionStatus: 'UPDATE',
          isSynced: false,
          latitude: widget.laporan!.latitude,
          longitude: widget.laporan!.longitude,
          statusLaporanId: widget.laporan!.statusLaporanId,
          statusNama: widget.laporan!.statusNama,
          //userId: authProvider.user?.id ?? 0,
          createdAt: widget.laporan!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _dbHelper.upsertLaporan(updatedLaporan.toDbMap());

      } else {
        final newLaporan = Laporan(
          judulLaporan: _titleController.text,
          deskripsi: _descriptionController.text,
          waktuKejadian: _selectedDateTime!,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          localImagePath: _pickedImage?.path, // Simpan path gambar ke DB
          actionStatus: 'CREATE',
          isSynced: false,
          statusLaporanId: 1, // Status default 'Baru'
          statusNama: 'Baru',
          //userId: authProvider.user?.id ?? 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _dbHelper.upsertLaporan(newLaporan.toDbMap());
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Laporan disimpan secara lokal!'), backgroundColor: Colors.blue),
      );
      Navigator.of(context).pop(true); // Kirim sinyal 'true' untuk refresh

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan ke database lokal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Baru'),
        backgroundColor: Colors.pink[400],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Laporan',
                    hintText: 'Cth: Pencopetan di Halte Busway',
                    prefixIcon: Icon(Icons.drive_file_rename_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Kejadian',
                    hintText: 'Jelaskan kronologi, ciri-ciri pelaku, dll.',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                   validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.pink),
                    title: const Text('Waktu Kejadian'),
                    subtitle: Text(
                      _selectedDateTime == null 
                      ? 'Belum dipilih' 
                      : DateFormat('dd MMMM yyyy, HH:mm').format(_selectedDateTime!),
                    ),
                    onTap: _selectDateTime,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _getCurrentLocation, 
                          icon: const Icon(Icons.my_location), 
                          label: const Text('Gunakan Lokasi Saat Ini'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                        ),
                        if (_currentPosition != null) 
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Lokasi diambil: Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_pickedImage!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey),
                              Text('Ketuk untuk Unggah Bukti'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // --- Tombol Submit ---
                ElevatedButton(
                  // Panggil method _submitReport yang baru
                  onPressed: _isLoading ? null : _saveReportToLocalDb,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : Text(_isEditing ? 'Update Laporan' : 'Kirim Laporan'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}