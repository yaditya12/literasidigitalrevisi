import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/materi.dart';
import 'quiz_page.dart';

class DetailMateriPage extends StatelessWidget {
  final MateriModel materi;

  const DetailMateriPage({super.key, required this.materi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header dengan Gradien yang mengecil saat di-scroll
          _buildSliverAppBar(context),

          // Area Konten Materi
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indikator Estimasi Waktu (Visual saja)
                  _buildReadingMeta(),
                  
                  const SizedBox(height: 25),

                  if (materi.sourceLink != null && materi.sourceLink!.trim().isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.tryParse(materi.sourceLink!.trim());
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.attach_file_rounded),
                        label: const Text('Buka File Materi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A11CB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Isi Materi dengan Typography yang nyaman
                  Text(
                    materi.content,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8, // Memberikan ruang antar baris agar mudah dibaca
                      color: Color(0xFF2D3436),
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 30),

                  // Kotak Ajakkan untuk Kuis
                  _buildQuizCallToAction(context),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget AppBar Terintegrasi Gradien ---
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          materi.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // --- Widget Meta Informasi (Estimasi Baca) ---
  Widget _buildReadingMeta() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF6A11CB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              Icon(Icons.timer_outlined, size: 14, color: Color(0xFF6A11CB)),
              SizedBox(width: 5),
              Text("5 Menit Baca", 
                style: TextStyle(color: Color(0xFF6A11CB), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: 15),
        const Text("•", style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 15),
        const Text("Digital Literacy", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  // --- Widget Tombol Aksi Kuis ---
  Widget _buildQuizCallToAction(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.indigo.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 40),
          const SizedBox(height: 10),
          const Text(
            "Materi Selesai!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            "Uji pemahamanmu dengan mengerjakan kuis.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Pindah ke halaman kuis
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => QuizPage(materi: materi)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text("MULAI KUIS", 
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }
}