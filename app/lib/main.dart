import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'history_detail_page.dart';
import 'model/octane_log.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(OctaneLogAdapter());
  await Hive.openBox<OctaneLog>('octane_logs');

  runApp(const OctaneApp());
}

class OctaneApp extends StatelessWidget {
  const OctaneApp({super.key});

  // ✅ “분홍분홍” 줄이고, 자동차/계기판 느낌(뉴트럴+버건디 포인트)
  static const Color _brand = Color(0xFF7A2E2E); // 버건디/다크레드
  static const Color _bg = Color(0xFFF6F3F1); // 아주 연한 웜 그레이

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: _brand,
      scaffoldBackgroundColor: _bg,
    );

    return MaterialApp(
      title: '고급유 노트',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
          tabBarTheme: const TabBarThemeData(
            labelColor: Color(0xFF7A2E2E),
            unselectedLabelColor: Colors.black87,
            indicatorColor: Color(0xFF7A2E2E),
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
          ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: _brand,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

      ),
      home: const OctaneHomePage(),
    );
  }
}

class OctaneHomePage extends StatefulWidget {
  const OctaneHomePage({super.key});

  @override
  State<OctaneHomePage> createState() => _OctaneHomePageState();
}

class _OctaneHomePageState extends State<OctaneHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ===== 입력 컨트롤러 =====
  final TextEditingController highFuelCtrl = TextEditingController();
  final TextEditingController regFuelCtrl = TextEditingController();

  final TextEditingController beforeLiterCtrl = TextEditingController();
  final TextEditingController beforeOctaneCtrl = TextEditingController();
  final TextEditingController addLiterCtrl = TextEditingController();
  final TextEditingController addOctaneCtrl = TextEditingController();

  double? _avgResult;
  String? _avgComment;

  double? _mixResult;
  String? _mixComment;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    highFuelCtrl.dispose();
    regFuelCtrl.dispose();
    beforeLiterCtrl.dispose();
    beforeOctaneCtrl.dispose();
    addLiterCtrl.dispose();
    addOctaneCtrl.dispose();
    super.dispose();
  }

  // ================= 계산 로직 =================

  double _calcAverageOctane() {
    final high = double.tryParse(highFuelCtrl.text) ?? 0;
    final reg = double.tryParse(regFuelCtrl.text) ?? 0;
    final total = high + reg;
    if (total <= 0) return 0;
    // (예시) 고급유/일반유 고정 옥탄가 기준
    return ((high * 94) + (reg * 91)) / total;
  }

  double _calcMixedOctane() {
    final beforeL = double.tryParse(beforeLiterCtrl.text) ?? 0;
    final beforeO = double.tryParse(beforeOctaneCtrl.text) ?? 0;
    final addL = double.tryParse(addLiterCtrl.text) ?? 0;
    final addO = double.tryParse(addOctaneCtrl.text) ?? 0;
    final total = beforeL + addL;
    if (total <= 0) return 0;
    return ((beforeL * beforeO) + (addL * addO)) / total;
  }

  // ================= 저장 =================

  void _saveLog({
    required String type,
    required double result,
    required Map<String, dynamic> inputs,
  }) {
    final box = Hive.box<OctaneLog>('octane_logs');
    box.add(
      OctaneLog(
        time: DateTime.now(),
        type: type, // average | mixed
        result: result,
        inputs: inputs,
      ),
    );
  }

  // ================= 상태(태그/문구) =================

  _Status _status(double v) {
    if (v >= 95) {
      return _Status("안정", Icons.verified_rounded, Colors.green);
    } else if (v >= 92) {
      return _Status("보통", Icons.info_outline_rounded, Colors.orange);
    } else if (v >= 90) {
      return _Status("주의", Icons.warning_amber_rounded, Colors.deepOrange);
    } else {
      return _Status("위험", Icons.error_rounded, Colors.red);
    }
  }


  String _statusSentence(double v) {
    if (v >= 95) return "일반·고속 주행 모두 무난합니다";
    if (v >= 92) return "일상 주행에는 문제 없습니다";
    if (v >= 90) return "급가속·고회전은 자제하세요";
    return "노킹 가능성이 있으니 주의하세요";
  }


  // ================= 액션 =================

  void _onCalcAverage() {
    final v = _calcAverageOctane();
    if (v > 0) {
      _saveLog(
        type: "average",
        result: v,
        inputs: {
          "highLiter": highFuelCtrl.text,
          "regularLiter": regFuelCtrl.text,
        },
      );
    }
    setState(() {
      _avgResult = v;
      _avgComment = _statusSentence(v);
    });
  }

  void _onCalcMixed() {
    final v = _calcMixedOctane();
    if (v > 0) {
      _saveLog(
        type: "mixed",
        result: v,
        inputs: {
          "기존잔여연료": beforeLiterCtrl.text,
          "기존옥탄기": beforeOctaneCtrl.text,
          "추가연료": addLiterCtrl.text,
          "추가연료 옥탄가": addOctaneCtrl.text,
        },
      );
    }
    setState(() {
      _mixResult = v;
      _mixComment = _statusSentence(v);
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "고급유 노트",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "평균 계산"),
            Tab(text: "혼합 계산"),
            Tab(text: "기록"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAverageTab(),
            _buildMixedTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  // ===== 공통 패딩(하단 네비 겹침 방지) =====
  EdgeInsets _listPadding(BuildContext context) => EdgeInsets.fromLTRB(
    16,
    16,
    16,
    MediaQuery.of(context).padding.bottom + 80,
  );

  // ================= 평균 =================

  Widget _buildAverageTab() {
    return ListView(
      padding: _listPadding(context),
      children: [
        _sectionTitle("입력"),
        const SizedBox(height: 10),
        _panelCard(
          children: [
            _numberField(highFuelCtrl, "고급유 주유량 (L)", hint: "예: 20"),
            const SizedBox(height: 12),
            _numberField(regFuelCtrl, "일반유 주유량 (L)", hint: "예: 25"),
          ],
        ),
        const SizedBox(height: 16),
        _calcButton("옥탄가 계산", onPressed: _onCalcAverage),
        if (_avgResult != null) ...[
          const SizedBox(height: 18),
          _resultPanel(_avgResult!, _avgComment ?? ""),
        ],
      ],
    );
  }

  // ================= 혼합 =================

  Widget _buildMixedTab() {
    return ListView(
      padding: _listPadding(context),
      children: [
        _sectionTitle("입력"),
        const SizedBox(height: 10),
        _panelCard(
          children: [
            _numberField(beforeLiterCtrl, "기존 연료 (L)", hint: "예: 10"),
            const SizedBox(height: 12),
            _numberField(beforeOctaneCtrl, "기존 옥탄가", hint: "예: 95"),
            const SizedBox(height: 12),
            _numberField(addLiterCtrl, "추가 연료 (L)", hint: "예: 30"),
            const SizedBox(height: 12),
            _numberField(addOctaneCtrl, "추가 옥탄가", hint: "예: 98"),
          ],
        ),
        const SizedBox(height: 16),
        _calcButton("옥탄가 계산", onPressed: _onCalcMixed),
        if (_mixResult != null) ...[
          const SizedBox(height: 18),
          _resultPanel(_mixResult!, _mixComment ?? ""),
        ],
      ],
    );
  }

  // ================= 결과 패널(계기판 느낌) =================

  Widget _resultPanel(double value, String comment) {
    final st = _status(value);
    final brand = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 상단 상태 칩
            Align(
              alignment: Alignment.centerLeft,
              child: _statusChip(st),
            ),
            const SizedBox(height: 10),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(st.icon, size: 18, color: st.color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    comment,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: brand,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(_Status st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: st.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: st.color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(st.icon, size: 16, color: st.color),
          const SizedBox(width: 6),
          Text(
            st.label,
            style: TextStyle(
              color: st.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ================= 기록 =================

  Widget _buildHistoryTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<OctaneLog>('octane_logs').listenable(),
      builder: (context, Box<OctaneLog> box, _) {
        if (box.isEmpty) {
          return const Center(child: Text("저장된 기록이 없습니다"));
        }

        return ListView.builder(
          padding: _listPadding(context),
          itemCount: box.length,
          itemBuilder: (context, index) {
            final log = box.getAt(box.length - 1 - index)!;
            return _historyItem(log, indexFromTop: index);
          },
        );
      },
    );
  }

  Widget _historyItem(OctaneLog log, {required int indexFromTop}) {
    final st = _status(log.result);
    final brand = Theme.of(context).colorScheme.primary;

    final typeTitle = log.type == "average" ? "평균 계산" : "혼합 계산";
    final typeIcon = log.type == "average"
        ? Icons.calculate_rounded
        : Icons.merge_type_rounded;

    final date =
        "${log.time.year}.${log.time.month.toString().padLeft(2, '0')}.${log.time.day.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onLongPress: () {
          // 길게 눌러 삭제 (MVP)
          final box = Hive.box<OctaneLog>('octane_logs');
          box.deleteAt(box.length - 1 - indexFromTop);
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HistoryDetailPage(log: log),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              // 좌측 아이콘 (화이트 카드에서 포인트만)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: brand.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: brand),
              ),
              const SizedBox(width: 12),

              // 가운데 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _statusChip(st),
                  ],
                ),
              ),

              // 우측 결과 숫자 (진한 색, 분홍 X)
              Text(
                log.result.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 공용 위젯 =================

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _panelCard({required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _calcButton(String text, {required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.calculate_rounded),
      label: Text(text),
      onPressed: onPressed,
    );
  }

  // ✅ “입력창이 단단해 보이게” 핵심: filled + outline + 대비
  Widget _numberField(
      TextEditingController ctrl,
      String label, {
        String? hint,
      }) {
    final brand = Theme.of(context).colorScheme.primary;

    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand, width: 1.6),
        ),
      ),
    );
  }
}

// ===== 상태 모델 =====
class _Status {
  final String label;
  final IconData icon;
  final Color color;
  const _Status(this.label, this.icon, this.color);
}
