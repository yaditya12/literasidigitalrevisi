import 'package:flutter/material.dart';
import '../data/materi.dart';
import 'result_page.dart';

class QuizPage extends StatefulWidget {
  final MateriModel materi; // Data Materi wajib diterima

  const QuizPage({super.key, required this.materi});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;

  @override
  Widget build(BuildContext context) {
    // Ambil daftar soal dari materi
    List<Map<String, dynamic>> questions = widget.materi.quiz;

    // Jika soal kosong (error handling)
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Tidak ada soal dalam kuis ini.")),
      );
    }

    final currentQuestion = questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Soal ${_currentIndex + 1} dari ${questions.length}"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      // Tombol LANJUT/SELESAI di bawah, selalu terlihat
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: _selectedAnswer == null ? null : _nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A11CB),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text(
              _currentIndex == questions.length - 1 ? "SELESAI" : "LANJUT",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / questions.length,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF6A11CB),
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 30),

            // Pertanyaan
            Text(
              currentQuestion['question'] ?? "Pertanyaan Error",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Opsi Jawaban
            ...List.generate(
              (currentQuestion['options'] as List).length,
              (index) {
                String optionText = currentQuestion['options'][index];
                bool isSelected = _selectedAnswer == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAnswer = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6A11CB).withOpacity(0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6A11CB) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF6A11CB) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : Center(child: Text("${String.fromCharCode(65 + index)}", style: const TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF6A11CB) : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _nextQuestion() {
    // 1. Cek Jawaban
    int correctAnswerIndex = widget.materi.quiz[_currentIndex]['answer'];
    if (_selectedAnswer == correctAnswerIndex) {
      _score++;
    }

    // 2. Pindah Soal atau Selesai
    if (_currentIndex < widget.materi.quiz.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null; // Reset pilihan
      });
    } else {
      // --- PERBAIKAN UTAMA DI SINI ---
      // Kita harus mengirim data 'widget.materi' ke ResultPage
      // Agar ResultPage tahu ID kuis mana yang harus dikunci.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            score: _score,
            total: widget.materi.quiz.length,
            materi: widget.materi, // <--- JANGAN LUPA INI!
          ),
        ),
      );
    }
  }
}