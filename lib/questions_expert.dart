import 'sample_questions.dart';

// Minimal fallback expert questions.
final List<Question> expertQuestions = [
  Question(
    id: 'exp_fallback_001',
    text: 'திருக்குறள் (குறள் 1) — பூர்த்தி செய்ய வேண்டிய சொல்: ___',
    options: ['அகர', 'முதல்', 'எழுத்து', 'உலகு'],
    correctIndex: 0,
  ),
  Question(
    id: 'exp_fallback_002',
    text: 'இலக்கணம்: வினைச்சொல் என்றால் என்ன?',
    options: ['நாமவாசகம்', 'வினைச்சொல்', 'பொருள்', 'பண்பு'],
    correctIndex: 1,
  ),
  Question(
    id: 'exp_fallback_003',
    text: 'செய்யுள்: ஒரு எடுத்துக்காட்டு (fallback)',
    options: ['வினை', 'பெயர்', 'இசை', 'நூல்'],
    correctIndex: 2,
  ),
];
