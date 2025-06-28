import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InputJobPage extends StatefulWidget {
  final int userId;
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

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      companyController.text = widget.job!['company'] ?? '';
      titleController.text = widget.job!['title'] ?? '';
      descController.text = widget.job!['description'] ?? '';
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
      });
      companyController.clear();
      titleController.clear();
      descController.clear();
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Lowongan' : 'Input Lowongan Baru',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: companyController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Perusahaan',
                      ),
                    ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Lowongan',
                      ),
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isEdit ? updateJob : addJob,
                      child: Text(
                        isEdit ? 'Simpan Perubahan' : 'Tambah Lowongan',
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
