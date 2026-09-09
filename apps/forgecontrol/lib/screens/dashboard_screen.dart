import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../store/system_store.dart';

const _temps = [40, 55, 70, 85, 100];
const _swatches = [
  0xFF22D3EE, 0xFFF472B6, 0xFFA78BFA, 0xFF34D399,
  0xFFFB923C, 0xFFFACC15, 0xFFF8FAFC, 0xFF334155,
];
const _effects = ['static', 'breathing', 'cycle', 'wave'];

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
    _rgbAnim = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
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
          title: const Text('◈ Forge Control'),
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
      if (smp?.demo == true)
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Demo telemetry on web'),
            subtitle: Text('Real CPU/RAM readings appear in the Windows build.'),
          ),
        ),
      Row(children: [
        Expanded(child: _gauge('CPU', cpu, Colors.cyan)),
        const SizedBox(width: 12),
        Expanded(child: _gauge('RAM', ramPct, Colors.purple)),
      ]),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CPU load — last 60s',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                    value: ramPct / 100, minHeight: 10,
                    borderRadius: BorderRadius.circular(6)),
                const SizedBox(height: 8),
                Text('Uptime ${smp?.uptimeMin ?? 0} min',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
        ),
      ),
      const SizedBox(height: 12),
      const Text('Performance mode',
          style: TextStyle(fontWeight: FontWeight.bold)),
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
          child: Text(s.schemeNote,
              style: Theme.of(context).textTheme.bodySmall),
        ),
    ]);
  }

  Widget _gauge(String label, double pct, Color c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 110,
              height: 110,
              child: CircularProgressIndicator(
                  value: pct / 100, strokeWidth: 12,
                  backgroundColor: Colors.white10, color: c),
            ),
            Text('${pct.toStringAsFixed(0)}%',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
        ]),
      ),
    );
  }

  Widget _fansTab(SystemStore s) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Curve stored per profile'),
          subtitle: Text(
              'Direct fan control needs the vendor driver — curve applies fully where supported, otherwise it documents your target.'),
        ),
      ),
      for (var i = 0; i < 5; i++)
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              SizedBox(
                  width: 64,
                  child: Text('${_temps[i]}°C',
                      style: const TextStyle(fontWeight: FontWeight.bold))),
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
                      textAlign: TextAlign.end)),
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
                    fontWeight: FontWeight.w800, letterSpacing: 3)),
          );
        },
      ),
      const SizedBox(height: 12),
      const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    color: on ? Colors.white : Colors.transparent, width: 3),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
      const Text('Effect', style: TextStyle(fontWeight: FontWeight.bold)),
      DropdownButtonFormField<String>(
        initialValue: s.rgbEffect,
        items: _effects
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => v != null ? s.setRgb(effect: v) : null,
      ),
      Row(children: [
        const Text('Brightness'),
        Expanded(
          child: Slider(
            value: s.brightness,
            onChanged: (v) => s.setRgb(bright: v),
          ),
        ),
        Text('${(s.brightness * 100).toInt()}%'),
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
                labelText: 'Save current setup as…',
                border: OutlineInputBorder(),
                isDense: true),
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
      color: on ? Colors.cyan.withValues(alpha: 0.08) : null,
      child: ListTile(
        leading: Icon(Icons.person,
            color: on ? Colors.cyan : null),
        title: Text(p.name,
            style: TextStyle(
                fontWeight: on ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(
            '${p.mode} • fan ${p.fanCurve.first}–${p.fanCurve.last}% • ${p.rgbEffect}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (!on)
            TextButton(
                onPressed: () => s.applyProfile(p),
                child: const Text('Apply')),
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

class _SparkPainter extends CustomPainter {
  final List<double> values;
  _SparkPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / 59;
      final y = size.height * (1 - (values[i].clamp(0, 100) / 100));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values;
}
