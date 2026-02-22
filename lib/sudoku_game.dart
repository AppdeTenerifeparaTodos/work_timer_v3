import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

// ========================================
// 📋 EKRAN WYBORU POZIOMU SUDOKU
// ========================================
class SudokuLevelsPage extends StatefulWidget {
  const SudokuLevelsPage({Key? key}) : super(key: key);

  @override
  State<SudokuLevelsPage> createState() => _SudokuLevelsPageState();
}

class _SudokuLevelsPageState extends State<SudokuLevelsPage> {
  int _maxUnlockedLevel = 1; // Na początku tylko poziom 1 jest odblokowany

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  // 📂 Wczytaj postęp z pamięci telefonu
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxUnlockedLevel = prefs.getInt('sudoku_max_level') ?? 1;
    });
  }

  // 💾 Zapisz postęp do pamięci telefonu
  Future<void> _saveProgress(int newLevel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sudoku_max_level', newLevel);
  }

  // 🔓 Sprawdź czy poziom jest zablokowany
  bool _isLocked(int level) {
    return level > _maxUnlockedLevel;
  }

  // 🎮 Otwórz grę na wybranym poziomie
  void _openLevel(int level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SudokuGamePage(
          level: level,
          onLevelCompleted: () {
            // Odblokuj następny poziom po ukończeniu tego
            if (level >= _maxUnlockedLevel && level < 10) {
              setState(() {
                _maxUnlockedLevel = level + 1;
              });
              _saveProgress(level + 1);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Lista wszystkich 10 poziomów
    final levels = [
      loc.translate('sudoku_level_1'),
      loc.translate('sudoku_level_2'),
      loc.translate('sudoku_level_3'),
      loc.translate('sudoku_level_4'),
      loc.translate('sudoku_level_5'),
      loc.translate('sudoku_level_6'),
      loc.translate('sudoku_level_7'),
      loc.translate('sudoku_level_8'),
      loc.translate('sudoku_level_9'),
      loc.translate('sudoku_level_10'),
    ];

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(loc.translate('sudoku_choose_level')),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Przycisk reset postępu
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset poziomów',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('sudoku_max_level', 1);
              setState(() {
                _maxUnlockedLevel = 1;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Postęp zresetowany')),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          final level = index + 1; // Poziom 1-10
          final isLocked = _isLocked(level);
          final title = levels[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                isLocked ? Icons.lock : Icons.lock_open,
                color: isLocked ? Colors.grey : Colors.teal,
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey : Colors.teal.shade900,
                ),
              ),
              subtitle: isLocked
                  ? Text(
                      loc.translate('sudoku_locked'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  : _BestTimeWidget(level: level), // Pokazuje najlepszy czas
              trailing: isLocked
                  ? null
                  : const Icon(Icons.arrow_forward_ios, color: Colors.teal),
              onTap: isLocked ? null : () => _openLevel(level),
            ),
          );
        },
      ),
    );
  }
}

// ========================================
// ⏱️ WIDGET: Pokazuje najlepszy czas dla poziomu
// ========================================
class _BestTimeWidget extends StatefulWidget {
  final int level;
  const _BestTimeWidget({required this.level});

  @override
  State<_BestTimeWidget> createState() => _BestTimeWidgetState();
}

class _BestTimeWidgetState extends State<_BestTimeWidget> {
  int _bestTime = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestTime = prefs.getInt('sudoku_best_time_level_${widget.level}') ?? 0;
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_bestTime == 0) return const SizedBox();
    return Text(
      '🏆 ${_formatTime(_bestTime)}',
      style: const TextStyle(fontSize: 12, color: Colors.teal),
    );
  }
}

// ========================================
// 🎮 GŁÓWNA GRA SUDOKU
// ========================================
class SudokuGamePage extends StatefulWidget {
  final int level;               // Poziom 1-10
  final VoidCallback? onLevelCompleted; // Wywołaj gdy ukończono poziom

  const SudokuGamePage({
    Key? key,
    required this.level,
    this.onLevelCompleted,
  }) : super(key: key);

  @override
  State<SudokuGamePage> createState() => _SudokuGamePageState();
}

