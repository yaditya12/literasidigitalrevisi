import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/materi.dart'; // Import Model Data
import 'materi_page.dart';    // Import Halaman Tujuan

class JoinQuizPage extends StatefulWidget {
  const JoinQuizPage({super.key});

  @override
  State<JoinQuizPage> createState() => _JoinQuizPageState();
}

class _JoinQuizPageState extends State<JoinQuizPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  // --- FUNGSI GABUNG KUIS ---
  void _joinQuiz() async {
    String code = _codeController.text.trim().toUpperCase(); // Pastikan Huruf Besar

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan kode kuis terlebih dahulu!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Cari Materi berdasarkan 'joinCode'
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('materi')
          .where('joinCode', isEqualTo: code)
          .limit(1) // Kita hanya butuh 1 hasil
          .get();

      if (!mounted) return;

      // 2. Cek apakah ditemukan
      if (snapshot.docs.isNotEmpty) {
        // --- KODE DITEMUKAN ---
        var doc = snapshot.docs.first;
        var data = doc.data() as Map<String, dynamic>;

        final bool isDraft = data['isDraft'] == true || data['status'] == 'draft';
        if (isDraft) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orange,
              content: Text("Kuis ini masih berstatus DRAFT dan belum dipublikasikan oleh Guru."),
            ),
          );
          return;
        }

        // Konversi ke Model
        MateriModel joinedMateri = MateriModel(
          id: doc.id,
          title: data['title'] ?? "Tanpa Judul",
          content: data['content'] ?? "",
          quiz: List<Map<String, dynamic>>.from(data['quiz'] ?? []),
          isDraft: false,
        );

        // Navigasi ke Materi Page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MateriPage(materi: joinedMateri)),
        );
        
        // Bersihkan input setelah berhasil
        _codeController.clear();

      } else {
        // --- KODE TIDAK DITEMUKAN ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Kode tidak ditemukan. Silakan cek kembali."),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Gabung Kuis", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustrasi Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6A11CB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vpn_key_rounded, size: 60, color: Color(0xFF6A11CB)),
            ),
            const SizedBox(height: 30),

            const Text(
              "Masukkan Kode Unik",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Minta kode 6 digit kepada gurumu untuk\nmulai mengerjakan kuis.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Input Kode
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters, // Otomatis Huruf Besar
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 5),
              decoration: InputDecoration(
                hintText: "X7Z9A2",
                hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 5),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            const SizedBox(height: 40),

            // Tombol Gabung
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _joinQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A11CB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: const Color(0xFF6A11CB).withOpacity(0.4),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("GABUNG SEKARANG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}