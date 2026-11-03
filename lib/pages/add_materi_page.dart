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
  List<Map<String, dynamic>> tempQuiz = <Map<String, dynamic>>[];
  final List<TextEditingController> _questionControllers = [];
  final List<List<TextEditingController>> _optionControllers = [];
  bool _isLoading = false;
  bool _isLoadingExistingDoc = false;
  bool _isDraft = false;
  late bool _isQuizOnly;

  @override
  void initState() {
    super.initState();
    _isQuizOnly = widget.materi?.isQuizOnly ?? widget.isQuizOnly;

    if (widget.materi != null) {
      _titleController = TextEditingController(text: widget.materi!.title);
      _contentController = TextEditingController(text: widget.materi!.content);
      _sourceLinkController =
          TextEditingController(text: widget.materi!.sourceLink ?? '');
      _isDraft = widget.materi!.isDraft;
      tempQuiz = widget.materi!.quiz.map<Map<String, dynamic>>((questionData) {
        final options = _safeOptions(questionData['options']);
        final answer = _safeAnswer(questionData['answer']);

        return <String, dynamic>{
          'question': (questionData['question'] ?? '').toString(),
          'options': options,
          'answer': answer,
        };
      }).toList();

      for (final q in tempQuiz) {
        _questionControllers.add(
          TextEditingController(text: (q['question'] ?? '').toString()),
        );
        final opts = _safeOptions(q['options']);
        _optionControllers.add(
          opts.map((o) => TextEditingController(text: o)).toList(),
        );
      }

      if (widget.docId != null) {
        _loadExistingDoc();
      }
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _sourceLinkController = TextEditingController();
      tempQuiz = <Map<String, dynamic>>[];

      if (widget.docId != null) {
        _loadExistingDoc();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _sourceLinkController.dispose();
    for (final c in _questionControllers) {
      c.dispose();
    }
    for (final row in _optionControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadExistingDoc() async {
    setState(() => _isLoadingExistingDoc = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('materi')
          .doc(widget.docId)
          .get();

      final data = doc.data();
      if (data == null) {
        if (mounted) setState(() => _isLoadingExistingDoc = false);
        return;
      }

      final category = data['category']?.toString();
      final isDraftDoc = data['isDraft'] == true || data['status'] == 'draft';
      final bool? isQuizOnlyDoc =
          data.containsKey('isQuizOnly') ? (data['isQuizOnly'] == true) : null;

      if (!mounted) return;

      setState(() {
        _isDraft = isDraftDoc;
        if (isQuizOnlyDoc != null) {
          _isQuizOnly = isQuizOnlyDoc;
        }
        if (category != null && _digitalLiteracyCategories.contains(category)) {
          _selectedCategory = category;
        }

        // If widget.materi was null, populate from Firestore data
        if (widget.materi == null) {
          _titleController.text = data['title']?.toString() ?? '';
          _contentController.text = data['content']?.toString() ?? '';
          _sourceLinkController.text = data['sourceLink']?.toString() ?? '';

          final rawQuiz = data['quiz'];
          if (rawQuiz is List) {
            tempQuiz.clear();
            for (final c in _questionControllers) {
              c.dispose();
            }
            _questionControllers.clear();
            for (final row in _optionControllers) {
              for (final c in row) {
                c.dispose();
              }
            }
            _optionControllers.clear();

            for (final item in rawQuiz) {
              if (item is Map) {
                final qMap = Map<String, dynamic>.from(item);
                final options = _safeOptions(qMap['options']);
                final answer = _safeAnswer(qMap['answer']);
                final qText = (qMap['question'] ?? '').toString();
                tempQuiz.add(<String, dynamic>{
                  'question': qText,
                  'options': options,
                  'answer': answer,
                });
                _questionControllers.add(TextEditingController(text: qText));
                _optionControllers.add(
                  options.map((o) => TextEditingController(text: o)).toList(),
                );
              }
            }
          }
        }
        _isLoadingExistingDoc = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingExistingDoc = false);
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

  int _answerIndex(int index) {
    final answer = _safeAnswer(tempQuiz[index]['answer']);
    tempQuiz[index]['answer'] = answer;
    return answer;
  }

  void _ensureControllersForIndex(int index) {
    while (_questionControllers.length <= index) {
      final qText = index < tempQuiz.length
          ? (tempQuiz[index]['question'] ?? '').toString()
          : '';
      _questionControllers.add(TextEditingController(text: qText));
    }
    while (_optionControllers.length <= index) {
      final List<String> opts = index < tempQuiz.length
          ? _safeOptions(tempQuiz[index]['options'])
          : ['', '', '', ''];
      _optionControllers.add(
        opts.map((o) => TextEditingController(text: o)).toList(),
      );
    }
  }

  void _addQuestion() {
    setState(() {
      tempQuiz.add(<String, dynamic>{
        'question': '',
        'options': <String>['', '', '', ''],
        'answer': 0,
      });
      _questionControllers.add(TextEditingController());
      _optionControllers.add(
        List.generate(4, (_) => TextEditingController()),
      );
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      tempQuiz.removeAt(index);
      if (index < _questionControllers.length) {
        _questionControllers[index].dispose();
        _questionControllers.removeAt(index);
      }
      if (index < _optionControllers.length) {
        for (final c in _optionControllers[index]) {
          c.dispose();
        }
        _optionControllers.removeAt(index);
      }
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

  void _syncControllersToTempQuiz() {
    for (int i = 0; i < tempQuiz.length; i++) {
      if (i < _questionControllers.length) {
        tempQuiz[i]['question'] = _questionControllers[i].text;
      }
      if (i < _optionControllers.length) {
        tempQuiz[i]['options'] =
            _optionControllers[i].map((c) => c.text).toList();
      }
    }
  }

  List<Map<String, dynamic>>? _validateAndBuildQuiz() {
    _syncControllersToTempQuiz();
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

  Future<void> _saveDraft() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _showSnackBar(
        'Beri judul terlebih dahulu untuk menyimpan sebagai Draft!',
        color: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String sourceLink = _sourceLinkController.text.trim();

      // Sinkronkan nilai controller ke tempQuiz sebelum simpan draft
      _syncControllersToTempQuiz();
      // Untuk draft, simpan seluruh soal tempQuiz agar pekerjaan guru tersimpan utuh
      final List<Map<String, dynamic>> draftQuiz = [];
      for (var q in tempQuiz) {
        final qText = (q['question'] ?? '').toString();
        final opts = _safeOptions(q['options']);
        final ans = _safeAnswer(q['answer']);
        draftQuiz.add({
          'question': qText,
          'options': opts,
          'answer': ans,
        });
      }

      final Map<String, dynamic> dataToSave = {
        'title': title,
        'category': _selectedCategory,
        'literacyScope': 'digital_literacy',
        'isQuizOnly': _isQuizOnly,
        'content': _isQuizOnly ? '' : content,
        'sourceLink': sourceLink,
        'quiz': draftQuiz,
        'isDraft': true,
        'status': 'draft',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('materi')
            .doc(widget.docId)
            .update(dataToSave);

        if (!mounted) return;
        _showSnackBar('Draft berhasil diperbarui!', color: Colors.green);
        Navigator.pop(context, true);
      } else {
        final newCode = _generateJoinCode();
        dataToSave['joinCode'] = newCode;
        dataToSave['createdAt'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance.collection('materi').add(dataToSave);

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
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('Judul wajib diisi!');
      return;
    }

    if (!_isQuizOnly && content.isEmpty) {
      _showSnackBar('Isi materi wajib diisi!');
      return;
    }

    if (tempQuiz.length < 5) {
      _showSnackBar(
        'Kuis wajib memiliki minimal 5 soal untuk dipublikasikan! (Saat ini: ${tempQuiz.length} soal)',
        color: Colors.orange,
      );
      return;
    }

    final validatedQuiz = _validateAndBuildQuiz();
    if (validatedQuiz == null) return;

    final textToCheck = [
      title,
      if (!_isQuizOnly) content,
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
        'isQuizOnly': _isQuizOnly,
        'content': _isQuizOnly ? '' : content,
        'sourceLink': sourceLink,
        'quiz': validatedQuiz,
        'isDraft': false,
        'status': 'published',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('materi')
            .doc(widget.docId)
            .update(dataToSave);

        if (!mounted) return;
        _showSnackBar(
            'Materi/kuis berhasil dipublikasikan ke siswa!',
            color: Colors.green);
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
      _showSnackBar('Gagal mempublikasikan: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.docId != null
        ? (_isDraft
            ? (_isQuizOnly ? 'Edit Draft Kuis' : 'Edit Draft Materi')
            : (_isQuizOnly ? 'Edit Kuis' : 'Edit Materi'))
        : (_isQuizOnly ? 'Buat Kuis Baru' : 'Buat Materi Baru');

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
            if (_isDraft) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded,
                        color: Colors.amber.shade800, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status: DRAFT — ${_isQuizOnly ? 'Kuis' : 'Materi & Kuis'} ini belum dapat dilihat oleh siswa. Anda dapat mengedit isi materi dan soal kuis kapan saja.',
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

            // Content Type Selector: Materi & Kuis vs Kuis Saja
            _buildContentTypeSelector(),
            const SizedBox(height: 14),

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
            _buildSectionHeader(
                Icons.category_rounded, 'Kategori Literasi Digital'),
            const SizedBox(height: 10),
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            if (!_isQuizOnly) ...[
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.quiz_rounded, color: _primaryColor, size: 20),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Pertanyaan Kuis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text(
                    'Tambah',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tempQuiz.length >= 5
                    ? Colors.green.shade50
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tempQuiz.length >= 5
                      ? Colors.green.shade200
                      : Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tempQuiz.length >= 5
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 18,
                    color: tempQuiz.length >= 5
                        ? Colors.green.shade700
                        : Colors.amber.shade900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tempQuiz.length >= 5
                          ? 'Minimal 5 soal terpenuhi (${tempQuiz.length} soal dibuat).'
                          : 'Batas minimal kuis adalah 5 soal untuk dapat dipublikasikan ke siswa.',
                      style: TextStyle(
                        fontSize: 11,
                        color: tempQuiz.length >= 5
                            ? Colors.green.shade900
                            : Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tempQuiz.length >= 5
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tempQuiz.length >= 5
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                      ),
                    ),
                    child: Text(
                      '${tempQuiz.length}/5 Soal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tempQuiz.length >= 5
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
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
                        'Belum ada kuis.\nKlik tambah untuk membuat (minimal 5 soal).',
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
            if (tempQuiz.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: OutlinedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_circle_outline, color: _primaryColor, size: 18),
                  label: const Text(
                    'Tambah Soal Lainnya',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primaryColor, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),
            const SizedBox(height: 35),

            // Tombol Simpan Draft & Publikasikan
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
                        icon: const Icon(Icons.bookmark_add_outlined,
                            color: _primaryColor, size: 20),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'SIMPAN DRAFT',
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: _primaryColor, width: 1.5),
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
                        icon: const Icon(Icons.rocket_launch_rounded,
                            color: Colors.white, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.docId != null && !_isDraft
                                ? 'UPDATE'
                                : 'PUBLIKASIKAN',
                            maxLines: 1,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (_isQuizOnly) {
                  setState(() => _isQuizOnly = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isQuizOnly ? _primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: !_isQuizOnly ? Colors.white : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Materi & Kuis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            !_isQuizOnly ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (!_isQuizOnly) {
                  setState(() => _isQuizOnly = true);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      _isQuizOnly ? Colors.orange.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_alt,
                      size: 18,
                      color: _isQuizOnly ? Colors.white : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kuis Saja',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            _isQuizOnly ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          prefixIcon: _isLoadingExistingDoc
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
        onChanged: _isLoadingExistingDoc
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
      mainAxisSize: MainAxisSize.min,
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
    _ensureControllersForIndex(index);
    final answer = _answerIndex(index);
    final qCtrl = _questionControllers[index];
    final optsCtrl = _optionControllers[index];

    return Card(
      key: ObjectKey(tempQuiz[index]),
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
            TextField(
              controller: qCtrl,
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
                        child: TextField(
                          controller: optsCtrl[optionIndex],
                          onChanged: (value) {
                            tempQuiz[index]['options'] =
                                optsCtrl.map((c) => c.text).toList();
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
