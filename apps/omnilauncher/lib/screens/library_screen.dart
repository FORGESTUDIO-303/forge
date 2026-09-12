import 'package:flutter/material.dart';
import '../models/game.dart';
import '../store/library_store.dart';
import '../theme.dart';

const _accents = [
  ForgeColors.cy,
  ForgeColors.vi,
  ForgeColors.mg,
  ForgeColors.gr,
  ForgeColors.gold,
  ForgeColors.cy,
];

class LibraryScreen extends StatefulWidget {
  final LibraryStore store;
  const LibraryScreen({super.key, required this.store});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String query = '';
  String platform = 'All';
  bool favOnly = false;
  bool grid = true;
  String sort = 'recent';

  List<Game> get visible {
    var list = widget.store.games.where((g) {
      if (favOnly && !g.favorite) return false;
      if (platform != 'All' && g.platform != platform) return false;
      if (query.isNotEmpty &&
          !g.title.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
    switch (sort) {
      case 'played':
        list.sort((a, b) => b.playtimeMinutes.compareTo(a.playtimeMinutes));
        break;
      case 'az':
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'rated':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        list.sort((a, b) => (b.lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0)));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final mins = store.totalMinutes;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Text('◈ ', style: TextStyle(color: ForgeColors.cy)),
            Text('OmniLauncher'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: favOnly ? 'Show all' : 'Favorites only',
            icon: Icon(favOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => favOnly = !favOnly),
          ),
          IconButton(
            tooltip: grid ? 'List view' : 'Grid view',
            icon: Icon(grid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => grid = !grid),
          ),
          PopupMenuButton<String>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'recent', child: Text('Recently played')),
              PopupMenuItem(value: 'played', child: Text('Most played')),
              PopupMenuItem(value: 'rated', child: Text('Top rated')),
              PopupMenuItem(value: 'az', child: Text('A – Z')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _heroStrip(store, mins),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search your library…',
                isDense: true,
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['All', ...kPlatforms].map((p) {
                final on = platform == p;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: on,
                    onSelected: (_) => setState(() => platform = p),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('Nothing here — add your first game with +'))
                : grid
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: visible.length,
                        itemBuilder: (_, i) => _Entrance(
                          index: i,
                          key: ObjectKey(visible[i].id),
                          child: _card(visible[i]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (_, i) => _Entrance(
                          index: i,
                          key: ObjectKey(visible[i].id),
                          child: _tile(visible[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(null),
        icon: const Icon(Icons.add),
        label: const Text('Add game'),
      ),
    );
  }

  Widget _heroStrip(LibraryStore store, int mins) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ForgeColors.card, ForgeColors.bg2],
        ),
        border: Border.all(color: ForgeColors.line),
        boxShadow: [
          BoxShadow(color: ForgeColors.cy.withValues(alpha: 0.10), blurRadius: 28),
        ],
      ),
      child: Row(
        children: [
          _stat('${store.games.length}', 'GAMES'),
          _statDivider(),
          _stat('${mins ~/ 60}h ${mins % 60}m', 'PLAYED'),
          _statDivider(),
          _stat('${store.favorites}', 'FAVORITES'),
          const Spacer(),
          const Icon(Icons.diamond_outlined, color: ForgeColors.gold, size: 22),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ForgeColors.txt)),
        Text(label,
            style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: ForgeColors.mut)),
      ],
    );
  }

