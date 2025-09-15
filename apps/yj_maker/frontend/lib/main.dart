import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const YojijukugoApp());

class YojijukugoApp extends StatelessWidget {
  const YojijukugoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '適当四字熟語メーカー',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const YjHome(),
    );
  }
}

class YjHome extends StatefulWidget {
  const YjHome({super.key});
  @override
  State<YjHome> createState() => _YjHomeState();
}

class _YjHomeState extends State<YjHome> {
  final rnd = Random();
  late String yj;
  late String meaning;

  static const _kanji1 = [
    '屁', '泡', '鍋', '腐', '鼻', '汁', '米', '芋', '泥', '痔'
  ];
  static const _kanji2 = [
    '爆', '狂', '怪', '臭', '飯', '屁', '酒', '蛙', '汁', '鼻'
  ];
  static const _kanji3 = [
    '拳', '餅', '骨', '菌', '便', '卵', '虫', '糞', '蛸', '酢'
  ];
  static const _kanji4 = [
    '丸', '帝', '殿', '様', '郎', '拳', '族', '臭', '界', '沼'
  ];

  static const _templates = [
    '意味はない。とにかくカッコつけたいだけ。',
    '言ったらだいたい滑る。でも気にするな。',
    '口にするとIQが1下がる。',
    'ラーメンのトッピングっぽい名前。',
    'トイレの落書きに書かれてそう。',
    '考えた本人も意味を理解していない。',
    'ポケモンの新技っぽい。威力は2。',
    '読んだ瞬間に脳がバグる。',
    '黒歴史ノートに必ず書いてあるやつ。',
    '学校のテストに出たらみんな白紙回答。',
    'ゴリラが叫んでそう。',
    '居酒屋で注文したら店員が困惑する。',
    'クソゲーの裏技コマンド名。',
    '3回唱えると腹筋が割れる（気がする）。',
    '漢字っぽいけどただの音の並び。',
    '言うと友達が減る呪文。',
    'おばあちゃんが適当に作った故事成語。',
    '誰かがカッコイイと思ってノリで登録した四字熟語。',
    'ランダム漢字ガチャで出てきた産物。',
    '脳内会議で採択された謎の言葉。',
    '酔っ払いがドヤ顔で言い出すパワーワード。',
    '笑いながら使うとちょっとだけモテる。',
    'ただの漢字ジャムセッション。',
    'カラオケの合いの手に最適。',
    'ドンキのポップに書いてありそう。',
    '叫ぶと運動会で優勝できる（かも）。',
    'お菓子の新商品っぽい。',
    '何かすごそうに聞こえるけどただの幻。',
    '書き初めで先生に真顔で褒められるやつ。',
    'AIが寝ぼけて吐き出した文字列。',
  ];

  void _generate() {
    yj = _kanji1[rnd.nextInt(_kanji1.length)] +
        _kanji2[rnd.nextInt(_kanji2.length)] +
        _kanji3[rnd.nextInt(_kanji3.length)] +
        _kanji4[rnd.nextInt(_kanji4.length)];
    meaning = _templates[rnd.nextInt(_templates.length)];
  }

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('適当四字熟語メーカー')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(yj,
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(meaning, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('新しい熟語をつくる'),
                onPressed: () => setState(_generate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
