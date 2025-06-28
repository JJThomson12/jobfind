import 'package:jobfind/pages/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Email atau password salah',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        return;
      }
      // Ambil data user dari tabel users
      final userData =
          await supabase.from('users').select().eq('id', user.id).maybeSingle();
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Data user tidak ditemukan di database.'),
          ),
        );
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) {
            return HomeScreen(
              userId: user.id,
              role: userData['role'],
              userName: userData['name'] ?? 'No Name',
              userEmail: userData['email'],
            );
          },
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString(), style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      // Register ke Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal registrasi. Coba email lain.'),
          ),
        );
        return;
      }
      // Insert ke tabel users
      await supabase.from('users').insert({
        'id': user.id,
        'name': name,
        'email': email,
        'role': 'job_seeker',
      });
      // Insert ke tabel job_seekers
      await supabase.from('job_seekers').insert({
        'id': user.id,
        'experience': '',
        'education': '',
        'skills': '',
        'photo_url': '',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Registrasi berhasil! Silakan login.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      Navigator.pop(context); // Kembali ke halaman login
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString(), style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  // Tambahkan fungsi untuk mengirim ulang email konfirmasi
  Future<void> resendConfirmationEmail(
    String email,
    BuildContext context,
  ) async {
    try {
      await supabase.auth.resend(type: OtpType.signup, email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Email konfirmasi telah dikirim ulang.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Gagal mengirim ulang email: ${e.toString()}',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}
