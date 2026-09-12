import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/materi.dart';

class AddMateriPage extends StatefulWidget {
  final MateriModel? materi;
  final String? docId;
  final bool isQuizOnly;

  const AddMateriPage({
    super.key,
    this.materi,
    this.docId,
    this.isQuizOnly = false,
  });

  @override
  State<AddMateriPage> createState() => _AddMateriPageState();
}

class _AddMateriPageState extends State<AddMateriPage> {
  static const Color _primaryColor = Color(0xFF6A11CB);
  static const Color _buttonColor = Color(0xFF00BFA5);

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
    'sosial media',
    'akun',
    'password',
    'kata sandi',
    'otp',
    'verifikasi',
    'privasi',
    'data pribadi',
    'keamanan',
    'cyber',
    'siber',
    'phishing',
    'scam',
    'penipuan',
    'hoaks',
    'hoax',
    'cek fakta',
    'fakta',
    'berita palsu',
    'misinformasi',
    'disinformasi',
    'jejak digital',
    'cyberbullying',
    'perundungan',
    'etika',
    'netiket',
    'komentar',
    'konten',
    'hak cipta',
    'plagiarisme',
    'transaksi',
    'e-wallet',
    'dompet digital',
    'marketplace',
    'pinjol',
    'literasi',
    'teknologi',
    'gadget',
    'perangkat',
    'aplikasi',
    'browser',
    'email',
    'malware',
    'virus',
    'spam',
    'unduhan',
    'link',
    'tautan',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _sourceLinkController;

  String _selectedCategory = 'Keamanan Digital';
  List<Map<String, dynamic>> tempQuiz = [];
  bool _isLoading = false;
  bool _isLoadingExistingCategory = false;

