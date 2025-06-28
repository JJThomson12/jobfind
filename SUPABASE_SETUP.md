# Setup Supabase Storage untuk Upload Foto Profil

## 1. Membuat Bucket di Supabase

1. Buka dashboard Supabase Anda
2. Pilih project Anda
3. Pergi ke **Storage** di sidebar kiri
4. Klik **Create a new bucket**
5. Beri nama bucket: `profile`
6. Pilih **Public** untuk bucket type (agar foto bisa diakses publik)
7. Klik **Create bucket**

## 2. Konfigurasi Bucket Policy

Setelah bucket dibuat, Anda perlu mengatur policy untuk mengizinkan upload dan download:

### Policy untuk Upload (INSERT)
```sql
CREATE POLICY "Allow authenticated users to upload profile photos" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'profile' AND (storage.foldername(name))[1] = 'profile_photos');
```

### Policy untuk Download (SELECT)
```sql
CREATE POLICY "Allow public to view profile photos" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'profile');
```

### Policy untuk Update (UPDATE)
```sql
CREATE POLICY "Allow users to update their own profile photos" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'profile' AND (storage.foldername(name))[1] = 'profile_photos')
WITH CHECK (bucket_id = 'profile' AND (storage.foldername(name))[1] = 'profile_photos');
```

### Policy untuk Delete (DELETE)
```sql
CREATE POLICY "Allow users to delete their own profile photos" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'profile' AND (storage.foldername(name))[1] = 'profile_photos');
```

## 3. Cara Menambahkan Policy

1. Di dashboard Supabase, pergi ke **SQL Editor**
2. Copy dan paste policy di atas satu per satu
3. Klik **Run** untuk setiap policy

## 4. Struktur Folder

Foto profil akan disimpan dengan struktur:
```
profile/
└── profile_photos/
    ├── profile_1_1703123456789.jpg
    ├── profile_2_1703123456790.png
    └── ...
```

## 5. Testing

Setelah setup selesai, Anda bisa test upload foto di aplikasi:
1. Buka halaman profil
2. Tap pada area foto profil
3. Pilih "Kamera" atau "Galeri"
4. Pilih foto (tanpa crop)
5. Foto akan otomatis terupload ke bucket `profile`

## 6. Fitur Upload Foto

### ✅ **Fitur yang Tersedia:**
- Upload foto dari kamera
- Upload foto dari galeri
- Kompresi otomatis (70% quality)
- Resize otomatis (max 800x800 pixel)
- Validasi ukuran file (max 3MB)
- Error handling yang robust
- Timeout protection

### ❌ **Fitur yang Dihapus:**
- Crop gambar (dihapus untuk stabilitas)

## 7. Troubleshooting

### Error: "Bucket not found"
- Pastikan bucket `profile` sudah dibuat
- Pastikan nama bucket sesuai dengan yang ada di kode

### Error: "Access denied"
- Pastikan policy sudah ditambahkan dengan benar
- Pastikan user sudah login (authenticated)

### Error: "File too large"
- Foto akan otomatis dikompresi ke 70% quality
- Maksimal ukuran 800x800 pixel
- Maksimal file size 3MB

### Aplikasi Force Close saat Upload Foto

**Penyebab umum:**
1. **Memory overflow** - File terlalu besar
2. **Network timeout** - Koneksi internet lambat atau terputus
3. **Supabase bucket belum dibuat** - Bucket `profile` belum ada

**Solusi:**

1. **Restart aplikasi:**
   - Tutup aplikasi sepenuhnya
   - Buka kembali aplikasi

2. **Periksa koneksi internet:**
   - Pastikan koneksi internet stabil
   - Coba upload dengan koneksi WiFi

3. **Periksa bucket Supabase:**
   - Pastikan bucket `profile` sudah dibuat
   - Pastikan policy sudah diatur dengan benar

4. **Clear cache aplikasi:**
   - Settings > Apps > JobFind > Storage > Clear Cache

5. **Update aplikasi:**
   - Pastikan menggunakan versi terbaru

### Debug Mode
Jika masih force close, coba jalankan di debug mode:
```bash
flutter run --debug
```
Lalu cek log error di terminal untuk informasi lebih detail.

## 8. Keamanan

- Bucket `profile` bersifat public untuk memudahkan akses foto
- Jika ingin lebih aman, bisa menggunakan signed URL atau private bucket
- Setiap foto memiliki nama unik berdasarkan user ID dan timestamp

## 9. Permission

**Aplikasi ini TIDAK memerlukan permission khusus dari Android!**

- **Kamera dan Galeri**: Aplikasi menggunakan intent system Android yang tidak memerlukan permission runtime
- **Storage**: Menggunakan temporary file yang tidak memerlukan permission storage
- **Internet**: Hanya memerlukan permission internet untuk upload ke Supabase

Sistem Android modern akan menangani permission secara otomatis melalui intent system, sehingga user tidak perlu memberikan izin manual.

## 10. Optimasi Performa

### **Optimasi yang Diterapkan:**
- Kompresi gambar otomatis (70% quality)
- Resize gambar otomatis (max 800x800 pixel)
- Validasi ukuran file (max 3MB)
- Timeout protection (30 detik untuk baca file, 60 detik untuk upload)
- Delay kecil untuk mencegah force close
- Error handling yang komprehensif

### **Hasil Optimasi:**
- File size lebih kecil (hemat bandwidth)
- Upload lebih cepat
- Memory usage lebih rendah
- Stabilitas aplikasi meningkat
- Force close berkurang signifikan 