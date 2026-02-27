// ══════════════════════════════════════════════════════════════
// KROK 1: W main.dart zamień cały blok theme: ThemeData(...) na:
// ══════════════════════════════════════════════════════════════

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFF6366F1),   // neonowy indigo
          secondary: Color(0xFF00D084),   // neonowy zielony
          surface:   Color(0xFF111118),
          onSurface: Colors.white,
        ),
        useMaterial3: true,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D14),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        // BottomNavigationBar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0D0D14),
          selectedItemColor: Color(0xFF6366F1),
          unselectedItemColor: Color(0xFF555566),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        // Karty
        cardTheme: CardThemeData(
          color: const Color(0xFF111118),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),

        // Przyciski ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // OutlinedButton
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6366F1),
            side: const BorderSide(color: Color(0xFF6366F1), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // TextField
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A24),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),

        // Divider
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.08),
        ),

        // Chip (ChoiceChip filtry)
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF1A1A24),
          selectedColor: const Color(0xFF6366F1),
          labelStyle: const TextStyle(color: Colors.white),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF111118),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),

        // ListTile
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Color(0xFF6366F1),
        ),

        // PopupMenu
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF1A1A24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          textStyle: const TextStyle(color: Colors.white),
        ),

        // Switch & Slider
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFF6366F1)),
          trackColor: WidgetStateProperty.all(const Color(0xFF6366F1).withOpacity(0.3)),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF6366F1),
          thumbColor: Color(0xFF6366F1),
          overlayColor: Color(0x336366F1),
        ),
      ),


// ══════════════════════════════════════════════════════════════
// KROK 2: Znajdź BottomNavigationBar i zamień na:
// ══════════════════════════════════════════════════════════════

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D14),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: const Color(0xFF444455),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.timer_outlined),
              activeIcon: _navIcon(Icons.timer, const Color(0xFF6366F1)),
              label: 'Timer',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined),
              activeIcon: _navIcon(Icons.bar_chart, const Color(0xFF00D084)),
              label: AppLocalizations.of(context)!.translate('summary_title'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.gamepad_outlined),
              activeIcon: _navIcon(Icons.gamepad, const Color(0xFFFF6B35)),
              label: AppLocalizations.of(context)!.translate('games_tab'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.event_outlined),
              activeIcon: _navIcon(Icons.event, const Color(0xFF00B4D8)),
              label: AppLocalizations.of(context)!.translate('events_tab'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.timer_outlined),
              activeIcon: _navIcon(Icons.timer, const Color(0xFFFF3D3D)),
              label: AppLocalizations.of(context)!.translate('pomodoro_tab'),
            ),
          ],
        ),
      ),


// ══════════════════════════════════════════════════════════════
// KROK 3: Dodaj helper _navIcon do klasy _MainTabScreenState:
// ══════════════════════════════════════════════════════════════

  Widget _navIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
