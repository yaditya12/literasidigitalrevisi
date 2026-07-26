import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimulationPage extends StatefulWidget {
  const SimulationPage({super.key});

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _cases = [];
  bool _isLoading = true;

  int _currentIndex = 0;
  int _score = 0;
  bool _showExplanation = false;
  bool _isAnswerCorrect = false;

  @override
  void initState() {
    super.initState();
    _fetchSimulationsFromFirebase();
  }

  // --- MENGAMBIL DATA DARI FIREBASE ---
  Future<void> _fetchSimulationsFromFirebase() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('simulations').orderBy('createdAt').get();
      
      List<Map<String, dynamic>> loadedCases = [];
      for (var doc in snapshot.docs) {
        loadedCases.add(doc.data() as Map<String, dynamic>);
      }

      setState(() {
        _cases = loadedCases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Tangani error jika gagal load
    }
  }

  void _checkAnswer(bool userGuessIsSafe) {
    bool actualIsSafe = _cases[_currentIndex]['isSafe'];
    setState(() {
      _isAnswerCorrect = (userGuessIsSafe == actualIsSafe);
      if (_isAnswerCorrect) _score += 25; 
      _showExplanation = true;
    });
  }

  void _nextCase() {
    setState(() {
      if (_currentIndex < _cases.length - 1) {
        _currentIndex++;
        _showExplanation = false;
      } else {
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Simulasi Selesai!", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, size: 60, color: Colors.green),
            const SizedBox(height: 15),
            Text("Skor Anda: $_score", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Terus asah insting literasi digitalmu!", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Kembali ke Beranda"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cases.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Simulasi Kasus")),
        body: const Center(child: Text("Belum ada soal simulasi. Minta Guru untuk menambahkannya!")),
      );
    }

    final currentCase = _cases[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Simulasi Kasus"), backgroundColor: const Color(0xFF6A11CB), foregroundColor: Colors.white),
      // Tombol jawaban / lanjut selalu terlihat di bawah
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: !_showExplanation
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Menurut Anda, apakah ini aman?", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, padding: const EdgeInsets.symmetric(vertical: 14)),
                          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                          label: const Text("BAHAYA / HOAKS", style: TextStyle(color: Colors.white, fontSize: 13)),
                          onPressed: () => _checkAnswer(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                          icon: const Icon(Icons.gpp_good, color: Colors.white),
                          label: const Text("AMAN", style: TextStyle(color: Colors.white)),
                          onPressed: () => _checkAnswer(true),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A11CB), padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: _nextCase,
                  child: Text(_currentIndex < _cases.length - 1 ? "LANJUT KASUS BERIKUTNYA" : "SELESAIKAN SIMULASI", style: const TextStyle(color: Colors.white)),
                ),
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Kasus ${_currentIndex + 1} dari ${_cases.length}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: (_currentIndex + 1) / _cases.length, backgroundColor: Colors.grey.shade300, color: const Color(0xFF6A11CB)),
            const SizedBox(height: 20),

            // Kartu konten kasus
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)]),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Text(currentCase['type'], style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  Text('"${currentCase['content']}"', style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic, height: 1.6), textAlign: TextAlign.center),
                ],
              ),
            ),

            // Penjelasan setelah menjawab
            if (_showExplanation) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isAnswerCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _isAnswerCorrect ? Colors.green : Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_isAnswerCorrect ? Icons.check_circle : Icons.cancel, color: _isAnswerCorrect ? Colors.green : Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isAnswerCorrect ? "Jawaban Anda Tepat!" : "Ups, Jawaban Kurang Tepat!",
                            style: TextStyle(fontWeight: FontWeight.bold, color: _isAnswerCorrect ? Colors.green : Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(currentCase['explanation'], style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}