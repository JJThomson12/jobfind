import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationListPage extends StatefulWidget {
  final String adminId;
  const ApplicationListPage({Key? key, required this.adminId})
    : super(key: key);

  @override
  State<ApplicationListPage> createState() => _ApplicationListPageState();
}

class _ApplicationListPageState extends State<ApplicationListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> applications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    setState(() => _isLoading = true);
    final data = await supabase
        .from('applications')
        .select('*, jobs(*), job_seekers(*, users(*))')
        .eq('deleted_by_admin', false)
        .order('id', ascending: false);
    applications = List<Map<String, dynamic>>.from(data);
    setState(() => _isLoading = false);
  }

  Future<void> updateStatus(String appId, String status) async {
    await supabase
        .from('applications')
        .update({'status': status})
        .eq('id', appId);
    fetchApplications();
  }

  Future<void> deleteApplication(String appId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus lamaran ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirm == true) {
      // Soft delete: update deleted_by_admin
      await supabase
          .from('applications')
          .update({'deleted_by_admin': true})
          .eq('id', appId);
      // Cek apakah deleted_by_user juga true
      final app =
          await supabase
              .from('applications')
              .select('deleted_by_user')
              .eq('id', appId)
              .maybeSingle();
      if (app != null && app['deleted_by_user'] == true) {
        // Hapus permanen jika kedua kolom true
        await supabase.from('applications').delete().eq('id', appId);
      }
      fetchApplications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Lamaran Masuk')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : applications.isEmpty
              ? const Center(child: Text('Belum ada lamaran.'))
              : ListView.builder(
                itemCount: applications.length,
                itemBuilder: (context, idx) {
                  final app = applications[idx];
                  final job = app['jobs'] ?? {};
                  final seeker = app['job_seekers'] ?? {};
                  final user = seeker['users'] ?? {};
                  final photoUrl = seeker['photo_url'] ?? '';
                  final status = app['status'] ?? '-';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(job['title'] ?? '-'),
                      trailing:
                          (status == 'accepted' || status == 'rejected')
                              ? IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Hapus Lamaran',
                                onPressed:
                                    () =>
                                        deleteApplication(app['id'].toString()),
                              )
                              : null,
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (photoUrl != null && photoUrl != '')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(photoUrl),
                                radius: 32,
                              ),
                            ),
                          Text('Nama: ${user['name'] ?? '-'}'),
                          Text('Email: ${user['email'] ?? '-'}'),
                          Text('Pengalaman: ${seeker['experience'] ?? '-'}'),
                          Text('Pendidikan: ${seeker['education'] ?? '-'}'),
                          Text('Keahlian: ${seeker['skills'] ?? '-'}'),
                          Text('Status: ${status}'),
                          if (status == 'submitted')
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed:
                                      () => updateStatus(
                                        app['id'].toString(),
                                        'accepted',
                                      ),
                                  child: const Text('Terima'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed:
                                      () => updateStatus(
                                        app['id'].toString(),
                                        'rejected',
                                      ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Tolak'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
