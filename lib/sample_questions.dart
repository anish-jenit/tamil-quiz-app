class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;

  Question({required this.id, required this.text, required this.options, required this.correctIndex});
}

final List<Question> sampleQuestions = [
  Question(
    id: 'sample_001',
    text: 'What is the capital of Tamil Nadu?',
    options: ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli'],
    correctIndex: 0,
  ),
  Question(
    id: 'sample_002',
    text: 'Which festival is known as the festival of lights?',
    options: ['Pongal', 'Diwali', 'Navaratri', 'Karthigai Deepam'],
    correctIndex: 1,
  ),
  Question(
    id: 'sample_003',
    text: 'What is the primary language spoken in Tamil Nadu?',
    options: ['Telugu', 'Hindi', 'Tamil', 'Malayalam'],
    correctIndex: 2,
  ),
];
