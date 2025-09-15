import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const FactorSprintApp());

class FactorSprintApp extends StatelessWidget {
  const FactorSprintApp({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '10秒素因数分解',
      theme: ThemeData(useMaterial3: true, colorScheme: scheme),
      home: const LevelSelectScreen(),
    );
  }
}

enum Grade { beginner, intermediate, advanced, expert }

extension GradeInfo on Grade {
  String get label => switch (this) {
        Grade.beginner => '初級',
        Grade.intermediate => '中級',
        Grade.advanced => '上級',
        Grade.expert => '超級',
      };

  List<int> get primes => switch (this) {
        Grade.beginner => [2, 3, 5],
        Grade.intermediate => [2, 3, 5, 7, 11, 13],
        Grade.advanced => [2, 3, 5, 7, 11, 13, 17, 19],
        Grade.expert => [2, 3, 5, 7, 11, 13, 17, 19, 23, 29],
      };

  int get cap => switch (this) {
        Grade.beginner => 1000,
        Grade.intermediate => 10000,
        Grade.advanced => 100000,
        Grade.expert => 1000000,
      };

  Color get color => switch (this) {
        Grade.beginner => Colors.green,
        Grade.intermediate => Colors.blue,
        Grade.advanced => Colors.orange,
        Grade.expert => Colors.purple,
      };
}