  Widget _statDivider() =>
      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SizedBox(
        height: 30,
        child: VerticalDivider(color: ForgeColors.line, thickness: 1),
      ));

  Color _accent(Game g) => _accents[g.colorSeed % _accents.length];

  Widget _card(Game g) {
    final a = _accent(g);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _play(g),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [a.withValues(alpha: 0.30), a.withValues(alpha: 0.06)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                g.title.isEmpty ? '?' : g.title.trim()[0].toUpperCase(),
                style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: a,
                    shadows: [Shadow(color: a.withValues(alpha: 0.6), blurRadius: 24)]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(g.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: ForgeColors.txt))),
                    InkWell(
                      onTap: () => widget.store.toggleFavorite(g.id),
                      child: Icon(g.favorite ? Icons.star : Icons.star_border,
                          size: 20,
                          color: g.favorite ? ForgeColors.gold : ForgeColors.mut),
                    ),
                  ]),
                  if (g.rating > 0)
                    Text(g.stars,
                        style: const TextStyle(
                            color: ForgeColors.gold,
                            fontSize: 13,
                            letterSpacing: 1.5)),
                  Text('${g.platform} • ${g.playtimeLabel}',
                      style: const TextStyle(color: ForgeColors.mut, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    IconButton(
                        tooltip: 'Play',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _play(g),
                        icon: Icon(Icons.play_arrow, color: ForgeColors.cy)),
                    const SizedBox(width: 8),
                    IconButton(
                        tooltip: '+15 min',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => widget.store.addPlaytime(g.id, 15),
                        icon: const Icon(Icons.timer, color: ForgeColors.mut)),
                    if (g.notes.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.sticky_note_2_outlined,
                            size: 15, color: ForgeColors.mut),
                      ),
                    const Spacer(),
                    IconButton(
                        tooltip: 'Edit',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _editDialog(g),
                        icon: const Icon(Icons.edit_outlined)),
                    IconButton(
                        tooltip: 'Delete',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmDelete(g),
                        icon: const Icon(Icons.delete_outline)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Game g) {
    final a = _accent(g);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
            backgroundColor: a.withValues(alpha: 0.22),
            child: Text(
                g.title.isEmpty ? '?' : g.title.trim()[0].toUpperCase(),
                style: TextStyle(color: a, fontWeight: FontWeight.bold))),
        title: Text(g.title, style: const TextStyle(color: ForgeColors.txt)),
        subtitle: Text(
          '${g.platform} • ${g.category} • ${g.playtimeLabel}'
          '${g.rating > 0 ? '  ${g.stars}' : ''}',
          style: const TextStyle(color: ForgeColors.mut),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              tooltip: 'Favorite',
              onPressed: () => widget.store.toggleFavorite(g.id),
              icon: Icon(g.favorite ? Icons.star : Icons.star_border,
                  color: g.favorite ? ForgeColors.gold : ForgeColors.mut)),
          IconButton(
              tooltip: 'Play',
              onPressed: () => _play(g),
              icon: Icon(Icons.play_arrow, color: ForgeColors.cy)),
          IconButton(
              tooltip: 'Edit',
              onPressed: () => _editDialog(g),
              icon: const Icon(Icons.edit_outlined)),
        ]),
        onTap: () => _play(g),
      ),
    );
  }

  Future<void> _play(Game g) async {
    final msg = await widget.store.play(g);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete(Game g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove game?'),
        content: Text('"${g.title}" leaves your library (files untouched).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) widget.store.remove(g.id);
  }

  Future<void> _editDialog(Game? g) async {
    final title = TextEditingController(text: g?.title ?? '');
    final exec = TextEditingController(text: g?.execPath ?? '');
    final notes = TextEditingController(text: g?.notes ?? '');
    String plat = g?.platform ?? 'PC';
    String cat = g?.category ?? 'Other';
    int rating = g?.rating ?? 0;
    const cats = [
      'Action', 'Roguelike', 'Card Game', 'Idle', 'RPG',
      'Strategy', 'Sports', 'Puzzle', 'Other'
    ];
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(g == null ? 'Add game' : 'Edit game'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: plat,
                decoration: const InputDecoration(labelText: 'Platform'),
                items:
                    kPlatforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setD(() => plat = v ?? plat),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: cats.contains(cat) ? cat : 'Other',
                decoration: const InputDecoration(labelText: 'Category'),
                items:
                    cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setD(() => cat = v ?? cat),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Rating', style: TextStyle(color: ForgeColors.mut)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: rating.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: rating <= 0 ? 'Unrated' : '${'★' * rating}',
                    onChanged: (v) => setD(() => rating = v.toInt()),
                  ),
                ),
                const SizedBox(width: 8),
                Text(rating <= 0 ? '—' : '★' * rating, style: const TextStyle(color: ForgeColors.gold)),
              ]),
              const SizedBox(height: 8),
              TextField(
                  controller: notes,
                  maxLines: 3,
                  maxLength: 300,
                  decoration:
                      const InputDecoration(labelText: 'Notes (optional)')),
              const SizedBox(height: 8),
              TextField(
                  controller: exec,
                  decoration: const InputDecoration(
                      labelText: 'Executable path (desktop launch)',
                      hintText: r'C:\Games\game.exe')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true || title.text.trim().isEmpty) return;
    if (g == null) {
      await widget.store.add(Game(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.text.trim(),
        platform: plat,
        category: cat,
        execPath: exec.text.trim(),
        colorSeed: DateTime.now().millisecond,
        rating: rating,
        notes: notes.text.trim(),
      ));
    } else {
      g.title = title.text.trim();
      g.platform = plat;
      g.category = cat;
      g.execPath = exec.text.trim();
      g.rating = rating;
      g.notes = notes.text.trim();
      await widget.store.update(g);
    }
  }
}

/// Staggered slide+reveal that runs once per widget (keyed by game id).
class _Entrance extends StatefulWidget {
  final int index;
  final Widget child;
  const _Entrance({super.key, required this.index, required this.child});

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _up;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _up = Tween(begin: 16.0, end: 0.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 55), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(offset: Offset(0, _up.value), child: child),
      ),
    );
  }
}