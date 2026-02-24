import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/word.dart';
import '../view_model/study_view_model.dart';

class QuizPage extends StatefulWidget {
  final String level;
  final int questionCount;
  final int? day;
  final List<Word>? initialWords;

  const QuizPage({
    super.key,
    required this.level,
    required this.questionCount,
    this.day,
    this.initialWords,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late StudyViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StudyViewModel();
    // 포스트 프레임 콜백에서 세션 체크 및 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInit();
    });
  }

  void _checkAndInit() async {
    final int levelInt = int.parse(widget.level.replaceAll(RegExp(r'[^0-9]'), ''));
    final savedSession = _viewModel.getSavedSession(levelInt, widget.day);

    if (savedSession != null) {
      // 이어풀기 팝업
      if (!mounted) return;
      final bool? resume = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('이어 풀기'),
          content: Text('${widget.day != null ? "DAY ${widget.day}" : widget.level} 퀴즈 기록이 있습니다.\n이어서 푸시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('새로 시작'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('이어 풀기'),
            ),
          ],
        ),
      );

      if (resume == true) {
        _viewModel.resumeSession(savedSession);
      } else {
        await _viewModel.loadWords(levelInt,
            questionCount: widget.questionCount, day: widget.day, initialWords: widget.initialWords);
      }
    } else {
      await _viewModel.loadWords(levelInt,
          questionCount: widget.questionCount, day: widget.day, initialWords: widget.initialWords);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            widget.day != null ? '${widget.level} DAY ${widget.day} 퀴즈' : '${widget.level} $widget.questionCount문제 퀴즈',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        body: Consumer<StudyViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.total == 0) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF5B86E5)));
            }

            if (viewModel.isFinished) {
              return _buildResultView(viewModel);
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
              '퀴즈 완료!',
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
                  value: viewModel.total > 0 ? (viewModel.currentIndex + 1) / viewModel.total : 0,
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
}
