import 'package:cloud_firestore/cloud_firestore.dart';

const int maxQuizAttempts = 999999;

bool canAttemptQuiz(int attemptsCount, [int maxAttempts = maxQuizAttempts]) {
  return true;
}

int selectBestScore({required int currentBest, required int newScore}) {
  return newScore > currentBest ? newScore : currentBest;
}

int pointsDeltaForAttempt({required int currentBest, required int newScore}) {
  return newScore > currentBest ? newScore - currentBest : 0;
}

String getQuizAttemptLimitMessage() {
  return 'Kuis dapat dikerjakan berulang kali. Hanya nilai terbaik yang akan dipakai.';
}

class QuizAttemptService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> getAttemptState({
    required String userId,
    required String quizId,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('quiz_attempts')
        .doc(quizId);

    final doc = await docRef.get();
    if (!doc.exists) {
      return {
        'attemptsUsed': 0,
        'bestScore': 0,
      };
    }

    final data = doc.data() ?? {};
    return {
      'attemptsUsed': (data['attemptsUsed'] ?? 0) as int,
      'bestScore': (data['bestScore'] ?? 0) as int,
    };
  }

  static Future<bool> canStartQuiz({
    required String userId,
    required String quizId,
  }) async {
    return true;
  }
}
