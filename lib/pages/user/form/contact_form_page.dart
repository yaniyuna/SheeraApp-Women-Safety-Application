// lib/screens/kontak/contact_form_page.dart (Nama file baru)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheera/providers/auth_provider.dart';
import 'package:sheera/services/api_services.dart';

class ContactFormPage extends StatefulWidget {
  final Map<String, dynamic>? contact;
  const ContactFormPage({super.key, this.contact});

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiService = ApiServices();
  bool _isLoading = false;

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.contact!['nama_kontak'];
      _phoneController.text = widget.contact!['nomor_telepon'];
    }
  }

  // 5. Buat fungsi yang bisa menangani create dan update
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String successMessage = '';
      
      try {
        // Cek mode halaman
        if (_isEditing) {
          await _apiService.updateKontak(
            id: widget.contact!['id'], 
            namaKontak: _nameController.text,
            nomorTelepon: _phoneController.text,
            token: authProvider.token!,
          );
          successMessage = 'Kontak berhasil diperbarui!';
        } else {
          await _apiService.addKontak(
            namaKontak: _nameController.text,
            nomorTelepon: _phoneController.text,
            token: authProvider.token!,
          );
          successMessage = 'Kontak berhasil ditambahkan!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Kontak Darurat' : 'Tambah Kontak Darurat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Kontak', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor Telepon', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Nomor telepon tidak boleh kosong' : null,
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                    : Text(_isEditing ? 'Update Kontak' : 'Simpan Kontak', style: const TextStyle(fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}