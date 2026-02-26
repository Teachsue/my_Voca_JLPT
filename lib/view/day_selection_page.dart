import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/word.dart';
import '../service/database_service.dart';
import 'word_list_page.dart';

class DaySelectionPage extends StatefulWidget {
  final String level;

  const DaySelectionPage({super.key, required this.level});

  @override
  State<DaySelectionPage> createState() => _DaySelectionPageState();
}

class _DaySelectionPageState extends State<DaySelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";
  List<List<Word>> _allDayChunks = [];

  @override
  void initState() {
    super.initState();
    _calculateDayChunks();
  }

  void _calculateDayChunks() {
    final int levelInt = int.parse(widget.level.replaceAll(RegExp(r'[^0-9]'), ''));
    final List<Word> allWords = DatabaseService.getWordsByLevel(levelInt);

    if (allWords.isEmpty) return;

    // 1. 전체 단어를 먼저 랜덤하게 섞음 (한국어 발음 기준 학습을 위해)
    allWords.shuffle(); 

    // 2. 섞인 상태에서 20개씩 DAY 분할
    final List<List<Word>> chunks = [];
    for (int i = 0; i < allWords.length; i += 20) {
      int end = (i + 20 < allWords.length) ? i + 20 : allWords.length;
      List<Word> chunk = allWords.sublist(i, end);

      if (chunks.isNotEmpty && chunk.length < 10) {
        chunks.last.addAll(chunk);
      } else {
        chunks.add(chunk);
      }
    }
    _allDayChunks = chunks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'DAY 번호 검색...',
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text('${widget.level} DAY 선택', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, size: 22),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            tooltip: '홈으로 이동',
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = "";
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box(DatabaseService.sessionBoxName).listenable(keys: ['last_day_${widget.level}']),
        builder: (context, sessionBox, _) {
          final int lastDay = sessionBox.get('last_day_${widget.level}', defaultValue: 0);

          return ValueListenableBuilder(
            valueListenable: Hive.box<Word>(DatabaseService.boxName).listenable(),
            builder: (context, Box<Word> box, _) {
              _calculateDayChunks(); // 데이터가 변경되면 다시 청크 계산

              if (_allDayChunks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text('${widget.level} 데이터를 불러오는 중입니다...', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              // 검색 쿼리에 따른 필터링 (DAY 번호 기준)
              final filteredDays = _searchQuery.isEmpty
                  ? List.generate(_allDayChunks.length, (i) => i)
                  : List.generate(_allDayChunks.length, (i) => i).where((index) {
                      final dayNum = (index + 1).toString();
                      return dayNum.contains(_searchQuery);
                    }).toList();

              if (filteredDays.isEmpty) {
                return const Center(child: Text('검색 결과가 없습니다.'));
              }

              return Column(
                children: [
                  // 최근 학습 바로가기 (검색 중이 아닐 때만 표시)
                  if (!_isSearching && lastDay > 0 && _searchQuery.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _buildResumeCard(context, lastDay),
                    ),
                  
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredDays.length,
                      itemBuilder: (context, index) {
                        final dayIndex = filteredDays[index];
                        final isRecent = (dayIndex + 1) == lastDay;
                        return _buildDayGridItem(context, dayIndex + 1, _allDayChunks[dayIndex], isRecent);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildResumeCard(BuildContext context, int lastDay) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordListPage(
              level: widget.level,
              initialDayIndex: lastDay - 1,
              allDayChunks: _allDayChunks,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B86E5).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('이어서 학습하기', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('DAY $lastDay', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDayGridItem(BuildContext context, int day, List<Word> words, bool isRecent) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordListPage(
              level: widget.level,
              initialDayIndex: day - 1,
              allDayChunks: _allDayChunks,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isRecent ? Border.all(color: const Color(0xFF5B86E5), width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (isRecent ? const Color(0xFF5B86E5) : const Color(0xFF5B86E5)).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: const Color(0xFF5B86E5),
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'DAY $day',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${words.length} 단어',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isRecent)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B86E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'RECENT',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
