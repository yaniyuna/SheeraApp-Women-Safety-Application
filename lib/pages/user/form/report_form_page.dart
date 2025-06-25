import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Untuk lokasi
import 'package:image_picker/image_picker.dart'; // Untuk gambar
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sheera/providers/auth_provider.dart';
import 'package:sheera/services/api_services.dart'; // Untuk format tanggal

class ReportFormPage extends StatefulWidget {
  final Map<String, dynamic>? laporan;
  //const ReportFormPage({super.key});
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
    // 4. Jika dalam mode edit, isi form dengan data yang sudah ada
    if (_isEditing) {
      _titleController.text = widget.laporan!['judul_laporan'];
      _descriptionController.text = widget.laporan!['deskripsi'];
      // Konversi string tanggal dari API menjadi objek DateTime
      _selectedDateTime = DateTime.parse(widget.laporan!['waktu_kejadian']);
      
    }
  }

  // --- LOGIKA UNTUK FITUR INTERAKTIF ---

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

  // Ganti nama method agar lebih jelas, dan perbarui logikanya
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Cek data interaktif
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon pilih waktu kejadian.')));
      return;
    }
    
    // Untuk lokasi, saat edit, kita mungkin tidak mewajibkan ambil lokasi baru
    if (!_isEditing && _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon ambil lokasi kejadian.')));
      return;
    }

    setState(() { _isLoading = true; });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiServices();
    String successMessage = '';
    
    try {
      if (_isEditing) {
        // --- LOGIKA UNTUK UPDATE ---
        await apiService.updateLaporan(
          id: widget.laporan!['id'],
          judul: _titleController.text,
          deskripsi: _descriptionController.text,
          waktuKejadian: _selectedDateTime!,
          token: authProvider.token!,
        );
        successMessage = 'Laporan berhasil diperbarui!';
      } else {
        // --- LOGIKA UNTUK CREATE (YANG SUDAH ADA) ---
        await apiService.createLaporan(
          judul: _titleController.text,
          deskripsi: _descriptionController.text,
          waktuKejadian: _selectedDateTime!,
          posisi: _currentPosition!,
          gambarBukti: _pickedImage,
          token: authProvider.token!,
        );
        successMessage = 'Laporan berhasil dikirim!';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true); // Kirim 'true' untuk sinyal refresh

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
                // --- Input Judul ---
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

                // --- Input Deskripsi ---
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
                
                // --- Pemilih Tanggal & Waktu ---
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
                
                // --- Pengambil Lokasi ---
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
                
                // --- Pengunggah Bukti ---
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
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  // Teks tombol dinamis
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