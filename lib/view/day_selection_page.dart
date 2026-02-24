import 'package:flutter/material.dart';
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
    // 검색 쿼리에 따른 필터링 (DAY 번호 기준)
    final filteredDays = _searchQuery.isEmpty
        ? List.generate(_allDayChunks.length, (i) => i)
        : List.generate(_allDayChunks.length, (i) => i).where((index) {
            final dayNum = (index + 1).toString();
            return dayNum.contains(_searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
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
      body: filteredDays.isEmpty
          ? const Center(child: Text('검색 결과가 없습니다.'))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 60), // 하단 패딩 60으로 증설
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: filteredDays.length,
              itemBuilder: (context, index) {
                final dayIndex = filteredDays[index];
                return _buildDayGridItem(context, dayIndex + 1, _allDayChunks[dayIndex]);
              },
            ),
    );
  }

  Widget _buildDayGridItem(BuildContext context, int day, List<Word> words) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordListPage(
              level: widget.level,
              day: day,
              words: words,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                color: const Color(0xFF5B86E5).withOpacity(0.1),
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
    );
  }
}
