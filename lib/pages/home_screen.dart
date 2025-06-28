import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jobfind/pages/profile_screen.dart';
import 'package:jobfind/pages/input_job.dart';
import 'package:jobfind/pages/login_screen.dart';
import 'package:jobfind/pages/application_list_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:jobfind/pages/job_detail.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String role;
  final String userName;
  final String userEmail;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.role,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> jobs = [];
  List<Map<String, dynamic>> filteredJobs = [];
  bool _isLoading = true;
  String? _userPhotoUrl;
  bool _hasNewApplications = false;
  bool _hasApplicationUpdates = false;
  List<Map<String, dynamic>> _applicationStatuses = [];

  @override
  void initState() {
    super.initState();
    fetchJobs();
    _fetchUserPhoto();
    _checkNewApplications();
    _checkApplicationStatus();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchJobs() async {
    await Future.delayed(const Duration(seconds: 1));
    final data = await supabase
        .from('jobs')
        .select()
        .order('id', ascending: false);
    if (mounted) {
      setState(() {
        jobs = List<Map<String, dynamic>>.from(data);
        filteredJobs = jobs;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserPhoto() async {
    if (widget.role == 'job_seeker') {
      final seekerData =
          await supabase
              .from('job_seekers')
              .select('photo_url')
              .eq('id', widget.userId)
              .maybeSingle();
      if (seekerData != null && mounted) {
        setState(() {
          _userPhotoUrl = seekerData['photo_url'];
        });
      }
    }
  }

  Future<void> _checkNewApplications() async {
    if (widget.role == 'admin') {
      try {
        // Check for applications with 'submitted' status (new applications)
        final newApplications = await supabase
            .from('applications')
            .select('id')
            .eq('status', 'submitted');

        if (mounted) {
          setState(() {
            _hasNewApplications = newApplications.isNotEmpty;
          });
        }
      } catch (e) {
        print('Error checking new applications: $e');
      }
    }
  }

  Future<void> _checkApplicationStatus() async {
    if (widget.role == 'job_seeker') {
      try {
        // Fetch applications with status 'accepted' or 'rejected'
        final applications = await supabase
            .from('applications')
            .select('''
              id,
              status,
              applied_at,
              jobs!inner(
                id,
                title,
                company
              )
            ''')
            .eq('job_seeker_id', widget.userId)
            .inFilter('status', ['accepted', 'rejected'])
            .order('applied_at', ascending: false);

        if (mounted) {
          setState(() {
            _applicationStatuses = List<Map<String, dynamic>>.from(
              applications,
            );
            _hasApplicationUpdates = applications.isNotEmpty;
          });
        }
      } catch (e) {
        print('Error checking application status: $e');
      }
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredJobs =
          jobs.where((job) {
            final title = (job['title'] ?? '').toString().toLowerCase();
            final company = (job['company'] ?? '').toString().toLowerCase();
            return title.contains(query) || company.contains(query);
          }).toList();
    });
  }

  void _goToProfile() {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: widget.userId),
      ),
    ).then((_) {
      // Refresh photo after returning from profile
      _fetchUserPhoto();
    });
  }

  void _goToInputJob() {
    Navigator.pop(context); // Close drawer
    if (widget.role == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  InputJobPage(userId: widget.userId, role: widget.role),
        ),
      ).then((_) => fetchJobs()); // Refresh jobs after returning
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses input lowongan hanya untuk admin!'),
        ),
      );
    }
  }

  void _goToApplicationList() {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationListPage(adminId: widget.userId),
      ),
    ).then((_) {
      // Clear notification after viewing applications
      _checkNewApplications();
    });
  }

  void _showApplicationStatus() {
    Navigator.pop(context); // Close drawer
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Status Lamaran'),
                if (_hasApplicationUpdates)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
            content: SizedBox(
              width: double.maxFinite,
              child:
                  _applicationStatuses.isEmpty
                      ? const Center(
                        child: Text(
                          'Belum ada update status lamaran',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _applicationStatuses.length,
                        itemBuilder: (context, index) {
                          final application = _applicationStatuses[index];
                          final job =
                              application['jobs'] as Map<String, dynamic>;
                          final status = application['status'] as String;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                status == 'accepted'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color:
                                    status == 'accepted'
                                        ? Colors.green
                                        : Colors.red,
                              ),
                              title: Text(
                                job['title'] ?? 'Unknown Position',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job['company'] ?? 'Unknown Company'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          status == 'accepted'
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            status == 'accepted'
                                                ? Colors.green
                                                : Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      status == 'accepted'
                                          ? 'DITERIMA'
                                          : 'DITOLAK',
                                      style: TextStyle(
                                        color:
                                            status == 'accepted'
                                                ? Colors.green
                                                : Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _signOut() async {
    Navigator.pop(context); // Close drawer
    await supabase.auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> applyJob(int jobId) async {
    try {
      await supabase.from('applications').insert({
        'job_id': jobId,
        'job_seeker_id': widget.userId,
        'status': 'submitted',
        'applied_at': DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lamaran berhasil dikirim!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal melamar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteJob(int jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus lowongan ini?',
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
        await supabase.from('jobs').delete().eq('id', jobId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lowongan berhasil dihapus!'),
            backgroundColor: Colors.green,
          ),
        );
        fetchJobs();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus lowongan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 20.0,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 16.0,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'JobFinder',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                widget.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(widget.userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundImage:
                    _userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) : null,
                backgroundColor: Colors.white,
                child:
                    _userPhotoUrl == null
                        ? const Icon(Icons.person, size: 35, color: Colors.grey)
                        : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (widget.role == 'job_seeker')
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profil Saya'),
                onTap: _goToProfile,
              ),
            if (widget.role == 'job_seeker')
              ListTile(
                leading: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (_hasApplicationUpdates)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: const Text('Status Lamaran'),
                onTap: _showApplicationStatus,
              ),
            if (widget.role == 'admin')
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('Input Lowongan'),
                onTap: _goToInputJob,
              ),
            if (widget.role == 'admin')
              ListTile(
                leading: Stack(
                  children: [
                    const Icon(Icons.assignment_turned_in_outlined),
                    if (_hasNewApplications)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: const Text('Daftar Lamaran'),
                onTap: _goToApplicationList,
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pekerjaan atau perusahaan...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? _buildShimmerEffect()
                    : filteredJobs.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_off_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Tidak ada lowongan ditemukan',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: fetchJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filteredJobs.length,
                        itemBuilder: (context, idx) {
                          final job = filteredJobs[idx];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => JobDetailPage(
                                          job: job,
                                          userId: widget.userId,
                                          role: widget.role,
                                        ),
                                  ),
                                );
                              },
                              splashColor: Colors.blue.withOpacity(0.08),
                              highlightColor: Colors.blue.withOpacity(0.04),
                              child: Padding(
                                padding: const EdgeInsets.all(22.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            job['title'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (widget.role == 'admin') ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blueAccent,
                                              size: 22,
                                            ),
                                            tooltip: 'Edit',
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) => InputJobPage(
                                                        userId: widget.userId,
                                                        role: widget.role,
                                                        job: job,
                                                      ),
                                                ),
                                              );
                                              fetchJobs();
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                              size: 22,
                                            ),
                                            tooltip: 'Hapus',
                                            onPressed:
                                                () => deleteJob(job['id']),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.business_center_outlined,
                                          size: 18,
                                          color: Colors.blueGrey.shade300,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          job['company'] ?? '-',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.blueGrey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      job['description'] ?? '-',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Lihat Detail',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 17,
                                          color: Colors.blue.shade700,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
