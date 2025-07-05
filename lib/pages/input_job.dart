import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../services/storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class InputJobPage extends StatefulWidget {
  final String userId;
  final String role;
  final Map<String, dynamic>? job;
  const InputJobPage({
    Key? key,
    required this.userId,
    required this.role,
    this.job,
  }) : super(key: key);

  @override
  State<InputJobPage> createState() => _InputJobPageState();
}

class _InputJobPageState extends State<InputJobPage> {
  final supabase = Supabase.instance.client;
  final companyController = TextEditingController();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      companyController.text = widget.job!['company'] ?? '';
      titleController.text = widget.job!['title'] ?? '';
      descController.text = widget.job!['description'] ?? '';
      _imageUrl = widget.job!['image_url'];
    }
  }

  Future<void> pickAndUploadJobImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null) return;
    String url;
    if (kIsWeb) {
      // Web: upload ke bucket 'company'
      final bytes = await picked.readAsBytes();
      final fileName =
          'company_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.name)}';
      url = await StorageService.uploadFileWeb(bytes, 'company', fileName);
      setState(() {
        _selectedImage = null;
        _imageUrl = url;
      });
    } else {
      // Mobile: upload dari File
      final file = File(picked.path);
      url = await StorageService.uploadFile(
        file,
        'company',
        'company_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}',
      );
      setState(() {
        _selectedImage = file;
        _imageUrl = url;
      });
    }
  }

  Future<void> addJob() async {
    setState(() => _isLoading = true);
    try {
      await supabase.from('jobs').insert({
        'user_id': widget.userId,
        'company': companyController.text.trim(),
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'image_url': _imageUrl,
      });
      companyController.clear();
      titleController.clear();
      descController.clear();
      setState(() {
        _selectedImage = null;
        _imageUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lowongan berhasil ditambahkan!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambah lowongan: ${e.toString()}')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> updateJob() async {
    if (widget.job == null) return;
    setState(() => _isLoading = true);
    try {
      await supabase
          .from('jobs')
          .update({
            'company': companyController.text.trim(),
            'title': titleController.text.trim(),
            'description': descController.text.trim(),
            'image_url': _imageUrl,
          })
          .eq('id', widget.job!['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lowongan berhasil diperbarui!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui lowongan: ${e.toString()}')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Input Lowongan')),
        body: const Center(
          child: Text('Hanya admin yang dapat menginput lowongan.'),
        ),
      );
    }
    final isEdit = widget.job != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Lowongan' : 'Input Lowongan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: companyController,
              decoration: const InputDecoration(labelText: 'Perusahaan'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul Pekerjaan'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            const SizedBox(height: 16),
            Text(
              'Gambar Pekerjaan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_imageUrl != null) Image.network(_imageUrl!, height: 120),
            if (_imageUrl == null)
              Container(
                height: 120,
                width: 120,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: pickAndUploadJobImage,
              icon: const Icon(Icons.upload),
              label: const Text('Upload Gambar'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (isEdit ? updateJob : addJob),
                child: Text(isEdit ? 'Update' : 'Tambah'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
