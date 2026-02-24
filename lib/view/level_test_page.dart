import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/level_test_view_model.dart';

class LevelTestPage extends StatelessWidget {
  const LevelTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LevelTestViewModel()..initTest(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('실력 맞춤 테스트', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        body: Consumer<LevelTestViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isFinished) return _buildResultView(context, viewModel);
            if (viewModel.currentWord == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF5B86E5)));
            return _buildQuizView(context, viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildResultView(BuildContext context, LevelTestViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_rounded, size: 80, color: Color(0xFF5B86E5)),
            const SizedBox(height: 24),
            const Text('테스트 완료!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('총 30문제 중 ${viewModel.totalCorrect}문제를 맞혔습니다.', style: TextStyle(fontSize: 17, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('추천 학습 레벨: ${viewModel.recommendedLevel}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5B86E5))),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B86E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizView(BuildContext context, LevelTestViewModel viewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${viewModel.currentIndex + 1} / ${viewModel.totalQuestions}', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  const Text('레벨 테스트', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (viewModel.currentIndex + 1) / viewModel.totalQuestions,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B86E5)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      Text(viewModel.isAnswered ? viewModel.currentWord!.kana : ' ', style: TextStyle(fontSize: 18, color: Colors.grey[500], letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(viewModel.currentWord!.kanji, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...viewModel.currentOptions.map((option) => _buildOptionButton(viewModel, option)),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        if (viewModel.isAnswered)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: viewModel.nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B86E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Text('다음 문제', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionButton(LevelTestViewModel viewModel, String option) {
    bool isCorrect = option == viewModel.currentWord!.meaning;
    bool isSelected = option == viewModel.selectedAnswer;
    bool isAnswered = viewModel.isAnswered;

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[200]!;
    Color textColor = Colors.black87;

    if (isAnswered) {
      if (isCorrect) {
        backgroundColor = Colors.green[50]!;
        borderColor = Colors.green;
        textColor = Colors.green[700]!;
      } else if (isSelected) {
        backgroundColor = Colors.red[50]!;
        borderColor = Colors.red;
        textColor = Colors.red[700]!;
      } else {
        textColor = Colors.grey[400]!;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 60,
        child: OutlinedButton(
          onPressed: isAnswered ? null : () => viewModel.submitAnswer(option),
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            side: BorderSide(color: borderColor, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Text(option, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: textColor, fontWeight: (isAnswered && isCorrect) ? FontWeight.bold : FontWeight.w500)),
        ),
      ),
    );
  }
}