class _SudokuGamePageState extends State<SudokuGamePage> {
  // 🎯 PLANSZA SUDOKU
  // _puzzle = plansza z dziurami (0 = puste pole)
  // _solution = pełne rozwiązanie
  // _userInput = co wpisał gracz
  late List<List<int>> _puzzle;
  late List<List<int>> _solution;
  late List<List<int>> _userInput;

  int _selectedRow = -1;   // Zaznaczony wiersz (-1 = nic nie zaznaczono)
  int _selectedCol = -1;   // Zaznaczona kolumna

  int _seconds = 0;        // Licznik czasu w sekundach
  Timer? _timer;           // Timer który tyka co sekundę
  bool _gameStarted = false;
  bool _gameSolved = false;

  int _errorCount = 0;     // Ile błędów popełnił gracz
  int _hintsLeft = 3;      // Ile podpowiedzi zostało (3 na start)
  int _bestTime = 0;       // Najlepszy czas dla tego poziomu

  @override
  void initState() {
    super.initState();
    _loadBestTime();
    _generatePuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 📂 Wczytaj najlepszy czas dla tego poziomu
  Future<void> _loadBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestTime = prefs.getInt('sudoku_best_time_level_${widget.level}') ?? 0;
    });
  }

  // 💾 Zapisz najlepszy czas jeśli lepszy
  Future<void> _saveBestTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_bestTime == 0 || _seconds < _bestTime) {
      await prefs.setInt('sudoku_best_time_level_${widget.level}', _seconds);
      setState(() {
        _bestTime = _seconds;
      });
    }
  }

  // ⏱️ Formatuj czas np. 125 sekund → "2:05"
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  // ▶️ Rozpocznij odliczanie czasu
  void _startTimer() {
    if (_gameStarted) return;
    _gameStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _seconds++);
    });
  }

  // ========================================
  // 🧩 GENEROWANIE SUDOKU
  // Ile cyfr usuwamy zależy od poziomu:
  // Poziom 1 = łatwy (usuwamy mało cyfr = dużo wskazówek)
  // Poziom 10 = trudny (usuwamy dużo cyfr = mało wskazówek)
  // ========================================
  void _generatePuzzle() {
    // 1. Wygeneruj pełną, poprawną siatkę 9x9
    _solution = _generateFullGrid();

    // 2. Skopiuj rozwiązanie i usuń część cyfr (to tworzy łamigłówkę)
    _puzzle = List.generate(9, (r) => List.from(_solution[r]));
    _removeCells(_puzzle, widget.level);

    // 3. Stwórz pustą siatkę na odpowiedzi gracza
    _userInput = List.generate(9, (r) => List.filled(9, 0));

    setState(() {
      _selectedRow = -1;
      _selectedCol = -1;
      _seconds = 0;
      _gameStarted = false;
      _gameSolved = false;
      _errorCount = 0;
      _hintsLeft = 3;
    });

    _timer?.cancel();
  }

  // Generuje pełną siatkę 9x9 (poprawne Sudoku)
  List<List<int>> _generateFullGrid() {
    // Zacznij od pustej siatki
    List<List<int>> grid = List.generate(9, (_) => List.filled(9, 0));
    _fillGrid(grid);
    return grid;
  }

  // Wypełnia siatkę rekurencyjnie (backtracking)
  bool _fillGrid(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) {
          // Puste pole - spróbuj wstawić cyfry 1-9 w losowej kolejności
          final nums = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(Random());
          for (final num in nums) {
            if (_isValid(grid, r, c, num)) {
              grid[r][c] = num;
              if (_fillGrid(grid)) return true;
              grid[r][c] = 0; // Cofnij jeśli nie działa
            }
          }
          return false; // Żadna cyfra nie pasuje
        }
      }
    }
    return true; // Siatka wypełniona!
  }

  // Sprawdza czy cyfra może być w danym miejscu (reguły Sudoku)
  bool _isValid(List<List<int>> grid, int row, int col, int num) {
    // Sprawdź wiersz
    for (int c = 0; c < 9; c++) {
      if (grid[row][c] == num) return false;
    }
    // Sprawdź kolumnę
    for (int r = 0; r < 9; r++) {
      if (grid[r][col] == num) return false;
    }
    // Sprawdź kwadrat 3x3
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if (grid[r][c] == num) return false;
      }
    }
    return true;
  }

  // Usuwa cyfry z siatki - ile zależy od poziomu
  void _removeCells(List<List<int>> grid, int level) {
    // Ile cyfr zostawiamy (więcej = łatwiej)
    // Poziom 1: 50 cyfr widocznych, Poziom 10: 22 cyfry widoczne
    final cluesMap = {
      1: 50, // Początkujący - dużo wskazówek
      2: 46,
      3: 42,
      4: 38,
      5: 35,
      6: 32,
      7: 29,
      8: 27,
      9: 25,
      10: 22, // Niemożliwy - mało wskazówek
    };
    final clues = cluesMap[level] ?? 35;
    final toRemove = 81 - clues; // Ile pól wyzerować

    final positions = List.generate(81, (i) => i)..shuffle(Random());
    int removed = 0;
    for (final pos in positions) {
      if (removed >= toRemove) break;
      final r = pos ~/ 9;
      final c = pos % 9;
      grid[r][c] = 0;
      removed++;
    }
  }

  // ========================================
  // 🎯 OBSŁUGA KLIKNIĘĆ I WPISYWANIA CYFR
  // ========================================

  // Gracz kliknął na komórkę
  void _onCellTap(int row, int col) {
    _startTimer(); // Zacznij odliczać przy pierwszym kliknięciu
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  // Gracz wpisał cyfrę
  void _onNumberInput(int num) {
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_gameSolved) return;

    // Nie można zmieniać oryginalnych cyfr z łamigłówki
    if (_puzzle[_selectedRow][_selectedCol] != 0) return;

    setState(() {
      if (num == 0) {
        // Usuń cyfrę
        _userInput[_selectedRow][_selectedCol] = 0;
      } else {
        _userInput[_selectedRow][_selectedCol] = num;
        // Sprawdź czy to błąd
        if (_solution[_selectedRow][_selectedCol] != num) {
          _errorCount++;
        }
      }
    });

    // Sprawdź czy sudoku jest rozwiązane
    _checkWin();
  }

  // 💡 Podpowiedź - wstaw poprawną cyfrę w zaznaczonym polu
  void _useHint() {
    if (_hintsLeft <= 0) return;
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_puzzle[_selectedRow][_selectedCol] != 0) return;

    setState(() {
      _userInput[_selectedRow][_selectedCol] =
          _solution[_selectedRow][_selectedCol];
      _hintsLeft--;
    });

    _checkWin();
  }

  // 🏆 Sprawdź czy plansza jest poprawnie wypełniona
  void _checkWin() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = _puzzle[r][c] != 0 ? _puzzle[r][c] : _userInput[r][c];
        if (cell != _solution[r][c]) return; // Nie ukończone
      }
    }

    // 🎉 Wygrał!
    _timer?.cancel();
    setState(() => _gameSolved = true);
    _saveBestTime();
    widget.onLevelCompleted?.call();
    _showWinDialog();
  }

  // ========================================
  // 🎉 DIALOG WYGRANEJ
  // ========================================
  void _showWinDialog() {
    final loc = AppLocalizations.of(context)!;
    final isNewRecord = _bestTime == _seconds;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            Text(loc.translate('sudoku_congratulations')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⏱️ ${loc.translate('time')}: ${_formatTime(_seconds)}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '❌ ${loc.translate('sudoku_errors')}: $_errorCount',
              style: const TextStyle(fontSize: 16),
            ),
            if (isNewRecord) ...[
              const SizedBox(height: 12),
              Text(
                '🏆 ${loc.translate('new_time_record')}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _generatePuzzle(); // Nowa gra na tym samym poziomie
            },
            child: Text(loc.translate('sudoku_new_game')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 🎨 BUDOWANIE INTERFEJSU
  // ========================================
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text('${loc.translate('sudoku_game_title')} - ${loc.translate('sudoku_level_${widget.level}')}'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.translate('sudoku_new_game'),
            onPressed: _generatePuzzle,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 📊 Pasek statystyk (czas, błędy, rekord)
            _buildStatsBar(loc),

            // 🔲 Plansza Sudoku 9x9
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildBoard(),
                ),
              ),
            ),

            // 🔢 Klawiatura z cyframi 1-9
            _buildNumberPad(loc),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 📊 Pasek z czasem, błędami i rekordem
  Widget _buildStatsBar(AppLocalizations loc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('⏱️ ${loc.translate('time')}', _formatTime(_seconds)),
          _buildStat('❌ ${loc.translate('sudoku_errors')}', '$_errorCount'),
          _buildStat(
            '💡 ${loc.translate('sudoku_hints_left')}',
            '$_hintsLeft',
          ),
          if (_bestTime > 0)
            _buildStat('🏆 ${loc.translate('sudoku_best_time')}', _formatTime(_bestTime)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  // 🔲 Buduje planszę 9x9
  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal.shade800, width: 3),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            final row = index ~/ 9;
            final col = index % 9;
            return _buildCell(row, col);
          },
        ),
      ),
    );
  }

  // 🔲 Jedna komórka planszy
  Widget _buildCell(int row, int col) {
    final isSelected = row == _selectedRow && col == _selectedCol;
    final isOriginal = _puzzle[row][col] != 0; // Cyfra z łamigłówki
    final value = isOriginal ? _puzzle[row][col] : _userInput[row][col];
    final isError = !isOriginal &&
        value != 0 &&
        value != _solution[row][col];

    // Kolory zaznaczenia
    Color bgColor = Colors.white;
    if (isSelected) {
      bgColor = Colors.teal.shade200;
    } else if (_selectedRow != -1 &&
        (_selectedRow == row ||
            _selectedCol == col ||
            (_selectedRow ~/ 3 == row ~/ 3 &&
                _selectedCol ~/ 3 == col ~/ 3))) {
      // Podświetl wiersz, kolumnę i kwadrat 3x3 zaznaczonej komórki
      bgColor = Colors.teal.shade50;
    }

    // Grubsze linie co 3 komórki (granice kwadratów 3x3)
    final borderRight = (col + 1) % 3 == 0 && col != 8
        ? BorderSide(color: Colors.teal.shade800, width: 2)
        : BorderSide(color: Colors.grey.shade300, width: 0.5);
    final borderBottom = (row + 1) % 3 == 0 && row != 8
        ? BorderSide(color: Colors.teal.shade800, width: 2)
        : BorderSide(color: Colors.grey.shade300, width: 0.5);

    return GestureDetector(
      onTap: () => _onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            right: borderRight,
            bottom: borderBottom,
          ),
        ),
        child: Center(
          child: value == 0
              ? null
              : Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        isOriginal ? FontWeight.bold : FontWeight.normal,
                    color: isError
                        ? Colors.red
                        : isOriginal
                            ? Colors.teal.shade900
                            : Colors.blue.shade700,
                  ),
                ),
        ),
      ),
    );
  }

  // 🔢 Klawiatura z cyframi 1-9 i podpowiedzią
  Widget _buildNumberPad(AppLocalizations loc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          // Cyfry 1-9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(9, (i) {
              final num = i + 1;
              return _buildNumButton(num);
            }),
          ),
          const SizedBox(height: 8),
          // Przyciski: Usuń i Podpowiedź
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Przycisk USUŃ (wymaże wpisaną cyfrę)
              ElevatedButton.icon(
                onPressed: () => _onNumberInput(0),
                icon: const Icon(Icons.backspace),
                label: const Text(''),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
              ),
              // Przycisk PODPOWIEDŹ
              ElevatedButton.icon(
                onPressed: _hintsLeft > 0 ? _useHint : null,
                icon: const Icon(Icons.lightbulb),
                label: Text('${loc.translate('sudoku_hint')} ($_hintsLeft)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔢 Jeden przycisk cyfry
  Widget _buildNumButton(int num) {
    return GestureDetector(
      onTap: () => _onNumberInput(num),
      child: Container(
        width: 34,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.teal.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.teal.shade300),
        ),
        child: Center(
          child: Text(
            '$num',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
        ),
      ),
    );
  }
}