  @override
  void initState() {
    super.initState();

    if (widget.materi != null) {
      _titleController = TextEditingController(text: widget.materi!.title);
      _contentController = TextEditingController(text: widget.materi!.content);
      _sourceLinkController = TextEditingController(text: widget.materi!.sourceLink ?? '');
      tempQuiz = widget.materi!.quiz.map((questionData) {
        final options = _safeOptions(questionData['options']);
        final answer = _safeAnswer(questionData['answer']);

        return {
          'question': (questionData['question'] ?? '').toString(),
          'options': options,
          'answer': answer,
        };
      }).toList();

      if (widget.docId != null) {
        _loadExistingCategory();
      }
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _sourceLinkController = TextEditingController();
      tempQuiz = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _sourceLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCategory() async {
    setState(() => _isLoadingExistingCategory = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('materi')
          .doc(widget.docId)
          .get();

      final data = doc.data();
      final category = data?['category']?.toString();

      if (!mounted) return;

      if (category != null && _digitalLiteracyCategories.contains(category)) {
        setState(() {
          _selectedCategory = category;
          _isLoadingExistingCategory = false;
        });
      } else {
        setState(() => _isLoadingExistingCategory = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingExistingCategory = false);
    }
  }

  static List<String> _safeOptions(dynamic value) {
    final List<String> options = value is List
        ? value.map((item) => item?.toString() ?? '').toList()
        : <String>[];

    while (options.length < 4) {
      options.add('');
    }

    return options.take(4).toList();
  }

  static int _safeAnswer(dynamic value) {
    if (value is int && value >= 0 && value <= 3) return value;

    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null && parsed >= 0 && parsed <= 3) return parsed;

    return 0;
  }

  List<String> _ensureOptions(int index) {
    final options = _safeOptions(tempQuiz[index]['options']);
    tempQuiz[index]['options'] = options;
    return options;
  }

  int _answerIndex(int index) {
    final answer = _safeAnswer(tempQuiz[index]['answer']);
    tempQuiz[index]['answer'] = answer;
    return answer;
  }

  void _addQuestion() {
    setState(() {
      tempQuiz.add({
        'question': '',
        'options': ['', '', '', ''],
        'answer': 0,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      tempQuiz.removeAt(index);
    });
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();

    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  bool _containsDigitalLiteracyTopic(String value) {
    final text = value.toLowerCase();

    return _digitalLiteracyKeywords.any((keyword) {
      return text.contains(keyword.toLowerCase());
    });
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  List<Map<String, dynamic>>? _validateAndBuildQuiz() {
    final List<Map<String, dynamic>> validatedQuiz = [];

    for (int i = 0; i < tempQuiz.length; i++) {
      final question = (tempQuiz[i]['question'] ?? '').toString().trim();
      final options = _safeOptions(tempQuiz[i]['options'])
          .map((option) => option.trim())
          .toList();
      final answer = _safeAnswer(tempQuiz[i]['answer']);

      if (question.isEmpty) {
        _showSnackBar('Pertanyaan #${i + 1} wajib diisi!');
        return null;
      }

      if (options.any((option) => option.isEmpty)) {
        _showSnackBar('Semua opsi jawaban pada soal #${i + 1} wajib diisi!');
        return null;
      }

      validatedQuiz.add({
        'question': question,
        'options': options,
        'answer': answer,
      });
    }

    return validatedQuiz;
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text('Berhasil Dibuat!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bagikan kode ini kepada siswa:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 30,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text(
                  'SELESAI',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAll() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('Judul wajib diisi!');
      return;
    }

    if (!widget.isQuizOnly && content.isEmpty) {
      _showSnackBar('Isi materi wajib diisi!');
      return;
    }

    if (tempQuiz.isEmpty) {
      _showSnackBar('Minimal buat 1 pertanyaan kuis!');
      return;
    }

    final validatedQuiz = _validateAndBuildQuiz();
    if (validatedQuiz == null) return;

    final textToCheck = [
      title,
      if (!widget.isQuizOnly) content,
      ...validatedQuiz.map((quiz) => quiz['question'].toString()),
      ...validatedQuiz.expand(
        (quiz) => List<String>.from(quiz['options'] as List),
      ),
    ].join(' ');

    if (!_containsDigitalLiteracyTopic(textToCheck)) {
      _showSnackBar(
        'Materi ditolak. Aplikasi ini hanya menerima materi Literasi Digital.',
        color: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String sourceLink = _sourceLinkController.text.trim();

      final Map<String, dynamic> dataToSave = {
        'title': title,
        'category': _selectedCategory,
        'literacyScope': 'digital_literacy',
        'content': widget.isQuizOnly ? '' : content,
        'sourceLink': sourceLink,
        'quiz': validatedQuiz,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('materi')
            .doc(widget.docId)
            .update(dataToSave);

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        final newCode = _generateJoinCode();

        dataToSave['joinCode'] = newCode;
        dataToSave['createdAt'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance.collection('materi').add(dataToSave);

        if (!mounted) return;
        _showSuccessDialog(newCode);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menyimpan: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.docId != null
        ? 'Edit Materi'
        : widget.isQuizOnly
            ? 'Buat Kuis Baru'
            : 'Buat Materi Baru';

    final buttonText = widget.docId != null ? 'UPDATE MATERI' : 'SIMPAN MATERI';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDigitalLockInfo(),
            const SizedBox(height: 20),
            _buildSectionHeader(Icons.title, 'Judul'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _titleController,
              label: 'Judul',
              hint: 'Contoh: Keamanan Digital, Hoaks, Privasi Data...',
              icon: Icons.title,
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(Icons.category_rounded, 'Kategori Literasi Digital'),
            const SizedBox(height: 10),
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            if (!widget.isQuizOnly) ...[
              _buildSectionHeader(Icons.book_rounded, 'Isi Materi'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _contentController,
                label: 'Penjelasan Materi',
                hint: 'Tuliskan materi khusus literasi digital...',
                icon: Icons.notes,
                maxLines: 5,
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(Icons.quiz_rounded, 'Pertanyaan Kuis'),
                TextButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Tambah'),
                  style: TextButton.styleFrom(foregroundColor: _primaryColor),
                ),
              ],
            ),
            if (tempQuiz.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(
                        Icons.post_add,
                        size: 50,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada kuis.\nKlik tambah untuk membuat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ...tempQuiz.asMap().entries.map((entry) {
              return _buildQuestionCard(entry.key);
            }),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalLockInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _primaryColor.withOpacity(0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_rounded, color: _primaryColor),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Form ini dikunci khusus untuk materi Literasi Digital. '
              'Materi di luar topik digital tidak dapat disimpan.',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Pilih Kategori',
          prefixIcon: _isLoadingExistingCategory
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.verified_user_rounded, color: _primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          floatingLabelStyle: const TextStyle(color: _primaryColor),
        ),
        items: _digitalLiteracyCategories.map((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: _isLoadingExistingCategory
            ? null
            : (value) {
                if (value == null) return;
                setState(() => _selectedCategory = value);
              },
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textInputAction:
            maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          floatingLabelStyle: const TextStyle(color: _primaryColor),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final options = _ensureOptions(index);
    final answer = _answerIndex(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Soal #${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Hapus Soal',
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: (tempQuiz[index]['question'] ?? '').toString(),
              onChanged: (value) => tempQuiz[index]['question'] = value,
              decoration: const InputDecoration(
                hintText: 'Tulis pertanyaan literasi digital di sini...',
                border: UnderlineInputBorder(),
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilihan Jawaban. Klik bulat untuk menentukan kunci jawaban:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ...List.generate(4, (optionIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: optionIndex,
                      groupValue: answer,
                      onChanged: (value) {
                        setState(() {
                          tempQuiz[index]['answer'] = value ?? 0;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          initialValue: options[optionIndex],
                          onChanged: (value) {
                            final currentOptions = _ensureOptions(index);
                            currentOptions[optionIndex] = value;
                            tempQuiz[index]['options'] = currentOptions;
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Opsi ${String.fromCharCode(65 + optionIndex)}',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}