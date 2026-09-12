import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profile.dart';
import '../store/system_store.dart';
import '../theme.dart';

const _temps = [40, 55, 70, 85, 100];
const _swatches = [
  0xFF22D3EE, 0xFFF472B6, 0xFFA78BFA, 0xFF34D399,
  0xFFFB923C, 0xFFE8C15A, 0xFFF8FAFC, 0xFF334155,
];
const _effects = ['static', 'breathing', 'cycle', 'wave', 'strobing'];

const _repo = 'github.com/FORGESTUDIO-303/forge';

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

class _Section {
  final IconData icon, activeIcon;
  final String label;
  const _Section(this.icon, this.activeIcon, this.label);
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rgbAnim;
  late final AnimationController _fanSpin;
  int _tab = 0;
  final List<bool> _deviceSync = [true, true, true, true, true, true, true, true, true];

  static const _nav = <_Section>[
    _Section(Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    _Section(Icons.devices_other_outlined, Icons.devices_other, 'Devices'),
    _Section(Icons.lightbulb_outline, Icons.lightbulb, 'Aura Sync'),
    _Section(Icons.bolt_outlined, Icons.bolt, 'Performance'),
    _Section(Icons.air, Icons.air, 'Fans'),
    _Section(Icons.manage_accounts_outlined, Icons.manage_accounts, 'Profiles'),
  ];

  @override
  void initState() {
    super.initState();
    _rgbAnim = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _fanSpin = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _rgbAnim.dispose();
    _fanSpin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    return Scaffold(
      body: Row(
        children: [
          _SideRail(
            tab: _tab,
            onSelect: (i) => setState(() => _tab = i),
            onAbout: () => showDialog(context: context, builder: (_) => const _AboutDialog()),
          ),
          Expanded(
            child: Column(
              children: [
                _header(s),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: switch (_tab) {
                        0 => _overviewView(s),
                        1 => _devicesView(s),
                        2 => _auraView(s),
                        3 => _performanceView(s),
                        4 => _fansView(s),
                        _ => _profilesView(s),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(SystemStore s) {
    final sec = _nav[_tab].label;
    final on = _tab == 3 && s.mode != 'balanced';
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ForgeColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FORGE CONTROL / OVERVIEW',
                  style: TextStyle(
                      fontSize: 10, letterSpacing: 3, color: ForgeColors.mut, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(sec,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: ForgeColors.txt)),
              ],
            ),
          ),
          if (on)
            const _Chip(
              icon: null,
              label: 'POWERED UP',
              color: ForgeColors.red,
              bg: Color(0x26FF2D3F),
            ),
          const SizedBox(width: 8),
          _Chip(
            icon: null,
            label: s.mode.toUpperCase(),
            color: ForgeColors.cy,
            bg: ForgeColors.cy.withValues(alpha: 0.10),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () => showDialog(context: context, builder: (_) => const _AboutDialog()),
            child: const _Chip(
              icon: Icons.code_rounded,
              label: 'MIT · OPEN SOURCE',
              color: ForgeColors.gold,
              bg: Color(0x1FE8C15A),
            ),
          ),
        ],
      ),
    );
  }

  /* ---------------- Overview ---------------- */
  Widget _overviewView(SystemStore s) {
    final smp = s.sample;
    final cpu = smp?.cpu ?? 0.0;
    final ram = (smp?.ramPct ?? 0).clamp(0.0, 100.0);
    final load = (cpu + ram) / 2;
    return ListView(padding: const EdgeInsets.all(20), children: [
      // hero banner, Armoury style.
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF171B2C), ForgeColors.cardSoft],
          ),
          border: Border.all(color: ForgeColors.line),
          boxShadow: [
            BoxShadow(color: ForgeColors.cy.withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: ForgeColors.goldGradient,
                boxShadow: [
                  BoxShadow(color: ForgeColors.gold.withValues(alpha: 0.45), blurRadius: 24),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.diamond, color: Color(0xFF1A1206), size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('FORGE CONTROL',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: ForgeColors.txt)),
                      SizedBox(width: 10),
                      Text('v1.1',
                          style: TextStyle(color: ForgeColors.gold, fontSize: 11, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Universal system & hardware suite.',
                      style: TextStyle(color: ForgeColors.mut, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const _Chip(
                          icon: Icons.check_circle_rounded,
                          label: 'SENSORS ONLINE',
                          color: ForgeColors.gr,
                          bg: Color(0x1F34D399)),
                      const SizedBox(width: 8),
                      _Chip(
                          icon: null,
                          label: _osName.toUpperCase(),
                          color: ForgeColors.gold,
                          bg: ForgeColors.gold.withValues(alpha: 0.12)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_right_rounded, color: ForgeColors.mut),
          ],
        ),
      ),
      const SizedBox(height: 16),
      // gauges + side panel, Armoury-style.
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: _acCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SecTitle('SYSTEM PERFORMANCE'),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _Gauge(label: 'CPU', value: cpu, color: ForgeColors.cy)),
                      const SizedBox(width: 8),
                      Expanded(child: _Gauge(label: 'MEMORY', value: ram, color: ForgeColors.vi)),
                      const SizedBox(width: 8),
                      Expanded(child: _Gauge(label: 'LOAD', value: load, color: ForgeColors.gold)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SecTitle('CPU — LAST 60 SEC'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 92,
                    child: CustomPaint(painter: _SparkPainter(s.cpuHistory), size: Size.infinite),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _acCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SecTitle('LIVE STATUS'),
                      const SizedBox(height: 8),
                      _statusRow('CPU load', '${cpu.toStringAsFixed(0)} %', ForgeColors.cy),
                      _statusRow('Memory', '${smp?.ramUsedGB.toStringAsFixed(1)} / ${smp?.ramTotalGB.toStringAsFixed(1)} GB', ForgeColors.vi),
                      _statusRow('Uptime', '${smp?.uptimeMin ?? 0} min', ForgeColors.gold),
                      _statusRow('Power plan', s.schemeNote.isEmpty ? 'active' : s.schemeNote, ForgeColors.gr,
                          mono: true),
                      const SizedBox(height: 8),
                      if (smp?.demo == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Demo telemetry — real readings appear in the Windows build.',
                              style: TextStyle(color: ForgeColors.mut, fontSize: 11)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _acCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SecTitle('QUICK MODES'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _ModeTile(s, 'silent', Icons.bedtime_outlined, 'Silent')),
                          const SizedBox(width: 8),
                          Expanded(child: _ModeTile(s, 'balanced', Icons.balance, 'Balanced')),
                          const SizedBox(width: 8),
                          Expanded(child: _ModeTile(s, 'performance', Icons.bolt, 'Forge')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _statusRow(String k, String v, Color c, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(k, style: const TextStyle(color: ForgeColors.mut, fontSize: 13)),
          const Spacer(),
          Text(v,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                  color: ForgeColors.txt,
                  fontSize: 12,
                  fontFamily: mono ? 'Consolas' : null,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _ModeTile(SystemStore s, String mode, IconData icon, String label) {
    final on = s.mode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => s.setMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? ForgeColors.red : ForgeColors.line, width: on ? 2 : 1),
          color: on ? ForgeColors.red.withValues(alpha: 0.12) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: on ? ForgeColors.red : ForgeColors.mut),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: on ? ForgeColors.red : ForgeColors.mut)),
          ],
        ),
      ),
    );
  }

  /* ---------------- Devices ---------------- */
  Widget _devicesView(SystemStore s) {
    final icon = <IconData>[
      Icons.developer_board_rounded,
      Icons.memory,
      Icons.settings_input_hdmi,
      Icons.workspaces,
      Icons.storage_rounded,
      Icons.keyboard_alt_outlined,
      Icons.mouse_outlined,
      Icons.headphones_outlined,
      Icons.air,
    ];
    final name = <String>[
      'Motherboard', 'CPU', 'Graphics card', 'Memory',
      'Storage', 'Keyboard', 'Mouse', 'Headset', 'Chassis fans',
    ];
    final spec = <String>[
      'B650E FORGE · BIOS 1.2.3', '16C / 32T · 70 W TDP', '12 GB · driver OK',
      'DDR5 32 GB · XMP', 'M.2 NVMe · 1 TB', 'Wired · profile 1',
      '2600 DPI · 1000 Hz', '7.1 · wireless', '3× 120 mm · curve linked',
    ];
    final status = s.sample?.demo == true ? 'SIMULATED' : 'ONLINE';
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: _acCard(),
        child: Row(
          children: [
            const Icon(Icons.cast_connected_rounded, color: ForgeColors.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FORGE SYNC',
                      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, color: ForgeColors.txt)),
                  const Text('One switch for every detected component.',
                      style: TextStyle(color: ForgeColors.mut, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: _deviceSync.every((e) => e),
              activeTrackColor: ForgeColors.red,
              activeThumbColor: Colors.white,
              onChanged: (v) => setState(() {
                for (var i = 0; i < _deviceSync.length; i++) {
                  _deviceSync[i] = v;
                }
              }),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
        ),
        itemCount: name.length,
        itemBuilder: (_, i) {
          final on = _deviceSync[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: on ? ForgeColors.line : ForgeColors.line),
              color: const Color(0xFF121728),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: on ? ForgeColors.cy.withValues(alpha: 0.12) : ForgeColors.bg2,
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon[i], size: 18, color: on ? ForgeColors.cy : ForgeColors.mut),
                    ),
                    const Spacer(),
                    Switch(
                      value: on,
                      activeTrackColor: ForgeColors.red,
                      activeThumbColor: Colors.white,
                      onChanged: (v) => setState(() => _deviceSync[i] = v),
                    ),
                  ],
                ),
                Text(name[i], style: const TextStyle(fontWeight: FontWeight.w700, color: ForgeColors.txt)),
                Row(
                  children: [
                    Expanded(
                      child: Text(spec[i],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: ForgeColors.mut, fontSize: 11)),
                    ),
                    Text(status,
                        style: const TextStyle(color: ForgeColors.gr, fontSize: 9, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ]);
  }

  /* ---------------- Aura Sync ---------------- */
  Widget _auraView(SystemStore s) {
    final base = Color(s.rgbColor);
    return ListView(padding: const EdgeInsets.all(20), children: [
      AnimatedBuilder(
        animation: _rgbAnim,
        builder: (_, _) {
          final t = _rgbAnim.value;
          Color c = base;
          if (s.rgbEffect == 'cycle' || s.rgbEffect == 'wave') {
            c = HSVColor.fromAHSV(1, (t * 360) % 360, 0.85, 1).toColor();
          }
          final breathe =
              s.rgbEffect == 'breathing' ? (0.5 + 0.5 * math.sin(2 * math.pi * t)) : 1.0;
          final glow = (s.brightness * breathe).clamp(0.05, 1.0);
          return Container(
            height: 168,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(colors: [
                c.withValues(alpha: glow),
                c.withValues(alpha: 0.06),
              ]),
              border: Border.all(color: c.withValues(alpha: 0.55), width: 2),
              boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35 * glow), blurRadius: 34)],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('AURA SYNC', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 5, color: ForgeColors.txt)),
                const SizedBox(height: 6),
                Text(s.rgbEffect.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 3, fontSize: 12, color: c)),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: _acCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SecTitle('EFFECTS'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _effects.map((e) {
                      final on = s.rgbEffect == e;
                      return InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: () => s.setRgb(effect: e),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: on ? ForgeColors.red : ForgeColors.bg2,
                            border: Border.all(color: on ? ForgeColors.red : ForgeColors.line),
                          ),
                          child: Text(e.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: on ? Colors.white : ForgeColors.mut)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  const _SecTitle('COLOR'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _swatches.map((argb) {
                      final on = s.rgbColor == argb;
                      return InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: () => s.setRgb(color: argb),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(argb),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: on ? ForgeColors.gold : ForgeColors.line, width: on ? 3 : 1),
                            boxShadow: on
                                ? [BoxShadow(color: Color(argb).withValues(alpha: 0.5), blurRadius: 12)]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text('BRIGHTNESS', style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: ForgeColors.mut, fontWeight: FontWeight.w700)),
                      Expanded(
                        child: Slider(
                          value: s.brightness,
                          onChanged: (v) => s.setRgb(bright: v),
                          activeColor: ForgeColors.cy,
                        ),
                      ),
                      Text('${(s.brightness * 100).toInt()}%',
                          style: const TextStyle(color: ForgeColors.cy, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: _acCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SecTitle('SYNCED DEVICES'),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _deviceSync.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: _deviceSync[i] ? ForgeColors.gr : ForgeColors.mut),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_devName(i),
                                style: const TextStyle(fontSize: 12, color: ForgeColors.txt)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ]);
  }

  String _devName(int i) {
    const n = ['Motherboard', 'CPU', 'Graphics card', 'Memory', 'Storage', 'Keyboard', 'Mouse', 'Headset', 'Fans'];
    return n[i.clamp(0, n.length - 1)];
  }

  /* ---------------- Performance ---------------- */
  Widget _performanceView(SystemStore s) {
    const modes = [
      ('silent', Icons.bedtime_outlined, 'Silent', 'Low heat & whisper-quiet fans.'),
      ('balanced', Icons.balance, 'Balanced', 'Everyday all-rounder.'),
      ('performance', Icons.bolt, 'Forge', 'Maximum power. Fans spin up.'),
    ];
    return ListView(padding: const EdgeInsets.all(20), children: [
      const _SecTitle('POWER PROFILES'),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: modes.map((m) {
          final on = s.mode == m.$1;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => s.setMode(m.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: on ? ForgeColors.red : ForgeColors.line, width: on ? 2 : 1),
                  color: on ? ForgeColors.red.withValues(alpha: 0.10) : const Color(0xFF131B30),
                  boxShadow: on
                      ? [BoxShadow(color: ForgeColors.red.withValues(alpha: 0.25), blurRadius: 28)]
                      : const [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(m.$2, size: 30, color: on ? ForgeColors.red : ForgeColors.cy),
                    const SizedBox(height: 12),
                    Text(m.$3,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ForgeColors.txt)),
                    const SizedBox(height: 4),
                    Text(m.$4, style: const TextStyle(color: ForgeColors.mut, fontSize: 12)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (on)
                          const Text('ACTIVE',
                              style: TextStyle(
                                  color: ForgeColors.red, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2))
                        else
                          const Text('SWITCH',
                              style: TextStyle(
                                  color: ForgeColors.mut, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const Spacer(),
                        Icon(Icons.arrow_forward_rounded,
                            size: 16, color: on ? ForgeColors.red : ForgeColors.mut),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: _acCard(),
        child: Row(
          children: [
            const Icon(Icons.power_settings_new_rounded, color: ForgeColors.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WINDOWS POWER PLAN',
                      style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: ForgeColors.gold, fontWeight: FontWeight.w700)),
                  Text(s.schemeNote,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ForgeColors.txt, fontSize: 13)),
                ],
              ),
            ),
            TextButton(onPressed: () => s.setMode(s.mode), child: const Text('Re-apply')),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: _acCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.savings_outlined, color: ForgeColors.cy, size: 20),
                SizedBox(width: 10),
                _SecTitle('FORGE PERFORMANCE'),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Profiles switch the real Windows power plan (powercfg) and remember fan curves + RGB per profile. Demo telemetry is used off-Windows.',
              style: TextStyle(color: ForgeColors.mut, fontSize: 12),
            ),
          ],
        ),
      ),
    ]);
  }

  /* ---------------- Fans ---------------- */
  Widget _fansView(SystemStore s) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: _acCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SecTitle('FAN CURVE'),
                  const SizedBox(height: 6),
                  const Text('RPM follows temperature targets 40–100 °C.',
                      style: TextStyle(color: ForgeColors.mut, fontSize: 12)),
                  const SizedBox(height: 10),
                  for (var i = 0; i < 5; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 54,
                            child: Text('${_temps[i]}°C',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: ForgeColors.txt)),
                          ),
                          Expanded(
                            child: Slider(
                              value: s.fanCurve[i].toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 20,
                              activeColor: ForgeColors.cy,
                              onChanged: (v) => setState(() => s.setFan(i, v.toInt())),
                            ),
                          ),
                          SizedBox(
                            width: 46,
                            child: Text('${s.fanCurve[i]}%',
                                textAlign: TextAlign.end,
                                style: const TextStyle(color: ForgeColors.cy, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: _acCard(),
              child: Column(
                children: [
                  const _SecTitle('CHASSIS FANS'),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _fanSpin,
                    builder: (_, _) => CustomPaint(
                      size: const Size(150, 150),
                      painter: _FanPainter(
                        _fanSpin.value,
                        s.fanCurve.last / 100,
                        ForgeColors.cy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Target ${s.fanCurve.last}% @ ${_temps.last}°C',
                      style: const TextStyle(color: ForgeColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Curve stored per profile. Direct fan control applies where the vendor driver is installed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ForgeColors.mut, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    ]);
  }

  /* ---------------- Profiles ---------------- */
  Widget _profilesView(SystemStore s) {
    final name = TextEditingController();
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: _acCard(),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: name,
                decoration: const InputDecoration(
                    labelText: 'Save current setup as a profile…', isDense: true),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ForgeColors.red, foregroundColor: Colors.white),
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                s.saveProfile(name.text.trim());
                name.clear();
                setState(() {});
              },
              child: const Text('Save profile'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      for (final p in s.profiles) _profileTile(s, p),
    ]);
  }

  Widget _profileTile(SystemStore s, ForgeProfile p) {
    final on = s.activeProfile == p.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: on ? ForgeColors.red.withValues(alpha: 0.10) : const Color(0xFF131B30),
        border: Border.all(color: on ? ForgeColors.red : ForgeColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: on ? ForgeColors.red : ForgeColors.bg2,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.manage_accounts_rounded, size: 20, color: on ? ForgeColors.red : ForgeColors.cy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: TextStyle(
                        color: ForgeColors.txt,
                        fontWeight: on ? FontWeight.w800 : FontWeight.w600)),
                Text('${p.mode} · fan ${p.fanCurve.first}–${p.fanCurve.last}% · ${p.rgbEffect}',
                    style: const TextStyle(color: ForgeColors.mut, fontSize: 12)),
              ],
            ),
          ),
          if (!on)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: ForgeColors.cy),
              onPressed: () {
                s.applyProfile(p);
                setState(() {});
              },
              child: const Text('Apply'),
            ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => s.deleteProfile(p.name),
            icon: const Icon(Icons.delete_outline, color: ForgeColors.mut),
          ),
        ],
      ),
    );
  }
}

