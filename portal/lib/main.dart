import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const ForestPortalApp());

/// ウェブアプリの森（ポータル）
class ForestPortalApp extends StatelessWidget {
  const ForestPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2E7D32);   // 濃い緑
    const secondary = Color(0xFF66BB6A); // 明るい緑
    const surface = Color(0xFFF3F8F4);   // ほんのり緑がかった白

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: Colors.white,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'ウェブアプリの森',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansJpTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.all(12),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const PortalHome(),
    );
  }
}

class PortalHome extends StatefulWidget {
  const PortalHome({super.key});
  @override
  State<PortalHome> createState() => _PortalHomeState();
}

class _PortalHomeState extends State<PortalHome> {
  late Future<List<AppEntry>> _future = _loadApps();
  String _keyword = '';
  Set<String> _selectedTags = {};

Future<List<AppEntry>> _loadApps() async {
  // 同一オリジンの /assets/apps.json を取得（キャッシュ無効化用にクエリ付与）
  final uri = Uri.parse('/assets/apps.json?t=${DateTime.now().millisecondsSinceEpoch}');
  try {
    final res = await http.get(uri, headers: {'Cache-Control': 'no-cache'});
    if (res.statusCode == 200) {
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => AppEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      throw Exception('HTTP ${res.statusCode}');
    }
  } catch (e) {
    // フォールバック（ローカル開発や離線時用にバンドルの apps.json を参照）
    final raw = await rootBundle.loadString('assets/apps.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => AppEntry.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<AppEntry>>(
        future: _future,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return Center(child: Text('読み込みエラー: ${s.error}'));
          }
          final apps = s.data ?? [];

          // タグ一覧
          final allTags = <String>{};
          for (final a in apps) {
            allTags.addAll(a.tags);
          }

          // フィルタ
          final filtered = apps.where((a) {
            final kw = _keyword.trim().toLowerCase();
            final okKeyword = kw.isEmpty ||
                a.title.toLowerCase().contains(kw) ||
                a.description.toLowerCase().contains(kw);
            final okTag =
                _selectedTags.isEmpty || a.tags.any(_selectedTags.contains);
            return okKeyword && okTag;
          }).toList();

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: ForestHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: '検索（タイトル / 説明）',
                          ),
                          onChanged: (v) =>
                              setState(() => _keyword = v.trim()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: 'apps.json を再読込',
                        child: FilledButton.icon(
                          onPressed: () =>
                              setState(() => _future = _loadApps()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('更新'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (allTags.isNotEmpty)
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: allTags.map((t) {
                        final sel = _selectedTags.contains(t);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(t),
                            selected: sel,
                            onSelected: (_) => setState(() {
                              if (sel) {
                                _selectedTags.remove(t);
                              } else {
                                _selectedTags.add(t);
                              }
                            }),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('該当なし')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverLayoutBuilder(builder: (context, cons) {
                    final w = cons.crossAxisExtent; // sliver版の幅
                    final col =
                        w >= 1200 ? 5 : w >= 992 ? 4 : w >= 768 ? 3 : w >= 520 ? 2 : 1;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: col,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => AppCard(entry: filtered[i]),
                        childCount: filtered.length,
                      ),
                    );
                  }),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

/// 森っぽいヘッダー（グラデ＋木漏れ日のボケ）
class ForestHeader extends StatelessWidget {
  const ForestHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景：森グラデーション
        Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF388E3C), Color(0xFF81C784)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // 木漏れ日っぽいボケ
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BokehPainter()))),
        // タイトル
        SizedBox(
          height: 200,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  // ロゴ代替（絵文字）
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🌲', style: TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'ウェブアプリの森',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'みんなのアイデアがアプリとして芽生える',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 下端の丸み
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _BokehPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blobs = <_Blob>[
      _Blob(0.18, 0.28, 80, 0.10),
      _Blob(0.55, 0.18, 60, 0.12),
      _Blob(0.80, 0.42, 90, 0.08),
      _Blob(0.32, 0.66, 70, 0.10),
      _Blob(0.70, 0.72, 50, 0.08),
    ];
    for (final b in blobs) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(b.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      final offset = Offset(size.width * b.x, size.height * b.y);
      canvas.drawCircle(offset, b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Blob {
  final double x, y, radius, opacity;
  _Blob(this.x, this.y, this.radius, this.opacity);
}

/// アプリ項目
class AppEntry {
  final String id, title, description, thumbnail, link;
  final List<String> tags;
  AppEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.link,
    this.tags = const [],
  });

  factory AppEntry.fromJson(Map<String, dynamic> j) => AppEntry(
        id: j['id'] as String,
        title: j['title'] as String,
        description: (j['description'] ?? '') as String,
        thumbnail: j['thumbnail'] as String,
        link: j['link'] as String,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
      );
}

/// 1カード
class AppCard extends StatelessWidget {
  final AppEntry entry;
  const AppCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final descStyle = Theme.of(context).textTheme.bodySmall;

    return Card(
      child: InkWell(
        onTap: () async {
          // 相対リンクにも対応（/apps/... など）
          final uri = _resolve(entry.link);
          await launchUrl(uri, webOnlyWindowName: '_self');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // サムネ
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(
                  '${entry.thumbnail}?t=${DateTime.now().millisecondsSinceEpoch}',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.apps, size: 48)),
                )
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                entry.title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                entry.description,
                style: descStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `<base href>` を尊重して相対/絶対どちらも安全に解決
  Uri _resolve(String href) {
    final u = Uri.tryParse(href);
    if (u == null) return Uri.base;
    return u.hasScheme ? u : Uri.base.resolve(href);
  }
}
