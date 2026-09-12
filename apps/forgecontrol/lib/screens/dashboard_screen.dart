import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../store/system_store.dart';
import '../theme.dart';

const _temps = [40, 55, 70, 85, 100];
const _swatches = [
  0xFF22D3EE, 0xFFF472B6, 0xFFA78BFA, 0xFF34D399,
  0xFFFB923C, 0xFFE8C15A, 0xFFF8FAFC, 0xFF334155,
];
const _effects = ['static', 'breathing', 'cycle', 'wave'];

String get _osName {
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
      return 'Windows';
    case TargetPlatform.android:
      return 'Android';
    case TargetPlatform.iOS:
      return 'iOS';
    case TargetPlatform.linux:
      return 'Linux';
    case TargetPlatform.macOS:
      return 'macOS';
    default:
      return 'Web';
  }
}

class DashboardScreen extends StatefulWidget {
  final SystemStore store;
  const DashboardScreen({super.key, required this.store});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rgbAnim;

  @override
  void initState() {
    super.initState();
    _rgbAnim = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _rgbAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final smp = s.sample;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [
            const Text('◈ ', style: TextStyle(color: ForgeColors.cy)),
            const Text('Forge Control'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: ForgeColors.gold),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(_osName.toUpperCase(),
                  style: const TextStyle(
                      color: ForgeColors.gold,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          bottom: const TabBar(tabs: [
            Tab(text: 'Monitor', icon: Icon(Icons.monitor_heart, size: 18)),
            Tab(text: 'Fans', icon: Icon(Icons.air, size: 18)),
            Tab(text: 'RGB', icon: Icon(Icons.lightbulb, size: 18)),
            Tab(text: 'Profiles', icon: Icon(Icons.person, size: 18)),
          ]),
        ),
        body: TabBarView(children: [
          _monitorTab(s, smp),
          _fansTab(s),
          _rgbTab(s),
          _profilesTab(s),
        ]),
      ),
    );
  }

