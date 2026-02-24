import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

const _modeColors = {
  'work':  [Color(0xFFFF3D3D), Color(0xFFFF6B35)],
  'break': [Color(0xFF00D084), Color(0xFF00B4D8)],
  'long':  [Color(0xFFA855F7), Color(0xFF6366F1)],
};

const _modeBg = {
  'work':  Color(0xFF150808),
  'break': Color(0xFF081510),
  'long':  Color(0xFF0D0815),
};

const _modeStatusLabel = {
  'work':  'FOKUS',
  'break': 'PRZERWA',
  'long':  'RELAKS',
};

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({Key? key}) : super(key: key);

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage>
    with TickerProviderStateMixin {

  int _workMin   = 25;
  int _breakMin  = 5;
  int _longMin   = 15;
  int _sessLimit = 4;

  String _mode     = 'work';
  int    _left     = 25 * 60;
  int    _total    = 25 * 60;
  bool   _running  = false;
  int    _sessions = 0;
  int    _worked   = 0;
  int    _best     = 0;
  int    _streak   = 0;
  Timer? _ticker;

  late AnimationController _spinCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _blinkCtrl;
  late AnimationController _ringPulse;

  bool   _toastVisible = false;
  String _toastMsg     = '';

  Color  get _c1       => _modeColors[_mode]![0];
  Color  get _c2       => _modeColors[_mode]![1];
  Color  get _bg       => _modeBg[_mode]!;
  double get _progress => _left / _total;

  @override
  void initState() {
    super.initState();
    _spinCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _blinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _ringPulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _loadSettings();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _blinkCtrl.dispose();
    _ringPulse.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _workMin   = p.getInt('pomo_work')  ?? 25;
      _breakMin  = p.getInt('pomo_break') ?? 5;
      _longMin   = p.getInt('pomo_long')  ?? 15;
      _sessLimit = p.getInt('pomo_sess')  ?? 4;
      _left  = _workMin * 60;
      _total = _workMin * 60;
    });
  }

  Future<void> _saveSettings() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('pomo_work',  _workMin);
    await p.setInt('pomo_break', _breakMin);
    await p.setInt('pomo_long',  _longMin);
    await p.setInt('pomo_sess',  _sessLimit);
  }

  int _secsFor(String m) {
    if (m == 'work')  return _workMin * 60;
    if (m == 'break') return _breakMin * 60;
    return _longMin * 60;
  }

  void _setMode(String m) {
    _ticker?.cancel();
    setState(() {
      _mode    = m;
      _running = false;
      _left    = _secsFor(m);
      _total   = _secsFor(m);
    });
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (_left > 0) {
            _left--;
            if (_mode == 'work') _worked++;
          } else {
            _ticker?.cancel();
            _running = false;
            _finish();
          }
        });
      });
    }
  }

  void _finish() {
    if (_mode == 'work') {
      _sessions++; _streak++;
      if (_streak > _best) _best = _streak;
      _showToast('🍅 Niesamowite! Czas na przerwę!');
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) _setMode(_sessions % _sessLimit == 0 ? 'long' : 'break');
      });
    } else {
      _showToast('💪 Wracamy do pracy!');
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) _setMode('work');
      });
    }
  }

  void _reset() { _ticker?.cancel(); _setMode(_mode); }
  void _skip()  { _ticker?.cancel(); setState(() => _running = false); _finish(); }

  void _showToast(String msg) {
    setState(() { _toastMsg = msg; _toastVisible = true; });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final sw  = MediaQuery.of(context).size.width;
    // Pierścień: max 220px, min 160px, proporcjonalny do szerokości
    final ringSize = math.min(sw * 0.55, 220.0).clamp(160.0, 220.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      color: _bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [

          // Tło — subtelne orby
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final sh = MediaQuery.of(context).size.height;
              return Stack(children: [
                Positioned(
                  top:  -sh * 0.15 + _pulseCtrl.value * 10,
                  left: -sw * 0.2,
                  child: _orb(sw * 0.7, _c1, 0.11 + _pulseCtrl.value * 0.03),
                ),
                Positioned(
                  bottom: -sh * 0.1,
                  right:  -sw * 0.15,
                  child: _orb(sw * 0.55, _c2, 0.09),
                ),
              ]);
            },
          ),

          // Główna treść — SingleChildScrollView eliminuje overflow
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    const SizedBox(height: 12),

                    // ── Header ──────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('WORK STUDY TIMER',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10, fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: Colors.white.withOpacity(0.28),
                          ),
                        ),
                        GestureDetector(
                          onTap: _openSettings,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                              color: Colors.white.withOpacity(0.06),
                            ),
                            child: Icon(Icons.settings,
                                size: 15, color: Colors.white.withOpacity(0.4)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Mode tabs ────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(children: [
                        _modeTab('work',  '🍅 ${loc.translate('pomodoro_work')}'),
                        const SizedBox(width: 4),
                        _modeTab('break', '☕ ${loc.translate('pomodoro_break')}'),
                        const SizedBox(width: 4),
                        _modeTab('long',  '😴 ${loc.translate('pomodoro_long_break')}'),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    // ── Pierścień timera ─────────────────────────────────────
                    Center(child: _buildTimerRing(ringSize)),

                    const SizedBox(height: 20),

                    // ── Kontrolki ────────────────────────────────────────────
                    _buildControls(),

                    const SizedBox(height: 16),

                    // ── Sesje ────────────────────────────────────────────────
                    _buildSessionsBar(loc),

                    const SizedBox(height: 10),

                    // ── Statystyki ───────────────────────────────────────────
                    _buildStats(),

                    const SizedBox(height: 16),

                  ],
                ),
              ),
            ),
          ),

          // Toast
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            top: _toastVisible ? 56 : -70,
            left: 20, right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_c1, _c2]),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [BoxShadow(color: _c1.withOpacity(0.5), blurRadius: 24)],
                ),
                child: Text(_toastMsg,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

        ]),
      ),
    );
  }

  Widget _orb(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(opacity),
      boxShadow: [BoxShadow(color: color.withOpacity(opacity * 0.4), blurRadius: 70)],
    ),
  );

  Widget _modeTab(String mode, String label) {
    final active = _mode == mode;
    final colors = _modeColors[mode]!;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: active
                ? LinearGradient(colors: colors,
                begin: Alignment.centerLeft, end: Alignment.centerRight)
                : null,
            boxShadow: active
                ? [BoxShadow(color: colors[0].withOpacity(0.35), blurRadius: 14)]
                : [],
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: active ? Colors.white : Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerRing(double ringSize) {
    return SizedBox(
      width: ringSize + 24,
      height: ringSize + 24,
      child: Stack(alignment: Alignment.center, children: [

        // Obracający się glow-ring
        AnimatedBuilder(
          animation: _spinCtrl,
          builder: (_, __) => Transform.rotate(
            angle: _spinCtrl.value * 2 * math.pi,
            child: Container(
              width: ringSize + 24,
              height: ringSize + 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.transparent,
                    _c1.withOpacity(0.5),
                    _c2.withOpacity(0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.55, 1.0],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _bg),
              ),
            ),
          ),
        ),

        // Ring painter
        SizedBox(
          width: ringSize, height: ringSize,
          child: AnimatedBuilder(
            animation: _blinkCtrl,
            builder: (_, __) => CustomPaint(
              painter: _RingPainter(
                progress: _progress, color1: _c1, color2: _c2,
                glowOpacity: _running ? (0.5 + _blinkCtrl.value * 0.5) : 0.5,
              ),
            ),
          ),
        ),

        // Czas + status
        Column(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Colors.white, Color(0xFFCCCCCC)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ).createShader(b),
            child: Text(_fmt(_left),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: ringSize * 0.195,
                fontWeight: FontWeight.w900,
                color: Colors.white, letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _blinkCtrl,
              builder: (_, __) {
                final op = _running ? (0.3 + _blinkCtrl.value * 0.7) : 1.0;
                return Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _c1.withOpacity(op),
                    boxShadow: [BoxShadow(color: _c1.withOpacity(op * 0.8), blurRadius: 6)],
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              _running ? (_modeStatusLabel[_mode] ?? 'FOKUS')
                  : (_left < _total ? 'PAUZA' : 'GOTOWY'),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  letterSpacing: 3, color: _c1),
            ),
          ]),
        ]),

      ]),
    );
  }

  Widget _buildControls() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _ctrlBtn(Icons.skip_next, _skip, 48),
      const SizedBox(width: 16),
      GestureDetector(
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _ringPulse,
          builder: (_, __) => SizedBox(
            width: 76, height: 76,
            child: Stack(alignment: Alignment.center, children: [
              Opacity(
                opacity: (1 - _ringPulse.value) * 0.3,
                child: Container(
                  width: 62 + _ringPulse.value * 28,
                  height: 62 + _ringPulse.value * 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [_c1, _c2],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                ),
              ),
              Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_c1, _c2],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: _c1.withOpacity(0.4), blurRadius: 16)],
                ),
                child: Icon(_running ? Icons.pause : Icons.play_arrow,
                    color: Colors.white, size: 28),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 16),
      _ctrlBtn(Icons.refresh, _reset, 48),
    ]);
  }

  Widget _ctrlBtn(IconData icon, VoidCallback fn, double size) => GestureDetector(
    onTap: fn,
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        color: Colors.black.withOpacity(0.2),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.4), size: size * 0.42),
    ),
  );

  Widget _buildSessionsBar(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text('SESJE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    letterSpacing: 2, color: Colors.white.withOpacity(0.3))),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (b) => LinearGradient(colors: [_c1, _c2]).createShader(b),
              child: Text('$_sessions', style: const TextStyle(fontFamily: 'monospace',
                  fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ]),
          Row(
            children: List.generate(_sessLimit, (i) {
              final sessInCycle = _sessions % _sessLimit;
              final done = i < (sessInCycle == 0 && _sessions > 0 ? _sessLimit : sessInCycle);
              return Padding(
                padding: const EdgeInsets.only(left: 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: const Cubic(0.34, 1.56, 0.64, 1),
                  width: done ? 30 : 26, height: done ? 30 : 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? _c1.withOpacity(0.12) : Colors.transparent,
                    border: Border.all(
                        color: done ? _c1 : Colors.white.withOpacity(0.1), width: 1.5),
                    boxShadow: done
                        ? [BoxShadow(color: _c1.withOpacity(0.3), blurRadius: 8)]
                        : [],
                  ),
                  child: Center(child: Text(done ? '🍅' : '⭕',
                      style: const TextStyle(fontSize: 12))),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(children: [
      Expanded(child: _statCard('${_worked ~/ 60} min', 'DZIŚ ŁĄCZNIE')),
      const SizedBox(width: 10),
      Expanded(child: _statCard('$_best', 'REKORD SESJI')),
    ]);
  }

  Widget _statCard(String val, String label) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(children: [
      Text(val, style: const TextStyle(fontFamily: 'monospace',
          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
          letterSpacing: 1.5, color: Colors.white.withOpacity(0.3))),
    ]),
  );

  void _openSettings() {
    final loc = AppLocalizations.of(context)!;
    int tw = _workMin, tb = _breakMin, tl = _longMin, ts = _sessLimit;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: const Color(0xFF111118),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('⚙️ ${loc.translate('pomodoro_settings')}',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _settRow(loc.translate('pomodoro_work_time'),           tw, 1, 60, (v) => ss(() => tw = v)),
              _settRow(loc.translate('pomodoro_break_time'),          tb, 1, 30, (v) => ss(() => tb = v)),
              _settRow(loc.translate('pomodoro_long_break_time'),     tl, 5, 60, (v) => ss(() => tl = v)),
              _settRow(loc.translate('pomodoro_sessions_until_long'), ts, 2,  8, (v) => ss(() => ts = v)),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.translate('cancel'),
                  style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _c1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  _workMin = tw; _breakMin = tb;
                  _longMin = tl; _sessLimit = ts;
                  _ticker?.cancel(); _running = false;
                  _mode = 'work'; _left = tw * 60; _total = tw * 60;
                });
                _saveSettings();
                Navigator.pop(ctx);
              },
              child: Text(loc.translate('save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settRow(String label, int val, int min, int max, Function(int) onChange) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          Row(children: [
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Color(0xFFFF3D3D)),
              onPressed: val > min ? () => onChange(val - 1) : null,
            ),
            Text('$val', style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF00D084)),
              onPressed: val < max ? () => onChange(val + 1) : null,
            ),
          ]),
        ]),
      );
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color  color1;
  final Color  color2;
  final double glowOpacity;

  const _RingPainter({
    required this.progress, required this.color1,
    required this.color2,   required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r      = size.width / 2 - 8;

    canvas.drawCircle(center, r, Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12);

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    final rect  = Rect.fromCircle(center: center, radius: r);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..color = color1.withOpacity(0.2 * glowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));

    canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2, endAngle: -math.pi / 2 + sweep,
        colors: [color1, color2],
      ).createShader(rect));
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color1 != color1 || old.glowOpacity != glowOpacity;
}