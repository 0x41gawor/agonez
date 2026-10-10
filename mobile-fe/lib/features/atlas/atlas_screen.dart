import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../providers.dart';

class AtlasScreen extends ConsumerStatefulWidget {
  const AtlasScreen({super.key});
  @override
  ConsumerState<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends ConsumerState<AtlasScreen> {
  final controller = TextEditingController();
  List<Json> results = [];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() => loading = true);
    try {
      results = await (await ref.read(apiProvider.future)).searchAtlas(q);
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Atlas', style: Theme.of(context).textTheme.headlineLarge),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Badge(
                  label: Text('0'),
                  child: Icon(Icons.tab_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            onSubmitted: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search exercises',
              filled: true,
              fillColor: AgonezColors.panel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Exercises'),
                selected: true,
                onSelected: (_) {},
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Muscles'),
                selected: false,
                onSelected: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const LinearProgressIndicator()
          else
            Expanded(
              child: ListView.separated(
                itemCount: results.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = results[i];
                  final identity = e['exercise'] as Map? ?? e;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 7),
                    title: Text(
                      '${identity['name'] ?? identity['full_name'] ?? 'Exercise'}',
                    ),
                    subtitle: Text(
                      '${e['classification'] ?? e['primary_muscles'] ?? ''}',
                      maxLines: 1,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(e),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
  Future<void> _open(Json item) async {
    final identity = item['exercise'] as Map? ?? item;
    Json? article;
    try {
      article = await (await ref.read(
        apiProvider.future,
      )).atlasArticle('${identity['slug']}');
    } catch (_) {}
    if (!mounted) return;
    final technique = article?['technique'] as Map?;
    final tldr = technique?['tldr'] as Map?;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .92,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '${identity['name'] ?? identity['full_name']}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 18),
            const Text(
              'TECHNIQUE · TL;DR',
              style: TextStyle(
                color: AgonezColors.prescription,
                letterSpacing: 1.3,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            if (article != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Fact('${article['target_category'] ?? '—'}'),
                  _Fact('${article['mechanics_tier'] ?? '—'}'),
                  _Fact('${article['resistance_source'] ?? '—'}'),
                ],
              ),
              const SizedBox(height: 18),
              if (tldr != null)
                for (final entry in tldr.entries) ...[
                  Text(
                    '${entry.key}'.toUpperCase(),
                    style: const TextStyle(
                      color: AgonezColors.prescription,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${entry.value}'),
                  const SizedBox(height: 12),
                ]
              else
                Text('${technique?['overview'] ?? ''}'),
            ] else
              const Text('This article is available when online.'),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'MUSCLE MAP',
              style: TextStyle(letterSpacing: 1.3, fontSize: 11),
            ),
            const SizedBox(height: 8),
            const Text(
              'The canonical anatomy map is bundled for offline highlighting.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AgonezColors.raised,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AgonezColors.line),
    ),
    child: Text(
      text.replaceAll('_', ' '),
      style: const TextStyle(fontSize: 12),
    ),
  );
}