  Widget _monitorTab(SystemStore s, smp) {
    final cpu = smp?.cpu ?? 0;
    final ramPct = smp?.ramPct ?? 0;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _heroCard(s, smp),
      const SizedBox(height: 12),
      if (smp?.demo == true)
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline, color: ForgeColors.gold),
            title: Text('Demo telemetry', style: TextStyle(color: ForgeColors.txt)),
            subtitle: Text('Real CPU / RAM readings appear in the Windows build.'),
          ),
        ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _AnimatedGauge('CPU', cpu, ForgeColors.cy)),
        const SizedBox(width: 12),
        Expanded(child: _AnimatedGauge('RAM', ramPct, ForgeColors.mg)),
      ]),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CPU load — last 60s',
                    style: TextStyle(fontWeight: FontWeight.bold, color: ForgeColors.txt)),
                const SizedBox(height: 8),
                SizedBox(
                    height: 90,
                    child: CustomPaint(
                      painter: _SparkPainter(s.cpuHistory),
                      size: Size.infinite,
                    )),
              ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'RAM  ${smp?.ramUsedGB.toStringAsFixed(1)} / ${smp?.ramTotalGB.toStringAsFixed(1)} GB',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: ForgeColors.txt)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: ramPct.clamp(2, 100) / 100),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 12,
                        backgroundColor: ForgeColors.line,
                        color: ForgeColors.cy),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Uptime ${smp?.uptimeMin ?? 0} min',
                    style: const TextStyle(color: ForgeColors.mut, fontSize: 12)),
              ]),
        ),
      ),
      const SizedBox(height: 12),
      const Text('Performance mode',
          style: TextStyle(fontWeight: FontWeight.bold, color: ForgeColors.txt)),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'silent', label: Text('Silent'), icon: Icon(Icons.bedtime)),
          ButtonSegment(value: 'balanced', label: Text('Balanced'), icon: Icon(Icons.balance)),
          ButtonSegment(value: 'performance', label: Text('Forge'), icon: Icon(Icons.bolt)),
        ],
        selected: {s.mode},
        onSelectionChanged: (v) => s.setMode(v.first),
      ),
      if (s.schemeNote.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(s.schemeNote, style: const TextStyle(color: ForgeColors.mut)),
        ),
    ]);
  }

  Widget _heroCard(SystemStore s, smp) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ForgeColors.card, ForgeColors.bg2],
        ),
        border: Border.all(color: ForgeColors.line),
        boxShadow: [BoxShadow(color: ForgeColors.cy.withValues(alpha: 0.10), blurRadius: 30)],
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SYSTEM HEALTH',
                  style: TextStyle(
                      fontSize: 11, letterSpacing: 2, color: ForgeColors.gold, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.diamond_outlined, color: ForgeColors.cy, size: 16),
                const SizedBox(width: 6),
                Text(s.mode.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 1.5, color: ForgeColors.txt)),
              ]),
              const SizedBox(height: 4),
              Text('${s.schemeNote.isNotEmpty ? s.schemeNote : 'Powered up'}',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ForgeColors.mut, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.bolt, color: ForgeColors.gold, size: 30),
      ]),
    );
  }

  Widget _fansTab(SystemStore s) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline, color: ForgeColors.gold),
          title: Text('Curve stored per profile', style: TextStyle(color: ForgeColors.txt)),
          subtitle: Text(
              'Direct fan control needs the vendor driver — curve applies fully where supported, otherwise it documents your target.'),
        ),
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < 5; i++)
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              SizedBox(
                  width: 64,
                  child: Text('${_temps[i]}°C',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: ForgeColors.txt))),
              Expanded(
                child: Slider(
                  value: s.fanCurve[i].toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${s.fanCurve[i]}%',
                  onChanged: (v) => setState(() => s.setFan(i, v.toInt())),
                ),
              ),
              SizedBox(
                  width: 52,
                  child: Text('${s.fanCurve[i]}%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: ForgeColors.cy, fontWeight: FontWeight.w700))),
            ]),
          ),
        ),
    ]);
  }

  Widget _rgbTab(SystemStore s) {
    final base = Color(s.rgbColor);
    return ListView(padding: const EdgeInsets.all(16), children: [
      AnimatedBuilder(
        animation: _rgbAnim,
        builder: (_, _) {
          final t = _rgbAnim.value;
          Color c = base;
          if (s.rgbEffect == 'cycle' || s.rgbEffect == 'wave') {
            c = HSVColor.fromAHSV(1, (t * 360) % 360, 0.85, 1).toColor();
          }
          final glow = s.rgbEffect == 'breathing'
              ? 0.45 + 0.55 * (0.5 + 0.5 * (3.14159 * 2 * t - 1.5707).clamp(-1.0, 1.0).abs())
              : 1.0;
          return Container(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [
                c.withValues(alpha: (s.brightness * glow).clamp(0.05, 1.0)),
                c.withValues(alpha: 0.08),
              ]),
              border: Border.all(color: c.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                    color: c.withValues(alpha: 0.35 * s.brightness),
                    blurRadius: 28)
              ],
            ),
            alignment: Alignment.center,
            child: Text(s.rgbEffect.toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, letterSpacing: 3, color: ForgeColors.txt)),
          );
        },
      ),
      const SizedBox(height: 12),
      const Text('Color', style: TextStyle(fontWeight: FontWeight.bold, color: ForgeColors.txt)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        children: _swatches.map((argb) {
          final on = s.rgbColor == argb;
          return InkWell(
            onTap: () => s.setRgb(color: argb),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(argb),
                shape: BoxShape.circle,
                border: Border.all(
                    color: on ? ForgeColors.gold : ForgeColors.line, width: 3),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
      const Text('Effect', style: TextStyle(fontWeight: FontWeight.bold, color: ForgeColors.txt)),
      DropdownButtonFormField<String>(
        initialValue: s.rgbEffect,
        items: _effects.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => v != null ? s.setRgb(effect: v) : null,
      ),
      Row(children: [
        const Text('Brightness', style: TextStyle(color: ForgeColors.mut)),
        Expanded(
          child: Slider(
            value: s.brightness,
            onChanged: (v) => s.setRgb(bright: v),
          ),
        ),
        Text('${(s.brightness * 100).toInt()}%',
            style: const TextStyle(color: ForgeColors.cy, fontWeight: FontWeight.w700)),
      ]),
    ]);
  }

  Widget _profilesTab(SystemStore s) {
    final name = TextEditingController();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(
          child: TextField(
            controller: name,
            decoration: const InputDecoration(
                labelText: 'Save current setup as…', isDense: true),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty) return;
            s.saveProfile(name.text.trim());
            name.clear();
          },
          child: const Text('Save'),
        ),
      ]),
      const SizedBox(height: 12),
      for (final p in s.profiles) _profileTile(s, p),
    ]);
  }

  Widget _profileTile(SystemStore s, ForgeProfile p) {
    final on = s.activeProfile == p.name;
    return Card(
      color: on ? ForgeColors.cy.withValues(alpha: 0.08) : null,
      child: ListTile(
        leading: Icon(Icons.person, color: on ? ForgeColors.cy : ForgeColors.mut),
        title: Text(p.name,
            style: TextStyle(
                color: ForgeColors.txt,
                fontWeight: on ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(
            '${p.mode} • fan ${p.fanCurve.first}–${p.fanCurve.last}% • ${p.rgbEffect}',
            style: const TextStyle(color: ForgeColors.mut)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (!on)
            TextButton(onPressed: () => s.applyProfile(p), child: const Text('Apply')),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => s.deleteProfile(p.name),
            icon: const Icon(Icons.delete_outline),
          ),
        ]),
      ),
    );
  }
}

/// Smooth gauge that animates to each new value.
class _AnimatedGauge extends StatefulWidget {
  final String label;
  final double pct;
  final Color color;
  const _AnimatedGauge(this.label, this.pct, this.color);

  @override
  State<_AnimatedGauge> createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<_AnimatedGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = Tween(begin: 0.0, end: widget.pct.clamp(0.0, 100.0))
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void didUpdateWidget(_AnimatedGauge old) {
    super.didUpdateWidget(old);
    if (old.pct != widget.pct) {
      final from = _anim.value;
      _anim = Tween(begin: from, end: widget.pct.clamp(0.0, 100.0))
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final v = _anim.value.clamp(0, 100);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(widget.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: ForgeColors.txt)),
              const SizedBox(height: 8),
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                      value: v / 100,
                      strokeWidth: 12,
                      backgroundColor: ForgeColors.line,
                      color: widget.color,
                      strokeCap: StrokeCap.round),
                ),
                Text('${v.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: ForgeColors.txt)),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  _SparkPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final step = size.width / 59;
    final path = Path();
    Offset? last;
    for (var i = 0; i < values.length; i++) {
      final x = i * step;
      final y = size.height * (1 - (values[i].clamp(0, 100) / 100));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      last = Offset(x, y);
    }
    if (last == null) return;
    // soft glow underlay.
    canvas.drawPath(
      path,
      Paint()
        ..color = ForgeColors.cy.withValues(alpha: 0.30)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // gradient main line.
    final shader = const SweepGradient(
      colors: [ForgeColors.cy, ForgeColors.vi, ForgeColors.mg, ForgeColors.cy],
    ).createShader(Offset.zero & size);
    canvas.drawPath(
      path,
      Paint()
        ..shader = shader
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values;
}