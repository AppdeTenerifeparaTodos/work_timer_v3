import 'package:flutter/material.dart';
import 'pet_provider.dart';

// ══════════════════════════════════════════
// ZAKŁADKA DEVPET — 6. zakładka w work_timer_v4
// ══════════════════════════════════════════

class DevPetTab extends StatefulWidget {
  final PetProvider petProvider;
  const DevPetTab({Key? key, required this.petProvider}) : super(key: key);

  @override
  State<DevPetTab> createState() => _DevPetTabState();
}

class _DevPetTabState extends State<DevPetTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _bounceAnim;

  PetProvider get _pet => widget.petProvider;

  @override
  void initState() {
    super.initState();
    _pet.addListener(_onPetChanged);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  void _onPetChanged() {
    if (mounted) {
      setState(() {});
      // Sprawdź nagrody
      final rewards = _pet.popPendingRewards();
      for (final r in rewards) {
        _showRewardDialog(r);
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pet.removeListener(_onPetChanged);
    super.dispose();
  }

  // ── Kolory ─────────────────────────────
  Color get _color => _pet.speciesColor;

  Color _energyColor(int e) {
    if (e >= 70) return Colors.greenAccent;
    if (e >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  // ── UI ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('DevPet 🐾', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D0D14),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_outlined),
            tooltip: 'Kolekcja maskotek',
            onPressed: _showCollection,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPetCard(),
            const SizedBox(height: 14),
            _buildDailyXpCard(),
            const SizedBox(height: 14),
            _buildStatsRow(),
            const SizedBox(height: 14),
            _buildRewardsCard(),
            const SizedBox(height: 14),
            _buildTipsCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── KARTA MASKOTKI ─────────────────────
  Widget _buildPetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: _color.withOpacity(0.12), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Column(children: [
        // Nagłówek: nazwa + etap
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            _pet.speciesName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _color),
          ),
          const SizedBox(width: 8),
          _chip(_pet.stageName, _pet.stageEmoji),
        ]),
        const SizedBox(height: 20),

        // Animowana maskotka + mood
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _bounceAnim.value),
            child: child,
          ),
          child: Column(children: [
            Text(_pet.speciesEmoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 4),
            Text(_pet.mood, style: const TextStyle(fontSize: 28)),
          ]),
        ),
        const SizedBox(height: 20),

        // Pasek XP (etap)
        _buildBar(
          label: '${_pet.stageName} ${_pet.stageEmoji}  →  ${_pet.xp} XP',
          value: _pet.stageProgress,
          color: _color,
        ),
        const SizedBox(height: 10),

        // Pasek energii
        _buildBar(
          label: 'Energia  ${_pet.energy}%',
          value: _pet.energy / 100,
          color: _energyColor(_pet.energy),
        ),
        const SizedBox(height: 20),

        // Przycisk karmienia
        ElevatedButton.icon(
          onPressed: () {
            _pet.feed();
            _snack('😋 ${_pet.speciesName} nakarmiony! +15 energii 🍎');
          },
          icon: const Text('🍎', style: TextStyle(fontSize: 18)),
          label: const Text('Nakarm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _color.withOpacity(0.2),
            foregroundColor: _color,
            side: BorderSide(color: _color.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }

  // ── DZIENNY XP ─────────────────────────
  Widget _buildDailyXpCard() {
    final pct  = (_pet.xpToday / PetProvider.kDailyXpLimit).clamp(0.0, 1.0);
    final done = _pet.xpToday >= PetProvider.kDailyXpLimit;

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('⏱️  Dzienny XP',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(
            done ? '✅ Max!' : '${_pet.xpToday} / ${PetProvider.kDailyXpLimit}',
            style: TextStyle(
              fontSize: 13,
              color: done ? Colors.greenAccent : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct, minHeight: 10,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              done ? Colors.greenAccent : const Color(0xFF6366F1),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          done
            ? '🎉 Świetna robota! Jutro możesz zdobyć kolejne XP.'
            : '1 XP za każde 5 min nauki. Max ${PetProvider.kDailyXpLimit} XP dziennie.',
          style: const TextStyle(fontSize: 11, color: Colors.white38),
        ),
      ]),
    );
  }

  // ── STATYSTYKI (3 kafle) ────────────────
  Widget _buildStatsRow() {
    return Row(children: [
      _statTile('Łączne XP',  '${_pet.xp}',                   '⭐'),
      const SizedBox(width: 12),
      _statTile('Kolekcja',   '${_pet.collection.length}/10',  '🏆'),
      const SizedBox(width: 12),
      _statTile('Etap',       _pet.stageName,                  _pet.stageEmoji),
    ]);
  }

  Widget _statTile(String label, String value, String emoji) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.white38),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── NAGRODY ────────────────────────────
  Widget _buildRewardsCard() {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🎁  Nagrody za kolekcję',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 14),
        ...kCollectionRewards.entries.map((e) {
          final unlocked = _pet.collection.length >= e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Text(e.value['emoji']!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  e.value['title']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: unlocked ? Colors.white : Colors.white38,
                  ),
                ),
                Text(
                  '${e.key} maskotek — ${e.value['desc']!}',
                  style: const TextStyle(fontSize: 11, color: Colors.white30),
                ),
              ])),
              if (unlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✓', style: TextStyle(color: Colors.greenAccent, fontSize: 13)),
                )
              else
                Text(
                  '${_pet.collection.length}/${e.key}',
                  style: const TextStyle(color: Colors.white30, fontSize: 12),
                ),
            ]),
          );
        }).toList(),
      ]),
    );
  }

  // ── PORADY ─────────────────────────────
  Widget _buildTipsCard() {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💡  Jak to działa?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        _tip('⏱️', 'Pracuj/ucz się — za każde 5 minut dostajesz 1 XP'),
        _tip('🌙', 'Max 100 XP dziennie — limit resetuje się o północy'),
        _tip('🦅', 'Po 1000 XP maskotka przechodzi na emeryturę'),
        _tip('🔄', 'Zbierz wszystkie 10 maskotek i odblokuj nagrody!'),
        _tip('😴', 'Karm maskotkę — energia spada gdy nie pracujesz'),
      ]),
    );
  }

  Widget _tip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ),
      ]),
    );
  }

  // ── KOLEKCJA (modal) ───────────────────
  void _showCollection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111118),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, ctrl) => Column(children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🏆 Kolekcja Maskotek',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              '${_pet.collection.length} / ${PetSpecies.values.length} zebrano',
              style: const TextStyle(fontSize: 13, color: Colors.white38),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: PetSpecies.values.length,
                itemBuilder: (_, i) {
                  final sp = PetSpecies.values[i];
                  final info = kSpeciesInfo[sp]!;
                  final collected = _pet.collection.firstWhere(
                    (c) => c.species == sp,
                    orElse: () => CollectedPet(species: sp, retiredAt: DateTime.now(), totalXp: 0),
                  );
                  final isCollected = _pet.collection.any((c) => c.species == sp);
                  final isCurrent   = _pet.species == sp;
                  final color = Color(int.parse('FF${info['color']}', radix: 16));

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCollected || isCurrent
                          ? color.withOpacity(0.1)
                          : const Color(0xFF0A0A0F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent
                            ? color.withOpacity(0.7)
                            : isCollected
                                ? color.withOpacity(0.35)
                                : Colors.white10,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(
                            isCollected || isCurrent ? info['emoji']! : '❓',
                            style: TextStyle(
                              fontSize: 24,
                              color: isCollected || isCurrent ? null : Colors.white24,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 4),
                            const Text('⭐', style: TextStyle(fontSize: 12)),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          isCollected || isCurrent ? info['name']! : '???',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCollected || isCurrent ? color : Colors.white24,
                          ),
                        ),
                        if (isCollected)
                          Text(
                            '${collected.totalXp} XP',
                            style: const TextStyle(fontSize: 10, color: Colors.white38),
                          ),
                        if (isCurrent && !isCollected)
                          Text(
                            'Aktualny',
                            style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ]),
        );
      },
    );
  }

  // ── Nagroda dialog ─────────────────────
  void _showRewardDialog(Map<String, String> reward) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF111118),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(reward['emoji']!, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              '🎊 Nagroda odblokowana!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              reward['title']!,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amberAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              reward['desc']!,
              style: const TextStyle(fontSize: 13, color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Super! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF111118),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: child,
  );

  Widget _chip(String label, String emoji) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$emoji $label',
      style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600),
    ),
  );

  Widget _buildBar({required String label, required double value, required Color color}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value, minHeight: 8,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _color.withOpacity(0.9),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
