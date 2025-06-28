import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserApplicationListPage extends StatefulWidget {
  final String userId;
  const UserApplicationListPage({Key? key, required this.userId})
    : super(key: key);

  @override
  State<UserApplicationListPage> createState() =>
      _UserApplicationListPageState();
}

class _UserApplicationListPageState extends State<UserApplicationListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> applications = [];
  bool _isLoading = false;
  bool _hasNewUpdates = false;

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('applications')
          .select('*, jobs(*)')
          .eq('job_seeker_id', widget.userId)
          .eq('deleted_by_user', false)
          .order('applied_at', ascending: false);

      applications = List<Map<String, dynamic>>.from(data);

      // Check for new updates (accepted/rejected applications)
      _hasNewUpdates = applications.any(
        (app) => app['status'] == 'accepted' || app['status'] == 'rejected',
      );

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching applications: $e');
      setState(() => _isLoading = false);
    }
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
      try {
        // Soft delete: update deleted_by_user
        await supabase
            .from('applications')
            .update({'deleted_by_user': true})
            .eq('id', appId);
        // Cek apakah deleted_by_admin juga true
        final app =
            await supabase
                .from('applications')
                .select('deleted_by_admin')
                .eq('id', appId)
                .maybeSingle();
        if (app != null && app['deleted_by_admin'] == true) {
          // Hapus permanen jika kedua kolom true
          await supabase.from('applications').delete().eq('id', appId);
        }
        fetchApplications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lamaran berhasil dihapus!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus lamaran: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _statusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        text = 'DITERIMA';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'DITOLAK';
        icon = Icons.cancel;
        break;
      case 'submitted':
        color = Colors.orange;
        text = 'MENUNGGU';
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey;
        text = 'UNKNOWN';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Lamaran Saya'),
            if (_hasNewUpdates)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'BARU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchApplications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : applications.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada lamaran',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mulai melamar pekerjaan untuk melihat status lamaran Anda',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: fetchApplications,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: applications.length,
                  itemBuilder: (context, idx) {
                    final app = applications[idx];
                    final job = app['jobs'] ?? {};
                    final status = app['status'] ?? '-';
                    final appliedAt = app['applied_at'];
                    final isNewUpdate =
                        status == 'accepted' || status == 'rejected';

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border:
                              isNewUpdate
                                  ? Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                    width: 2,
                                  )
                                  : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  job['title'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isNewUpdate)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'BARU',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    job['company'] ?? '-',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dilamar: ${_formatDate(appliedAt)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _statusBadge(status),
                            ],
                          ),
                          trailing:
                              (status == 'accepted' || status == 'rejected')
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    tooltip: 'Hapus Lamaran',
                                    onPressed:
                                        () => deleteApplication(
                                          app['id'].toString(),
                                        ),
                                  )
                                  : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
