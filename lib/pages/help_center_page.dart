import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  // --- DATA DUMMY PERTANYAAN & JAWABAN ---
  final List<Map<String, String>> faqList = const [
    {
      "question": "Bagaimana cara mengganti foto profil?",
      "answer": "Pergi ke menu 'Profil Saya', lalu klik menu 'Edit Profil'. Di sana Anda bisa menekan ikon kamera pada foto profil untuk mengganti gambar dari galeri Anda."
    },
    {
      "question": "Bagaimana cara mengikuti Kuis?",
      "answer": "Di halaman beranda (Home), pilih menu 'Join Quiz' atau pilih salah satu materi di bawah. Jika kuis memerlukan kode, masukkan Kode Unik yang diberikan oleh guru Anda."
    },
    {
      "question": "Apakah kuis bisa dikerjakan berulang kali?",
      "answer": "Ya. Kuis bisa dikerjakan terus menerus untuk belajar. Yang dihitung untuk poin adalah nilai terbaik yang Anda capai pada kuis tersebut."
    },
    {
      "question": "Bagaimana perhitungan sistem Peringkat?",
      "answer": "Peringkat dihitung berdasarkan total poin yang Anda kumpulkan. Semakin banyak kuis yang Anda kerjakan dengan nilai tinggi, semakin tinggi peringkat Anda di Leaderboard."
    },
    {
      "question": "Apakah saya bisa menghapus akun?",
      "answer": "Saat ini fitur hapus akun mandiri belum tersedia demi keamanan data akademik. Silakan hubungi admin sekolah atau guru jika Anda perlu menghapus akun."
    },
    {
      "question": "Aplikasi mengalami error/crash, apa solusinya?",
      "answer": "Cobalah untuk menutup aplikasi dan membukanya kembali. Pastikan juga koneksi internet Anda stabil. Jika masalah berlanjut, hubungi tim IT sekolah."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Background abu muda
      appBar: AppBar(
        title: const Text("Pusat Bantuan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: faqList.length,
        itemBuilder: (context, index) {
          final item = faqList[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
              ],
            ),
            child: Theme(
              // Menghilangkan garis divider bawaan ExpansionTile
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: Colors.blue, size: 22),
                ),
                title: Text(
                  item['question']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                children: [
                  Text(
                    item['answer']!,
                    style: const TextStyle(color: Colors.black54, height: 1.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}