/* ================= shared pieces ================= */

BoxDecoration _acCard() => BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      color: const Color(0xFF131B30),
      border: Border.all(color: ForgeColors.line),
    );

class _SecTitle extends StatelessWidget {
  final String text;
  const _SecTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 11, letterSpacing: 2, color: ForgeColors.gold, fontWeight: FontWeight.w700));
}

class _Chip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color, bg;
  const _Chip({this.icon, required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onSelect;
  final VoidCallback onAbout;
  const _SideRail({required this.tab, required this.onSelect, required this.onAbout});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      color: const Color(0xFF12141C),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: ForgeColors.goldGradient,
              boxShadow: [
                BoxShadow(color: ForgeColors.gold.withValues(alpha: 0.4), blurRadius: 18),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.diamond, color: Color(0xFF1A1206), size: 24),
          ),
          const SizedBox(height: 6),
          const Text('FORGE',
              style: TextStyle(
                  fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w800, color: ForgeColors.gold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _DashboardScreenState._nav.length,
              itemBuilder: (_, i) {
                final n = _DashboardScreenState._nav[i];
                final on = tab == i;
                return InkWell(
                  onTap: () => onSelect(i),
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: on ? ForgeColors.red.withValues(alpha: 0.14) : null,
                      border: Border(
                        left: BorderSide(
                            color: on ? ForgeColors.red : Colors.transparent, width: 3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(on ? n.activeIcon : n.icon,
                            size: 21, color: on ? ForgeColors.red : ForgeColors.mut),
                        const SizedBox(height: 4),
                        Text(n.label,
                            style: TextStyle(
                                fontSize: 8,
                                letterSpacing: 0.5,
                                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                                color: on ? ForgeColors.red : ForgeColors.mut)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          InkWell(
            onTap: onAbout,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.info_outline, size: 19, color: ForgeColors.mut),
                  SizedBox(height: 3),
                  Text('ABOUT',
                      style: TextStyle(fontSize: 8, letterSpacing: 1, color: ForgeColors.mut)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _Gauge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 100.0);
    return Column(
      children: [
        SizedBox(
          width: 128,
          height: 128,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(128, 128),
                painter: _ArcPainter(value: v, color: color),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(v.toStringAsFixed(0),
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900, color: ForgeColors.txt)),
                  Text('%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: ForgeColors.mut)),
      ],
    );
  }
}

/// Armoury-style 270° arc gauge with gradient sweep.
class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(9);
    final start = math.pi * 0.75;
    final sweep = math.pi * 1.5;
    final track = Paint()
      ..color = ForgeColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, track);
    final grad = SweepGradient(
      startAngle: start,
      endAngle: start + sweep,
      colors: [color.withValues(alpha: 0.2), color],
      transform: const GradientRotation(0),
    ).createShader(rect);
    final arc = Paint()
      ..shader = grad
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep * (value / 100), false, arc);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}

class _FanPainter extends CustomPainter {
  final double t;
  final double speed;
  final Color color;
  _FanPainter(this.t, this.speed, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: 0.8);
    canvas.drawCircle(c, r - 8, ring);
    final spin = t * math.pi * 2 * (0.5 + speed);
    final blade = Paint()..color = color.withValues(alpha: 0.85);
    for (var i = 0; i < 5; i++) {
      final a = spin + i * math.pi * 2 / 5;
      final path = Path();
      final inner = r * 0.16;
      final outer = r * 0.8;
      final b1 = c + Offset(math.cos(a - 0.42), math.sin(a - 0.42)) * inner;
      final b2 = c + Offset(math.cos(a - 0.12), math.sin(a - 0.12)) * outer;
      final b3 = c + Offset(math.cos(a + 0.12), math.sin(a + 0.12)) * outer;
      final b4 = c + Offset(math.cos(a + 0.42), math.sin(a + 0.42)) * inner;
      path.moveTo(b1.dx, b1.dy);
      path.lineTo(b2.dx, b2.dy);
      path.lineTo(b3.dx, b3.dy);
      path.lineTo(b4.dx, b4.dy);
      path.close();
      canvas.drawPath(path, blade);
    }
    canvas.drawCircle(c, r * 0.16 + 2,
        Paint()..color = ForgeColors.gold);
    canvas.drawCircle(c, r * 0.16,
        Paint()..color = ForgeColors.bg);
  }

  @override
  bool shouldRepaint(_FanPainter old) =>
      old.t != t || old.speed != speed || old.color != color;
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  _SparkPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final step = size.width / math.max(1, values.length - 1);
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
    canvas.drawPath(
      path,
      Paint()
        ..color = ForgeColors.cy.withValues(alpha: 0.28)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    final fill = path
      ..lineTo(last.dx, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = ForgeColors.cy.withValues(alpha: 0.05));
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

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131B30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: ForgeColors.line),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: ForgeColors.goldGradient,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.diamond, color: Color(0xFF1A1206), size: 26),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Forge Control',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: ForgeColors.txt)),
                    Text('v1.1 · Open source', style: TextStyle(color: ForgeColors.mut, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Forge Control is open-source software released under the MIT license. '
              'It is free forever — no tiers, no paywalls, no trackers. '
              'Part of the FORGESTUDIO-303 suite, built by Souhail with Muse Spark.',
              style: TextStyle(color: ForgeColors.mut, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 14),
            const Text('Source:', style: TextStyle(color: ForgeColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText('https://$_repo',
                      style: const TextStyle(color: ForgeColors.cy, fontSize: 12)),
                ),
                IconButton(
                  tooltip: 'Copy repo link',
                  onPressed: () => Clipboard.setData(const ClipboardData(text: 'https://$_repo')),
                  icon: const Icon(Icons.copy_rounded, size: 18, color: ForgeColors.mut),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Licensed under MIT · Copyright (c) 2026 FORGESTUDIO-303 (Souhail Bellaghrar)',
                style: TextStyle(color: ForgeColors.mut, fontSize: 11)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ForgeColors.red, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}