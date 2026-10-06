import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_page.dart';
import 'quiz_history_page.dart';
import 'help_center_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _sedangMenghapus = false;
  
  void _tampilkanKonfirmasiHapus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Hapus Akun?"),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus akun ini secara permanen? Semua data poin dan riwayat Anda akan hilang total.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _hapusAkunPermanen(context);
            },
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _hapusAkunPermanen(BuildContext context) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      
      if (user != null) {
        setState(() {
          _sedangMenghapus = true;
        });

        final uidTemp = user.uid;

        // 1. Log out paksa dulu dari Firebase Auth. 
        // Ini akan memicu Auth Gate di main.dart untuk langsung melempar aplikasi ke LoginPage secara otomatis!
        await auth.signOut();

        // 2. Bersihkan datanya di Firestore setelah logout (menggunakan UID cadangan)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uidTemp)
            .delete()
            .timeout(const Duration(seconds: 5));

        // 3. Hapus akun Autentikasinya dari server (jika diperlukan)
        // Catatan: Jika user.delete() gagal karena butuh login ulang, data Firestore-nya setidaknya sudah bersih terhapus.
        try {
          await user.delete().timeout(const Duration(seconds: 5));
        } catch (_) {
          // Abaikan jika auth delete gagal akibat token expired, karena user sudah ter-signout aman
        }

        // 4. Sebagai pengaman ganda, paksa pindah halaman manual ke LoginPage jika AuthGate macet
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sedangMenghapus = false;
        });
      }
      
      String pesanEror = "Terjadi kesalahan saat menghapus akun.";
      if (e is FirebaseException) {
        pesanEror = "Kendala Database: ${e.message}";
      } else if (e is TimeoutException) {
        pesanEror = "Koneksi internet tidak stabil.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanEror), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sedangMenghapus) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 20),
              Text(
                "Menghapus akun Anda...\nMohon tunggu sebentar.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;

    // Jika user bernilai null, langsung arahkan ke halaman login menggunakan rootNavigator agar menjebol tab bar
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()), 
          (route) => false,
        );
      });
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          // PERBAIKAN: Jika dokumen Firestore tidak ditemukan saat proses hapus berjalan, jangan tampilkan teks eror diam.
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 10),
                  Text("Sinkronisasi Akun..."),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          String username = data['username'] ?? "User";
          String email = data['email'] ?? "-";
          String? photoUrl = data['photoUrl'];
          int myPoints = data['points'] ?? 0;
          
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').where('points', isGreaterThan: myPoints).get(),
            builder: (context, rankSnapshot) {
              String rankStr = "...";
              if (rankSnapshot.hasData) {
                rankStr = "#${rankSnapshot.data!.docs.length + 1}";
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(4), 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
                            ? NetworkImage(photoUrl)
                            : NetworkImage("https://ui-avatars.com/api/?name=$username&background=random&size=128&color=fff"),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: _buildColorCard(
                            "Total Poin", 
                            "$myPoints", 
                            Icons.stars_rounded, 
                            const Color(0xFFFFF3E0), 
                            Colors.orange 
                          )
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildColorCard(
                            "Peringkat", 
                            rankStr, 
                            Icons.emoji_events_rounded, 
                            const Color(0xFFEDE7F6), 
                            const Color(0xFF6A11CB) 
                          )
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),

                    _buildSettingsTile(context, "Edit Profil", Icons.edit_outlined, Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(currentUsername: username, currentEmail: email, currentPhotoUrl: photoUrl)));
                    }),
                    _buildSettingsTile(context, "Riwayat Kuis", Icons.history_edu, Colors.purple, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => QuizHistoryPage(userRole: data['role'])));
                    }),
                    _buildSettingsTile(context, "Pusat Bantuan", Icons.support_agent, Colors.green, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterPage()));
                    }),
                    
                    const SizedBox(height: 20),
                    _buildSettingsTile(context, "Hapus Akun", Icons.person_off_rounded, Colors.red, () {
                      _tampilkanKonfirmasiHapus(context);
                    }),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildColorCard(String label, String value, IconData icon, Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 32),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor)),
          Text(label, style: TextStyle(fontSize: 12, color: accentColor.withOpacity(0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: color == Colors.red ? Colors.red : Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
    );
  }
}