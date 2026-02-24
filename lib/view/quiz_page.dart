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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndInit());
  }

  void _checkAndInit() async {
    final String levelDigit = widget.level.replaceAll(RegExp(r'[^0-9]'), '');
    final int levelInt = levelDigit.isEmpty ? 0 : int.parse(levelDigit);
    final savedSession = _viewModel.getSavedSession(levelInt, widget.day);

    if (savedSession != null) {
      if (!mounted) return;
      final bool? resume = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('이어 풀기', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('${widget.day != null ? "DAY ${widget.day}" : widget.level} 퀴즈 기록이 있습니다.\n이어서 푸시겠습니까?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('새로 시작')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('이어 풀기', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      );

      if (resume == true) {
        _viewModel.resumeSession(savedSession);
      } else {
        await _viewModel.loadWords(levelInt, questionCount: widget.questionCount, day: widget.day, initialWords: widget.initialWords);
      }
    } else {
      await _viewModel.loadWords(levelInt, questionCount: widget.questionCount, day: widget.day, initialWords: widget.initialWords);
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
            widget.day == 0 ? '오늘의 단어 퀴즈' : (widget.day != null ? '${widget.level} DAY ${widget.day} 퀴즈' : '${widget.level} 퀴즈'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        body: Consumer<StudyViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.total == 0) return const Center(child: CircularProgressIndicator(color: Color(0xFF5B86E5)));
            if (viewModel.isFinished) {
              if (widget.day == 0) {
                viewModel.markTodaysWordsAsCompleted();
              }
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
            const Text('퀴즈 완료!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('총 ${viewModel.total}문제 중 ${viewModel.score}문제를 맞혔습니다.', style: TextStyle(fontSize: 17, color: Colors.grey[600]), textAlign: TextAlign.center),
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

  Widget _buildQuizView(BuildContext context, StudyViewModel viewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${viewModel.currentIndex + 1} / ${viewModel.total}', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('정답: ${viewModel.score}', style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: viewModel.total > 0 ? (viewModel.currentIndex + 1) / viewModel.total : 0,
                  minHeight: 5,
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
                // 최적화된 높이의 문제 카드
                Container(
                  height: 160, // 200 -> 160으로 축소
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        viewModel.isAnswered ? viewModel.currentWord!.kana : ' ',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500], letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        viewModel.currentWord!.kanji,
                        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: viewModel.isAnswered ? 1.0 : 0.0,
                        child: Text(
                          '[ ${viewModel.currentWord!.koreanPronunciation} ]',
                          style: const TextStyle(fontSize: 16, color: Color(0xFF5B86E5), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20), // 24 -> 20으로 축소
                // 최적화된 높이의 보기 리스트
                ...viewModel.currentOptionWords.map((word) => _buildOptionButton(viewModel, word)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (viewModel.isAnswered)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 25), // 하단 여백 조정
              child: SizedBox(
                width: double.infinity,
                height: 52, // 55 -> 52로 축소
                child: ElevatedButton(
                  onPressed: viewModel.nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B86E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Text('다음 문제', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionButton(StudyViewModel viewModel, Word optionWord) {
    bool isCorrect = optionWord.meaning == viewModel.currentWord!.meaning;
    bool isSelected = optionWord.meaning == viewModel.selectedAnswer;
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
      padding: const EdgeInsets.only(bottom: 10), // 12 -> 10으로 축소
      child: SizedBox(
        height: 72, // 85 -> 72로 축소
        child: OutlinedButton(
          onPressed: isAnswered ? null : () => viewModel.submitAnswer(optionWord.meaning),
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            side: BorderSide(color: borderColor, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                optionWord.meaning,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, // 17 -> 16
                  fontWeight: (isAnswered && isCorrect) ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Opacity(
                opacity: isAnswered ? 1.0 : 0.0,
                child: Text(
                  '${optionWord.kanji} (${optionWord.kana}) - ${optionWord.koreanPronunciation}',
                  style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
