import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MazeApp());

class MazeApp extends StatelessWidget {
  const MazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'インスタント迷路',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: const MazePage(),
    );
  }
}

class MazePage extends StatefulWidget {
  const MazePage({super.key});

  @override
  State<MazePage> createState() => _MazePageState();
}

class _MazePageState extends State<MazePage> {
  static const int size = 10;        // 表示は10x10のまま
  late List<List<int>> maze;         // 0=道, 1=壁
  Point<int> player = const Point(0, 0);
  late Point<int> goal;
  bool cleared = false;

  @override
  void initState() {
    super.initState();
    _generateMaze();
    RawKeyboard.instance.addListener(_handleKey);
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKey);
    super.dispose();
  }

  void _generateMaze() {
    // すべて壁で初期化
    maze = List.generate(size, (_) => List.generate(size, (_) => 1));

    // 深さ優先で“2マス飛ばし”に掘る（偶数座標が道になる）
    void carve(int x, int y) {
      maze[y][x] = 0;
      final dirs = <Point<int>>[
        const Point(1, 0),
        const Point(-1, 0),
        const Point(0, 1),
        const Point(0, -1),
      ]..shuffle();
      for (final d in dirs) {
        final nx = x + d.x * 2;
        final ny = y + d.y * 2;
        if (nx >= 0 && ny >= 0 && nx < size && ny < size && maze[ny][nx] == 1) {
          maze[y + d.y][x + d.x] = 0; // 間の壁も開通
          carve(nx, ny);
        }
      }
    }

    carve(0, 0);

    // 念のためスタート開通
    maze[0][0] = 0;

    // BFSで(0,0)から到達可能な中で最遠のセルをゴールにする
    goal = _farthestReachable();

    player = const Point(0, 0);
    cleared = false;
  }

  Point<int> _farthestReachable() {
    final q = <Point<int>>[];
    final dist = List.generate(size, (_) => List.filled(size, -1));
    q.add(const Point(0, 0));
    dist[0][0] = 0;
    int head = 0;
    final dirs = [const Point(1,0), const Point(-1,0), const Point(0,1), const Point(0,-1)];
    while (head < q.length) {
      final p = q[head++];
      for (final d in dirs) {
        final nx = p.x + d.x, ny = p.y + d.y;
        if (nx>=0 && ny>=0 && nx<size && ny<size && maze[ny][nx]==0 && dist[ny][nx]==-1) {
          dist[ny][nx] = dist[p.y][p.x] + 1;
          q.add(Point(nx, ny));
        }
      }
    }
    // 最遠のセル（距離最大）を選ぶ。到達不能ケースは念のため(0,0)
    Point<int> best = const Point(0, 0);
    int bestD = 0;
    for (int y=0; y<size; y++) {
      for (int x=0; x<size; x++) {
        if (dist[y][x] > bestD) {
          bestD = dist[y][x];
          best = Point(x, y);
        }
      }
    }
    // ゴールも開通させておく（保険）
    maze[best.y][best.x] = 0;
    return best;
  }

  void _handleKey(RawKeyEvent e) {
    if (e is! RawKeyDownEvent) return;
    Point<int> next = player;
    if (e.logicalKey == LogicalKeyboardKey.arrowUp)    next = Point(player.x, player.y - 1);
    if (e.logicalKey == LogicalKeyboardKey.arrowDown)  next = Point(player.x, player.y + 1);
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft)  next = Point(player.x - 1, player.y);
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) next = Point(player.x + 1, player.y);
    if (_canMove(next)) {
      setState(() {
        player = next;
        if (player == goal) cleared = true;
      });
    }
  }

  bool _canMove(Point<int> p) =>
      p.x >= 0 && p.y >= 0 && p.x < size && p.y < size && maze[p.y][p.x] == 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('インスタント迷路'),
        actions: [
          IconButton(
              onPressed: () {
                setState(() => _generateMaze());
              },
              icon: const Icon(Icons.refresh))
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cleared)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('🎉 クリア！ 🎉',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            SizedBox(
              width: 400,
              height: 400,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size,
                ),
                itemCount: size * size,
                itemBuilder: (_, i) {
                  final x = i % size;
                  final y = i ~/ size;
                  Color color;
                  if (player == Point(x, y)) {
                    color = Colors.blue; // プレイヤー
                  } else if (goal == Point(x, y)) {
                    color = Colors.red; // ゴール
                  } else if (maze[y][x] == 1) {
                    color = Colors.black; // 壁
                  } else {
                    color = Colors.white; // 道
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text('矢印キーで移動。赤に着いたらクリア！'),
          ],
        ),
      ),
    );
  }
}
