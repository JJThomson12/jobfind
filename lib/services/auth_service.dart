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
      final user =
          await supabase
              .from('users')
              .select()
              .eq('email', email)
              .eq('password', password)
              .maybeSingle();

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

      // Validasi data user
      if (user['id'] == null || user['role'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Data user tidak valid. Silakan hubungi admin.'),
          ),
        );
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) {
            return HomeScreen(
              userId: user['id'],
              role: user['role'],
              userName: user['name'] ?? 'No Name',
              userEmail: user['email'],
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
      // Cek apakah email sudah ada
      final existing =
          await supabase
              .from('users')
              .select()
              .eq('email', email)
              .maybeSingle();
      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Email sudah digunakan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        return;
      }
      // Insert user baru (selalu job_seeker, admin manual)
      final userInsert =
          await supabase
              .from('users')
              .insert({
                'name': name,
                'email': email,
                'password': password, // Untuk produksi, hash password!
                'role': 'job_seeker',
              })
              .select()
              .single();
      final userId = userInsert['id'];
      // Insert ke job_seekers
      await supabase.from('job_seekers').insert({
        'id': userId,
        'experience': '',
        'education': '',
        'skills': '',
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