/// ---- ホーム（レベル選択） ----
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});
  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final Map<Grade, int> best = {
    Grade.beginner: 0,
    Grade.intermediate: 0,
    Grade.advanced: 0,
    Grade.expert: 0,
  };

  Future<void> _open(Grade g) async {
    final result = await Navigator.push<_GameResult>(
      context,
      MaterialPageRoute(builder: (_) => GamePage(grade: g, bestSoFar: best[g]!)),
    );
    if (result != null && result.bestUpdated > best[g]!) {
      setState(() => best[g] = result.bestUpdated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileText = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(title: const Text('10秒素因数分解')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('あそびかた', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('10秒以内に出題された数を素因数分解！素数ボタンを押した回数が指数になります。'
                        '取り消し「×」、クリア、確定ボタンあり。連続正解を伸ばそう！'),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: Grade.values.map((g) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: g.color, child: Text(g.label.substring(0,1))),
                        title: Text('${g.label}（素因数: ${g.primes.join(', ')}）', style: tileText),
                        subtitle: Text('出題範囲: ${g.cap}未満   ベスト: ${best[g]} 連続'),
                        trailing: FilledButton(
                          onPressed: () => _open(g),
                          child: const Text('スタート'),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// ---- ゲーム画面 ----
class GamePage extends StatefulWidget {
  final Grade grade;
  final int bestSoFar;
  const GamePage({super.key, required this.grade, required this.bestSoFar});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int prod = 1;
  final rnd = Random();
  late int target;
  Map<int, int> answer = {};
  List<int> pressHistory = [];
  int streak = 0;
  late int best;

  static const totalMs = 10000;
  static const tickMs = 100;
  Timer? timer;
  int remainMs = totalMs;
  String _pressedSequence() {
    if (pressHistory.isEmpty) return '（未入力）';
    return pressHistory.map((e) => e.toString()).join(' × ');
  }
  @override
  void initState() {
    super.initState();
    best = widget.bestSoFar;
    _startNewRound(resetStreak: true);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startNewRound({bool resetStreak = false}) {
    timer?.cancel();
    answer = {};
    pressHistory = [];
    if (resetStreak) streak = 0;
    target = _makeNumber(widget.grade.primes, widget.grade.cap);
    remainMs = totalMs;
    timer = Timer.periodic(const Duration(milliseconds: tickMs), (t) {
      if (!mounted) return;
      setState(() {
        remainMs -= tickMs;
        if (remainMs <= 0) {
          remainMs = 0;
          timer?.cancel();
          _onFail(reason: '時間切れ');
        }
      });
    });
    setState(() {});
  }

  int _makeNumber(List<int> primes, int cap) {
    while (true) {
      int n = 1;
      n *= primes[rnd.nextInt(primes.length)]; // 最低1因子
      for (final p in primes) {
        final maxTry = 1 + rnd.nextInt(5);
        for (int i = 0; i < maxTry; i++) {
          if (n * p > cap) break;
          if (rnd.nextBool()) n *= p;
        }
      }
      if (n > 1 && n < cap) return n;
    }
  }

  int _productOfAnswer() {
    int prod = 1;
    answer.forEach((p, e) {
      for (int i = 0; i < e; i++) {
        prod *= p;
      }
    });
    return prod;
  }

  void _pressPrime(int p) {
    setState(() {
      answer[p] = (answer[p] ?? 0) + 1;
      prod *= p;
      pressHistory.add(p);   // 👈 履歴に追加
    });
  }

  void _undo() {
    setState(() {
      if (pressHistory.isNotEmpty) {
        final last = pressHistory.removeLast();
        answer[last] = (answer[last] ?? 1) - 1;
        if (answer[last]! <= 0) answer.remove(last);
        prod ~/= last;
      }
    });
  }

  void _clearInput() {
    setState(() {
      answer.clear();
      prod = 1;
      pressHistory.clear();   // 👈 履歴もリセット
    });
  }

  void _submit() {
    timer?.cancel();
    final prod = _productOfAnswer();
    if (prod == target) {
      streak += 1;
      best = max(best, streak);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('正解！ 連続${streak}回'), duration: const Duration(milliseconds: 700)),
      );
      _startNewRound(resetStreak: false);
    } else {
      _onFail(reason: '不正解（あなたの答え: $prod）');
    }
  }

  Future<void> _onFail({required String reason}) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('${widget.grade.label} リザルト'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ターゲット: $target'),
            const SizedBox(height: 8),
            Text('あなたの連続正解: $streak 回'),
            Text('ベスト: $best 回'),
            const SizedBox(height: 8),
            Text(reason),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('レベル選択に戻る'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('もう一度'),
          ),
        ],
      ),
    );

    if (res == true) {
      _startNewRound(resetStreak: true);
    } else {
      // ホームへ戻る（ベストを返す）
      if (context.mounted) {
        Navigator.pop(context, _GameResult(bestUpdated: best));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = remainMs / totalMs;
    final prod = _productOfAnswer();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.grade.label} / 10秒素因数分解'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _GameResult(bestUpdated: best)),
        ),
        actions: [
          IconButton(onPressed: () => _startNewRound(resetStreak: true), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // カウントダウンバー
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('残り ${max(0, (remainMs / 1000)).toStringAsFixed(1)} 秒'),
                      Text('連続正解: $streak / ベスト: $best'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 問題
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const SizedBox(height: 8),
                    Text(
                      '$target',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                  ]),
                ),
              ),

              const SizedBox(height: 8),
              // 積と履歴
              Card(
                color: Colors.indigo.shade50,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      _pressedSequence(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              // 入力と操作
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      // 素数ボタン（可変グリッド）
                      LayoutBuilder(
                        builder: (context, cons) {
                          // 端末幅に応じて1タイルの最大幅を決定（広いほど列数が増える）
                          // 例: スマホ ~120px/個, タブレット ~140px/個, デスクトップ ~160px/個
                          double maxExtent = 120;
                          if (cons.maxWidth >= 480) maxExtent = 130;
                          if (cons.maxWidth >= 720) maxExtent = 140;
                          if (cons.maxWidth >= 960) maxExtent = 160;

                          return GridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: maxExtent,     // 列数は自動計算
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.2,             // ほぼ正方形
                            ),
                            children: [
                              for (final p in widget.grade.primes)
                                _CalcKey(
                                  labelTop: '$p',
                                  labelBottom: '^${(answer[p] ?? 0)}',
                                  onTap: () => _pressPrime(p),
                                ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // 操作ボタン（大きく・固定3分割）
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              onPressed: _undo,
                              icon: const Icon(Icons.undo),
                              label: const Text('× 取り消し'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade100,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _clearInput,
                              child: const Text('クリア'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _submit,
                              icon: const Icon(Icons.check),
                              label: const Text('確定'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GameResult {
  final int bestUpdated;
  _GameResult({required this.bestUpdated});
}

class _CalcKey extends StatelessWidget {
  final String labelTop;
  final String labelBottom;
  final VoidCallback onTap;
  const _CalcKey({
    required this.labelTop,
    required this.labelBottom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.08),
          border: Border.all(color: cs.primary.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(labelTop, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(labelBottom, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
