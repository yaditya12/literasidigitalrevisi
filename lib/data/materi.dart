
class MateriModel {
  final String? id;
  final String title;
  final String content;
  final List<Map<String, dynamic>> quiz;
  final String? sourceLink;

  MateriModel({
    this.id,
    required this.title,
    required this.content,
    required this.quiz,
    this.sourceLink,
  });
}

// Hapus 'final' agar list ini bisa dimanipulasi (ditambah/dihapus) saat aplikasi jalan
List<MateriModel> materiList = [
  // ---------- MATERI 1 ----------
  MateriModel(
    title: "Keamanan Digital",
    content:
        "Keamanan digital adalah upaya melindungi data pribadi saat menggunakan internet. "
        "Contoh: gunakan kata sandi kuat, aktifkan verifikasi dua langkah, "
        "hindari WiFi publik untuk transaksi penting.",
    quiz: [
      {
        "question": "Apa yang dimaksud dengan keamanan digital?",
        "options": [
          "Melindungi data pribadi di internet",
          "Menghapus semua data dari perangkat",
          "Menggunakan internet tanpa batas",
          "Mengganti perangkat setiap tahun"
        ],
        "answer": 0
      },
      {
        "question": "Contoh keamanan digital adalah…",
        "options": [
          "Menggunakan password 12345",
          "Aktifkan verifikasi dua langkah",
          "Bagikan data pribadi di media sosial",
          "Gunakan WiFi publik untuk login bank"
        ],
        "answer": 1
      },
      {
        "question": "WiFi publik sebaiknya tidak digunakan untuk…",
        "options": [
          "Streaming video",
          "Transaksi perbankan",
          "Browsing biasa",
          "Membaca berita"
        ],
        "answer": 1
      },
      {
        "question": "Password yang kuat adalah…",
        "options": [
          "Tanggal lahir",
          "Nama pacar",
          "Kombinasi huruf, angka, simbol",
          "Nomor HP"
        ],
        "answer": 2
      },
      {
        "question": "Tujuan utama keamanan digital adalah…",
        "options": [
          "Menghemat kuota",
          "Melindungi data pribadi",
          "Menambah followers",
          "Mempercepat internet"
        ],
        "answer": 1
      }
    ],
  ),

  // ---------- MATERI 2 ----------
  MateriModel(
    title: "Etika Bermedia Sosial",
    content:
        "Etika bermedia sosial adalah aturan dan norma saat berkomunikasi di internet. "
        "Contoh: hindari ujaran kebencian, gunakan bahasa sopan, hormati privasi orang lain.",
    quiz: [
      {
        "question": "Apa itu etika bermedia sosial?",
        "options": [
          "Aturan berkomunikasi online",
          "Cara membuat konten viral",
          "Cara mendapatkan like banyak",
          "Cara hack akun orang"
        ],
        "answer": 0
      },
      {
        "question": "Manakah yang termasuk etika yang baik?",
        "options": [
          "Menyebarkan data pribadi teman",
          "Menghina orang di komentar",
          "Menggunakan bahasa sopan",
          "Menyebar rumor"
        ],
        "answer": 2
      },
      {
        "question": "Kenapa etika digital penting?",
        "options": [
          "Agar terlihat keren",
          "Untuk menjaga interaksi yang sehat",
          "Untuk mendapat banyak follower",
          "Agar bisa bebas berkata apa saja"
        ],
        "answer": 1
      },
      {
        "question": "Contoh perilaku buruk di media sosial…",
        "options": [
          "Menyapa dengan ramah",
          "Menghormati privasi orang",
          "Ujaran kebencian",
          "Berbagi konten positif"
        ],
        "answer": 2
      },
      {
        "question": "Sebelum memposting sesuatu kita harus…",
        "options": [
          "Tidak perlu berpikir",
          "Cek dampak dan kebenaran",
          "Langsung viralkan",
          "Tag semua orang"
        ],
        "answer": 1
      }
    ],
  ),

  // ---------- MATERI 3 ----------
  MateriModel(
    title: "Mengenali Berita Palsu",
    content:
        "Berita palsu adalah informasi yang dibuat untuk menyesatkan. "
        "Cara mengenalinya: cek sumber, baca lebih dari satu media, "
        "hindari judul sensasional, dan periksa tanggal publikasi.",
    quiz: [
      {
        "question": "Berita palsu adalah…",
        "options": [
          "Informasi yang sudah lama",
          "Informasi dibuat untuk menyesatkan",
          "Berita dari TV nasional",
          "Berita tanpa gambar"
        ],
        "answer": 1
      },
      {
        "question": "Cara mengenali berita palsu…",
        "options": [
          "Percaya semua informasi",
          "Cek sumber dan kebenaran",
          "Percaya judul sensasional",
          "Forward tanpa membaca"
        ],
        "answer": 1
      },
      {
        "question": "Judul sensasional biasanya…",
        "options": [
          "Netral dan informatif",
          "Biasa saja",
          "Lebay dan memancing emosi",
          "Selalu benar"
        ],
        "answer": 2
      },
      {
        "question": "Sebelum membagikan berita kita harus…",
        "options": [
          "Baca lengkap dulu",
          "Forward cepat",
          "Percaya karena banyak share",
          "Tidak perlu cek sumber"
        ],
        "answer": 0
      },
      {
        "question": "Media terpercaya biasanya…",
        "options": [
          "Tidak jelas penulisnya",
          "Tidak punya alamat redaksi",
          "Memiliki standar jurnalistik",
          "Hanya upload di Facebook"
        ],
        "answer": 2
      }
    ],
  ),
];