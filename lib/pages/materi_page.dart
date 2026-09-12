import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/materi.dart';
import '../services/quiz_attempt_service.dart';
import 'detail_materi_page.dart';
import 'quiz_page.dart';

class MateriPage extends StatelessWidget {
  final MateriModel materi;

  const MateriPage({super.key, required this.materi});

  @override
  Widget build(BuildContext context) {
    // --- LOGIKA CEK TIPE ---
    // Jika content kosong, berarti ini adalah MODE KUIS SAJA (Tantangan)
    bool isQuizOnly = materi.content.trim().isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), 
      appBar: AppBar(
        title: const Text("Pilih Aktivitas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF6A11CB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ================================
          // HEADER MATERI (BANNER)
          // ================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                // Icon berubah sesuai tipe
                Icon(
                  isQuizOnly ? Icons.psychology_alt : Icons.menu_book_rounded, 
                  color: Colors.white, size: 60
                ),
                const SizedBox(height: 15),
                Text(
                  materi.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isQuizOnly ? "Tantangan Kuis Langsung" : "Selesaikan materi untuk membuka kuis",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ================================
          // PILIHAN MENU (BACA & KUIS)
          // ================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // --- TOMBOL BACA MATERI (HANYA MUNCUL JIKA BUKAN KUIS SAJA) ---
                if (!isQuizOnly) ...[
                  _buildActivityCard(
                    context: context,
                    title: "Baca Materi",
                    desc: "Pelajari teori dan konsep dasar.",
                    icon: Icons.chrome_reader_mode_rounded,
                    color: Colors.indigo.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetailMateriPage(materi: materi)),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // --- TOMBOL MULAI KUIS (SELALU MUNCUL) ---
                _buildActivityCard(
                  context: context,
                  title: "Mulai Kuis",
                  desc: "Uji kemampuanmu sekarang.",
                  icon: Icons.psychology_rounded,
                  color: Colors.green.shade400,
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Silakan login terlebih dahulu.')),
                      );
                      return;
                    }

                    final canStart = await QuizAttemptService.canStartQuiz(
                      userId: user.uid,
                      quizId: materi.id ?? materi.title.trim(),
                    );

                    if (!context.mounted) return;
                    if (!canStart) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(getQuizAttemptLimitMessage()),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QuizPage(materi: materi)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER UNTUK KARTU PILIHAN
  Widget _buildActivityCard({
    required BuildContext context,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            // Ikon Bulat
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            // Teks Keterangan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Panah Kecil
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}