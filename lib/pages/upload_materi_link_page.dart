import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UploadMateriLinkPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const UploadMateriLinkPage({super.key, this.docId, this.existingData});

  @override
  State<UploadMateriLinkPage> createState() => _UploadMateriLinkPageState();
}

class _UploadMateriLinkPageState extends State<UploadMateriLinkPage> {
  static const Color _primaryColor = Color(0xFF6A11CB);
  static const Color _buttonColor = Color(0xFF00BFA5);
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

  late final TextEditingController _titleController;
  late final TextEditingController _linkController;

  String _selectedType = 'Bahan Bacaan (PDF)';
  String _selectedCategory = 'Keamanan Digital';
  bool _isLoading = false;
  bool _isDraft = false;

  final List<String> _types = [
    'Bahan Bacaan (PDF)',
    'Presentasi (PPT/Canva)',
    'Infografis (Gambar)',
    'Video Pembelajaran',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      final data = widget.existingData!;
      _titleController = TextEditingController(text: data['title'] ?? '');
      _linkController = TextEditingController(text: data['link'] ?? '');
      _isDraft = data['isDraft'] == true || data['status'] == 'draft';

      final cat = data['category']?.toString();
      if (cat != null && _digitalLiteracyCategories.contains(cat)) {
        _selectedCategory = cat;
      }
      final type = data['type']?.toString();
      if (type != null && _types.contains(type)) {
        _selectedType = type;
      }
    } else {
      _titleController = TextEditingController();
      _linkController = TextEditingController();
    }
  }

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

  Future<void> _saveDraft() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      _showSnackBar(
        'Beri judul terlebih dahulu untuk menyimpan sebagai Draft!',
        color: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final link = _linkController.text.trim();

      final Map<String, dynamic> dataToSave = {
        'title': title,
        'category': _selectedCategory,
        'literacyScope': 'digital_literacy',
        'type': _selectedType,
        'link': link,
        'cover': _coverUrlByType(_selectedType),
        'isDraft': true,
        'status': 'draft',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('materi_siap_pakai')
            .doc(widget.docId)
            .update(dataToSave);

        if (!mounted) return;
        _showSnackBar('Draft berhasil diperbarui!', color: Colors.green);
        Navigator.pop(context, true);
      } else {
        dataToSave['createdAt'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance
            .collection('materi_siap_pakai')
            .add(dataToSave);

        if (!mounted) return;
        _showSnackBar(
          'Draft berhasil disimpan! Anda dapat mengedit dan melengkapinya kapan saja.',
          color: Colors.green,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menyimpan draft: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final link = _linkController.text.trim();

    if (title.isEmpty || link.isEmpty) {
      _showSnackBar('Judul dan Link wajib diisi untuk publikasi!');
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
      final Map<String, dynamic> dataToSave = {
        'title': title,
        'category': _selectedCategory,
        'literacyScope': 'digital_literacy',
        'type': _selectedType,
        'link': link,
        'cover': _coverUrlByType(_selectedType),
        'isDraft': false,
        'status': 'published',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('materi_siap_pakai')
            .doc(widget.docId)
            .update(dataToSave);

        if (!mounted) return;
        _showSnackBar('Materi berhasil dipublikasikan!', color: Colors.green);
        Navigator.pop(context, true);
      } else {
        dataToSave['createdAt'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance
            .collection('materi_siap_pakai')
            .add(dataToSave);

        if (!mounted) return;
        _showSnackBar(
          'Materi literasi digital berhasil ditambahkan!',
          color: Colors.green,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mempublikasikan: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.docId != null;
    final String pageTitle = isEditing
        ? (_isDraft ? 'Edit Draft Materi' : 'Edit Materi')
        : 'Tambah Materi Baru';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Draft banner
            if (_isDraft) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: Colors.amber.shade800, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status: DRAFT — Materi ini belum dapat dilihat oleh siswa. '
                        'Anda bisa mengedit dan melengkapinya kapan saja.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            Container(
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
                  const SizedBox(height: 35),

                  // Tombol Draft & Publikasikan
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Row(
                      children: [
                        // Tombol Simpan Draft
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _saveDraft,
                              icon: const Icon(Icons.bookmark_add_outlined, color: _primaryColor, size: 20),
                              label: const Text(
                                'SIMPAN DRAFT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _primaryColor,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _primaryColor, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tombol Publikasikan
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _publish,
                              icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                              label: Text(
                                isEditing && !_isDraft ? 'UPDATE' : 'PUBLIKASIKAN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _buttonColor,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}