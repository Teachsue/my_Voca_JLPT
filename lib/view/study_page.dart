import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/study_view_model.dart';

class StudyPage extends StatelessWidget {
  final String level;

  const StudyPage({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final int levelInt = int.parse(level.replaceAll(RegExp(r'[^0-9]'), ''));

    return ChangeNotifierProvider(
      create: (context) => StudyViewModel()..loadWords(levelInt),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('$level 학습', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        body: Consumer<StudyViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isFinished) {
              return _buildResultView(viewModel);
            }

            if (viewModel.currentWord == null) {
              return viewModel.total == 0
                  ? _buildEmptyView(context)
                  : const Center(child: CircularProgressIndicator(color: Color(0xFF5B86E5)));
            }

            return _buildQuizView(context, viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildResultView(StudyViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration_rounded, size: 80, color: Color(0xFF5B86E5)),
            const SizedBox(height: 24),
            const Text(
              '학습 완료!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '총 ${viewModel.total}문제 중 ${viewModel.score}문제를 맞혔습니다.',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: viewModel.restart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B86E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('다시 도전하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizView(BuildContext context, StudyViewModel viewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${viewModel.currentIndex + 1} / ${viewModel.total}',
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '정답: ${viewModel.score}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (viewModel.currentIndex + 1) / viewModel.total,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B86E5)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Word Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        viewModel.isAnswered ? viewModel.currentWord!.kana : ' ',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[500],
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.currentWord!.kanji,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      if (viewModel.isAnswered) ...[
                        const SizedBox(height: 16),
                        Text(
                          '[ ${viewModel.currentWord!.koreanPronunciation} ]',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF5B86E5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Options
                ...viewModel.currentOptions.map((option) {
                  return _buildOptionButton(viewModel, option);
                }).toList(),
              ],
            ),
          ),
        ),
        if (viewModel.isAnswered)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: viewModel.nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B86E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('다음 문제', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionButton(StudyViewModel viewModel, String option) {
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
        height: 65,
        child: OutlinedButton(
          onPressed: isAnswered ? null : () => viewModel.submitAnswer(option),
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            side: BorderSide(color: borderColor, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Text(
            option,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: (isAnswered && isCorrect) ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('해당 레벨의 단어가 없습니다.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('뒤로가기'),
          ),
        ],
      ),
    );
  }
}
