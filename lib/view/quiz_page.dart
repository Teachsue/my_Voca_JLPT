import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/word.dart';
import '../view_model/study_view_model.dart';
import '../service/database_service.dart';

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
    
    // 오답노트(day == -1)인 경우 이어 풀기 기능을 건너뛰고 즉시 시작
    if (widget.day == -1) {
      await _viewModel.loadWords(
        levelInt,
        questionCount: widget.questionCount,
        day: widget.day,
        initialWords: widget.initialWords,
      );
      if (mounted) setState(() {});
      return;
    }

    final savedSession = _viewModel.getSavedSession(levelInt, widget.day);

    if (savedSession != null) {
      if (!mounted) return;
      final bool? resume = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '이어 풀기',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${widget.day != null ? "DAY ${widget.day}" : widget.level} 퀴즈 기록이 있습니다.\n이어서 푸시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('새로 시작'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '이어 풀기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (resume == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      if (resume == true) {
        _viewModel.resumeSession(savedSession);
      } else {
        await _viewModel.loadWords(
          levelInt,
          questionCount: widget.questionCount,
          day: widget.day,
          initialWords: widget.initialWords,
        );
      }
    } else {
      await _viewModel.loadWords(
        levelInt,
        questionCount: widget.questionCount,
        day: widget.day,
        initialWords: widget.initialWords,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bool isTodaysCompleted = Hive.box(
      DatabaseService.sessionBoxName,
    ).get('todays_words_completed_$todayStr', defaultValue: false);

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.day == 0
                ? (isTodaysCompleted ? '오늘의 단어 복습 퀴즈' : '오늘의 단어 퀴즈')
                : (widget.day != null
                      ? '${widget.level} DAY ${widget.day} 퀴즈'
                      : '${widget.level} 퀴즈'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        body: Consumer<StudyViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.total == 0)
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF5B86E5)),
              );
            if (viewModel.isFinished) {
              final bool isPerfect = viewModel.score == viewModel.total;
              if (widget.day == 0 && isPerfect)
                viewModel.markTodaysWordsAsCompleted();
              return _buildResultView(viewModel);
            }
            return _buildQuizView(context, viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildResultView(StudyViewModel viewModel) {
    final bool isPerfect = viewModel.score == viewModel.total;
    final int wrongCount = viewModel.total - viewModel.score;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Icon(
                  isPerfect
                      ? Icons.workspace_premium_rounded
                      : Icons.fitness_center_rounded,
                  size: 80,
                  color: isPerfect ? Colors.orange : Colors.blueGrey,
                ),
                const SizedBox(height: 20),
                Text(
                  isPerfect ? '완벽합니다! 💯' : '아쉬워요! 조금만 더 힘내세요 💪',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    children: [
                      TextSpan(
                        text: '${viewModel.score}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      TextSpan(text: ' / ${viewModel.total}'),
                    ],
                  ),
                ),
                if (!isPerfect) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$wrongCount개를 틀렸어요.\n오답을 확인해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 35),
                if (!isPerfect) ...[
                  const Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: Colors.blueGrey,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '틀린 단어 확인',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(viewModel.sessionWords.length, (index) {
                    final word = viewModel.sessionWords[index];
                    final userAnswer = viewModel.userAnswers[index];

                    // 정답 체크 (유형에 상관없이 뜻으로 일단 표시)
                    final isCorrect =
                        userAnswer == word.meaning ||
                        userAnswer == word.kanji ||
                        userAnswer == word.kana;

                    if (isCorrect) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cancel_rounded,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${word.kanji} (${word.kana})',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '[${word.koreanPronunciation}]',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.indigo.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$userAnswer -> ${word.meaning}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isPerfect
                        ? () => Navigator.pop(context)
                        : () => viewModel.restart(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPerfect
                          ? const Color(0xFF5B86E5)
                          : Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      isPerfect ? '학습 완료' : '다시 도전하기',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isPerfect) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    child: Text(
                      '나중에 하기',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizView(BuildContext context, StudyViewModel viewModel) {
    final bool isLast = viewModel.currentIndex == viewModel.total - 1;
    final word = viewModel.currentWord!;
    final type = viewModel.currentQuizType!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${viewModel.currentIndex + 1} / ${viewModel.total}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '정답: ${viewModel.score}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: viewModel.total > 0
                      ? (viewModel.currentIndex + 1) / viewModel.total
                      : 0,
                  minHeight: 5,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF5B86E5),
                  ),
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
                // 문제 카드 UI (유형별 분기)
                Container(
                  height: 160,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (type == QuizType.kanjiToMeaning) ...[
                        Text(
                          viewModel.isAnswered ? word.kana : ' ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          word.kanji,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '[ ${word.koreanPronunciation} ]',
                          style: TextStyle(
                            fontSize: 16,
                            color: viewModel.isAnswered
                                ? const Color(0xFF5B86E5)
                                : Colors.blueGrey.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        // 뜻을 보여주고 한자나 를 맞히는 유형
                        const Text(
                          '다음 뜻에 맞는 단어는?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          word.meaning,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (viewModel.isAnswered) ...[
                          Text(
                            '${word.kanji} (${word.kana}) [${word.koreanPronunciation}]',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF5B86E5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          // 문제를 푸는 중에도 힌트가 너무 많지 않게 발음은 살짝 보여줄 수 있음 (선택 사항)
                          // 사용자의 요청에 따라 발음 표기 추가
                          Text(
                            '[ ${word.koreanPronunciation} ]',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...viewModel.currentOptionWords.map(
                  (optionWord) => _buildOptionButton(viewModel, optionWord),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (viewModel.isAnswered)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 25),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: viewModel.nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B86E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    isLast ? '결과 보기' : '다음 문제',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionButton(StudyViewModel viewModel, Word optionWord) {
    final type = viewModel.currentQuizType!;

    // 유형별로 버튼에 표시할 텍스트 결정
    String buttonDisplayLabel = "";
    bool isCorrect = false;

    switch (type) {
      case QuizType.kanjiToMeaning:
        buttonDisplayLabel = optionWord.meaning;
        isCorrect = optionWord.meaning == viewModel.currentWord!.meaning;
        break;
      case QuizType.meaningToKanji:
        buttonDisplayLabel = optionWord.kanji;
        isCorrect = optionWord.kanji == viewModel.currentWord!.kanji;
        break;
      case QuizType.meaningToKana:
        buttonDisplayLabel = optionWord.kana;
        isCorrect = optionWord.kana == viewModel.currentWord!.kana;
        break;
    }

    bool isSelected = buttonDisplayLabel == viewModel.selectedAnswer;
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
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 72,
        child: OutlinedButton(
          onPressed: isAnswered
              ? null
              : () => viewModel.submitAnswer(buttonDisplayLabel),
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            side: BorderSide(color: borderColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                buttonDisplayLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: (isAnswered && isCorrect)
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Opacity(
                opacity: isAnswered ? 1.0 : 0.0, // 답변 후에만 보이도록 수정
                child: Text(
                  type == QuizType.kanjiToMeaning
                      ? '${optionWord.kanji} (${optionWord.kana}) - ${optionWord.koreanPronunciation}'
                      : (type == QuizType.meaningToKanji
                            ? '${optionWord.kana} [${optionWord.koreanPronunciation}]'
                            : '${optionWord.kanji} [${optionWord.koreanPronunciation}]'),
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(0.7),
                  ),
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
