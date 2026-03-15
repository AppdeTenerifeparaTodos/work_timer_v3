import 'package:flutter/material.dart';
import 'alarm_service.dart';

/// Pokazuje bottomSheet z listą dźwięków do wyboru.
/// Zwraca wybrany AlarmSound lub null jeśli anulowano.
Future<AlarmSound?> showAlarmPicker({
  required BuildContext context,
  required String currentSoundId,
}) {
  return showModalBottomSheet<AlarmSound>(
    context: context,
    backgroundColor: const Color(0xFF0D0D14),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AlarmPickerSheet(currentSoundId: currentSoundId),
  );
}

class _AlarmPickerSheet extends StatefulWidget {
  final String currentSoundId;
  const _AlarmPickerSheet({required this.currentSoundId});

  @override
  State<_AlarmPickerSheet> createState() => _AlarmPickerSheetState();
}

class _AlarmPickerSheetState extends State<_AlarmPickerSheet> {
  late String _selectedId;
  final AlarmService _alarm = AlarmService();

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentSoundId;
  }

  @override
  void dispose() {
    _alarm.stop(); // zatrzymaj podgląd przy zamknięciu
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Wybierz dźwięk alarmu',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: kAlarmSounds.length,
            itemBuilder: (ctx, i) {
              final sound = kAlarmSounds[i];
              final isSelected = sound.id == _selectedId;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedId = sound.id);
                  _alarm.preview(sound.fileName);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1).withOpacity(0.15)
                        : const Color(0xFF1A1A24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.white12,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? const Color(0xFF6366F1) : Colors.white38,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(sound.displayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            )),
                      ),
                      // Przycisk podglądu
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline, color: Colors.white38, size: 24),
                        onPressed: () => _alarm.preview(sound.fileName),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Anuluj'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final selected = kAlarmSounds.firstWhere((s) => s.id == _selectedId);
                    Navigator.of(context).pop(selected);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Wybierz', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
      ],
    );
  }
}

// ── Ekran STOP alarmu ──────────────────────────────────────────────────────
// Pokazuje się gdy alarm gra — użytkownik musi kliknąć STOP

class AlarmStopScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onStop;

  const AlarmStopScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsujące kółko
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.1),
                  duration: const Duration(milliseconds: 800),
                  builder: (ctx, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      border: Border.all(color: const Color(0xFF6366F1), width: 2),
                    ),
                    child: const Icon(Icons.alarm, color: Color(0xFF6366F1), size: 56),
                  ),
                ),
                const SizedBox(height: 32),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 15)),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_circle_outlined, size: 28),
                    label: const Text('STOP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: Colors.red.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}