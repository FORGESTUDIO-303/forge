import 'package:flutter/material.dart';
import '../models/game.dart';
import '../store/library_store.dart';

const _accents = [
  Colors.cyan,
  Colors.purple,
  Colors.pink,
  Colors.teal,
  Colors.orange,
  Colors.indigo,
  Colors.green,
  Colors.amber,
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
        list.sort((a, b) => a.title.compareTo(b.title));
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
        title: const Text('◈ OmniLauncher'),
        actions: [
          IconButton(
            tooltip: favOnly ? 'Show all' : 'Favorites only',
            icon: Icon(favOnly ? Icons.star : Icons.star_border),
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
              PopupMenuItem(value: 'az', child: Text('A – Z')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search your library…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          SizedBox(
            height: 44,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text('${store.games.length} games',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 12),
                Text('▶ ${mins ~/ 60}h ${mins % 60}m played',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 12),
                Text('★ ${store.favorites}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Text('Nothing here — add your first game with +'))
                : grid
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: visible.length,
                        itemBuilder: (_, i) => _card(visible[i]),
                      )
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (_, i) => _tile(visible[i]),
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
              height: 86,
              color: a.withValues(alpha: 0.25),
              alignment: Alignment.center,
              child: Text(
                g.title.isEmpty
                    ? '?'
                    : g.title.trim()[0].toUpperCase(),
                style: TextStyle(
                    fontSize: 44, fontWeight: FontWeight.w800, color: a),
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
                                fontWeight: FontWeight.bold))),
                    InkWell(
                      onTap: () => widget.store.toggleFavorite(g.id),
                      child: Icon(
                          g.favorite ? Icons.star : Icons.star_border,
                          size: 20,
                          color: g.favorite ? Colors.amber : null),
                    ),
                  ]),
                  Text('${g.platform} • ${g.playtimeLabel}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Row(children: [
                    IconButton(
                        tooltip: 'Play',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _play(g),
                        icon: const Icon(Icons.play_arrow)),
                    const SizedBox(width: 8),
                    IconButton(
                        tooltip: '+15 min',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            widget.store.addPlaytime(g.id, 15),
                        icon: const Icon(Icons.timer)),
                    const Spacer(),
                    IconButton(
                        tooltip: 'Edit',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _editDialog(g),
                        icon: const Icon(Icons.edit)),
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
    return ListTile(
      leading: CircleAvatar(
          backgroundColor: a.withValues(alpha: 0.25),
          child: Text(
              g.title.isEmpty ? '?' : g.title.trim()[0].toUpperCase(),
              style: TextStyle(color: a, fontWeight: FontWeight.bold))),
      title: Text(g.title),
      subtitle: Text('${g.platform} • ${g.category} • ${g.playtimeLabel}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
            tooltip: 'Favorite',
            onPressed: () => widget.store.toggleFavorite(g.id),
            icon: Icon(g.favorite ? Icons.star : Icons.star_border,
                color: g.favorite ? Colors.amber : null)),
        IconButton(
            tooltip: 'Play',
            onPressed: () => _play(g),
            icon: const Icon(Icons.play_arrow)),
        IconButton(
            tooltip: 'Edit',
            onPressed: () => _editDialog(g),
            icon: const Icon(Icons.edit)),
      ]),
      onTap: () => _play(g),
    );
  }

  Future<void> _play(Game g) async {
    final msg = await widget.store.play(g);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete(Game g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove game?'),
        content: Text('"${g.title}" leaves your library (files untouched).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) widget.store.remove(g.id);
  }

  Future<void> _editDialog(Game? g) async {
    final title = TextEditingController(text: g?.title ?? '');
    final exec = TextEditingController(text: g?.execPath ?? '');
    String plat = g?.platform ?? 'PC';
    String cat = g?.category ?? 'Other';
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
                  decoration:
                      const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: plat,
                decoration: const InputDecoration(labelText: 'Platform'),
                items: kPlatforms
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setD(() => plat = v ?? plat),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: cats.contains(cat) ? cat : 'Other',
                decoration: const InputDecoration(labelText: 'Category'),
                items: cats
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setD(() => cat = v ?? cat),
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: exec,
                  decoration: const InputDecoration(
                      labelText: 'Executable path (desktop launch)',
                      hintText: r'C:\Games\game.exe')),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
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
      ));
    } else {
      g.title = title.text.trim();
      g.platform = plat;
      g.category = cat;
      g.execPath = exec.text.trim();
      await widget.store.update(g);
    }
  }
}
