import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final experienceController = TextEditingController();
  final educationController = TextEditingController();
  final skillsController = TextEditingController();
  String? photoUrl;
  String? name;
  String? email;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() => _isLoading = true);
    // Ambil data dari users
    final userData =
        await supabase
            .from('users')
            .select('name, email')
            .eq('id', widget.userId)
            .maybeSingle();
    // Ambil data dari job_seekers
    final seekerData =
        await supabase
            .from('job_seekers')
            .select()
            .eq('id', widget.userId)
            .maybeSingle();
    if (userData != null) {
      name = userData['name'];
      email = userData['email'];
    }
    if (seekerData != null) {
      experienceController.text = seekerData['experience'] ?? '';
      educationController.text = seekerData['education'] ?? '';
      skillsController.text = seekerData['skills'] ?? '';
      photoUrl = seekerData['photo_url'];
    }
    setState(() => _isLoading = false);
  }

  Future<void> saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('job_seekers')
          .update({
            'experience': experienceController.text.trim(),
            'education': educationController.text.trim(),
            'skills': skillsController.text.trim(),
            'photo_url': photoUrl,
          })
          .eq('id', widget.userId);
      // Jika tidak ada baris yang diupdate, lakukan insert
      if (response == null || (response is List && response.isEmpty)) {
        await supabase.from('job_seekers').insert({
          'id': widget.userId,
          'experience': experienceController.text.trim(),
          'education': educationController.text.trim(),
          'skills': skillsController.text.trim(),
          'photo_url': photoUrl,
        });
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui profil: ${e.toString()}')),
      );
    }
  }

  Future<void> pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final file = File(picked.path);
    final fileName =
        'profile_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
    final storagePath = 'profile_photos/$fileName';
    final bytes = await file.readAsBytes();
    final res = await supabase.storage
        .from('profile')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = supabase.storage.from('profile').getPublicUrl(storagePath);
    setState(() {
      photoUrl = url;
    });
    // Simpan ke database
    await supabase
        .from('job_seekers')
        .update({'photo_url': url})
        .eq('id', widget.userId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Foto berhasil diupload!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: const Color(0xFFF4F6F8),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            if (name != null)
                              Text(
                                name!,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (email != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 12.0,
                                  top: 2.0,
                                ),
                                child: Text(
                                  email!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            if (photoUrl != null && photoUrl!.isNotEmpty)
                              CircleAvatar(
                                radius: 48,
                                backgroundImage: NetworkImage(
                                  Uri.encodeFull(photoUrl!),
                                ),
                                onBackgroundImageError: (_, __) {},
                              )
                            else
                              const CircleAvatar(
                                radius: 48,
                                child: Icon(Icons.person, size: 48),
                              ),
                            TextButton.icon(
                              onPressed: pickAndUploadPhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Upload Foto'),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: experienceController,
                              decoration: InputDecoration(
                                labelText: 'Pengalaman Kerja',
                                prefixIcon: const Icon(Icons.work_outline),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: educationController,
                              decoration: InputDecoration(
                                labelText: 'Pendidikan',
                                prefixIcon: const Icon(Icons.school_outlined),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: skillsController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Keahlian',
                                prefixIcon: const Icon(Icons.star_outline),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
