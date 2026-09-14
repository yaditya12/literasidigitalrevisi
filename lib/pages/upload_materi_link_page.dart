import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UploadMateriLinkPage extends StatefulWidget {
  const UploadMateriLinkPage({super.key});

  @override
  State<UploadMateriLinkPage> createState() => _UploadMateriLinkPageState();
}

class _UploadMateriLinkPageState extends State<UploadMateriLinkPage> {
  static const Color _primaryColor = Color(0xFF6A11CB);
  static const String _bookCoverUrl =
      'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?q=80&w=500&auto=format&fit=crop';

  static const List<String> _digitalLiteracyCategories = [
    'Keamanan Digital',
    'Privasi dan Data Pribadi',
    'Etika Digital',
    'Mengenali Hoaks dan Cek Fakta',
    'Jejak Digital',
    'Cyberbullying',
    'Komunikasi Digital',
    'Transaksi Digital Aman',
    'Hak Cipta dan Plagiarisme Digital',
    'Kesehatan Digital',
    'Bijak Bermedia Sosial',
    'Kecakapan Menggunakan Teknologi',
  ];

  static const List<String> _digitalLiteracyKeywords = [
    'digital',
    'internet',
    'online',
    'daring',
    'media sosial',
    'akun',
    'password',
    'kata sandi',
    'otp',
    'privasi',
    'data pribadi',
    'keamanan',
    'cyber',
    'siber',
    'phishing',
    'scam',
    'hoaks',
    'hoax',
    'cek fakta',
    'berita palsu',
    'misinformasi',
    'disinformasi',
    'jejak digital',
    'cyberbullying',
    'etika',
    'netiket',
    'konten',
    'hak cipta',
    'plagiarisme',
    'transaksi',
    'e-wallet',
    'dompet digital',
    'marketplace',
    'literasi',
    'teknologi',
    'aplikasi',
    'email',
    'malware',
    'spam',
    'link',
    'tautan',
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  String _selectedType = 'Bahan Bacaan (PDF)';
  String _selectedCategory = 'Keamanan Digital';
  bool _isLoading = false;

  final List<String> _types = [
    'Bahan Bacaan (PDF)',
    'Presentasi (PPT/Canva)',
    'Infografis (Gambar)',
    'Video Pembelajaran',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  bool _containsDigitalLiteracyTopic(String value) {
    final text = value.toLowerCase();

    return _digitalLiteracyKeywords.any((keyword) {
      return text.contains(keyword.toLowerCase());
    });
  }

  String _coverUrlByType(String type) {
    return _bookCoverUrl;
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _saveMateri() async {
    final title = _titleController.text.trim();
    final link = _linkController.text.trim();

    if (title.isEmpty || link.isEmpty) {
      _showSnackBar('Judul dan Link wajib diisi!');
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme) {
      _showSnackBar('Format link tidak valid. Gunakan link lengkap https://...');
      return;
    }

    if (!_containsDigitalLiteracyTopic(title)) {
      _showSnackBar(
        'Materi link ditolak. Judul harus berkaitan dengan Literasi Digital.',
        color: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('materi_siap_pakai').add({
        'title': title,
        'category': _selectedCategory,
        'literacyScope': 'digital_literacy',
        'type': _selectedType,
        'link': link,
        'cover': _coverUrlByType(_selectedType),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);
      _showSnackBar(
        'Materi literasi digital berhasil ditambahkan!',
        color: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menyimpan: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Tambah Materi Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.cloud_upload_rounded,
                size: 70,
                color: _primaryColor,
              ),
              const SizedBox(height: 15),
              const Text(
                'Bagikan link materi Literasi Digital dari Google Drive, Canva, YouTube, atau sumber belajar lain.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: _primaryColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hanya materi Literasi Digital yang bisa disimpan.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Materi Literasi Digital',
                  hintText: 'Contoh: Cara Mengenali Hoaks',
                  prefixIcon: const Icon(Icons.title, color: _primaryColor),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: _primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Kategori Literasi Digital',
                  prefixIcon: const Icon(
                    Icons.verified_user_rounded,
                    color: _primaryColor,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: _primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                items: _digitalLiteracyCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Jenis Materi',
                  prefixIcon: const Icon(Icons.category, color: _primaryColor),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: _primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _linkController,
                maxLines: 2,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Link Materi',
                  hintText: 'https://...',
                  prefixIcon: const Icon(Icons.link, color: _primaryColor),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: _primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: _primaryColor.withOpacity(0.5),
                  ),
                  onPressed: _isLoading ? null : _saveMateri,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SIMPAN MATERI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}