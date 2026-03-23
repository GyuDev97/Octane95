import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'history_detail_page.dart';
import 'model/car_profile.dart';
import 'model/octane_log.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(OctaneLogAdapter());
  }
  await Hive.openBox<OctaneLog>('octane_logs');

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(CarProfileAdapter());
  }

  await Hive.openBox<CarProfile>('car_profile');

  runApp(const OctaneApp());
}

class OctaneApp extends StatelessWidget {
  const OctaneApp({super.key});

  static const Color _brand = Color(0xFF8B3A3A);
  static const Color _brandDark = Color(0xFF6E2C2C);
  static const Color _bg = Color(0xFFF8F7F6);
  static const Color _card = Colors.white;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _brand,
        brightness: Brightness.light,
        primary: _brand,
        surface: _card,
      ),
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
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F1717),
          ),
        ),
        dividerColor: const Color(0xFFE7DFDB),
        tabBarTheme: const TabBarThemeData(
          labelColor: _brand,
          unselectedLabelColor: Color(0xFF231C1B),
          indicatorColor: _brand,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Color(0xFFE7DFDB),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: _brandDark,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.08),
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFCFBFB),
          isDense: true,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          hintStyle: const TextStyle(
            color: Color(0xFFA0948E),
            fontWeight: FontWeight.w600,
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF5F504C),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD9D0CC), width: 1.4),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD9D0CC), width: 1.4),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: _brand, width: 1.8),
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

  final TextEditingController highFuelCtrl = TextEditingController();
  final TextEditingController regFuelCtrl = TextEditingController();

  final TextEditingController beforeLiterCtrl = TextEditingController();
  final TextEditingController beforeOctaneCtrl = TextEditingController();
  final TextEditingController addLiterCtrl = TextEditingController();
  final TextEditingController addOctaneCtrl = TextEditingController();

  final TextEditingController carNameCtrl = TextEditingController();
  final TextEditingController carYearCtrl = TextEditingController();
  final TextEditingController carRecCtrl = TextEditingController();
  final TextEditingController carWarnCtrl = TextEditingController();
  final TextEditingController carTankCtrl = TextEditingController();

  double? _avgResult;
  String? _avgComment;

  double? _mixResult;
  String? _mixComment;

  double? _touchedValue;
  int? _selectedSpotIndex;

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
    carNameCtrl.dispose();
    carYearCtrl.dispose();
    carRecCtrl.dispose();
    carWarnCtrl.dispose();
    carTankCtrl.dispose();

    super.dispose();
  }

  double _calcAverageOctane() {
    final high = double.tryParse(highFuelCtrl.text) ?? 0;
    final reg = double.tryParse(regFuelCtrl.text) ?? 0;
    final total = high + reg;
    if (total <= 0) return 0;
    return ((high * 97) + (reg * 92)) / total;
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

  void _saveLog({
    required String type,
    required double result,
    required Map<String, dynamic> inputs,
  }) {
    final box = Hive.box<OctaneLog>('octane_logs');
    box.add(
      OctaneLog(
        time: DateTime.now(),
        type: type,
        result: result,
        inputs: inputs,
      ),
    );
  }

  _Status _status(double v) {
    final box = Hive.box<CarProfile>('car_profile');
    final car = box.get('main');

    final recommend = car?.recommendedOctane ?? 95;
    final warning = car?.warningOctane ?? 91;

    if (v >= recommend) {
      return _Status(
        '최적 상태',
        '차량 기준에서 최상의 옥탄가입니다',
        Icons.verified_rounded,
        Colors.green,
      );
    } else if (v >= warning) {
      return _Status(
        '일반 상태',
        '일반 주행에 적합한 수준입니다',
        Icons.info_outline_rounded,
        Colors.orange,
      );
    } else {
      return _Status(
        '일반 상태',
        '노킹 및 출력 저하 가능성이 있습니다',
        Icons.warning_amber_rounded,
        Colors.red,
      );
    }
  }

  String _statusSentence(double v) => _status(v).message;

  void _onCalcAverage() {
    final v = _calcAverageOctane();
    if (v > 0) {
      _saveLog(
        type: 'average',
        result: v,
        inputs: {
          'highLiter': highFuelCtrl.text,
          'regularLiter': regFuelCtrl.text,
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
        type: 'mixed',
        result: v,
        inputs: {
          'beforeLiter': beforeLiterCtrl.text,
          'beforeOctane': beforeOctaneCtrl.text,
          'addLiter': addLiterCtrl.text,
          'addOctane': addOctaneCtrl.text,
        },
      );
    }
    setState(() {
      _mixResult = v;
      _mixComment = _statusSentence(v);
    });
  }

  void _saveCarProfile({
    required String name,
    required int year,
    required double recommend,
    required double warning,
    double? tank,
  }) {
    final box = Hive.box<CarProfile>('car_profile');

    box.put(
      'main',
      CarProfile(
        name: name,
        year: year,
        recommendedOctane: recommend,
        warningOctane: warning,
        tankCapacity: tank, // 🔥 추가
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고급유 노트'),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: '홈'),
            Tab(text: '기록'),
            Tab(text: '차량'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildHomeTab(),
            _buildHistoryTab(),
            _buildCarTab(),
          ],
        ),
      ),
    );
  }

  EdgeInsets _listPadding(BuildContext context) => EdgeInsets.fromLTRB(
    16,
    16,
    16,
    MediaQuery.of(context).padding.bottom + 96,
  );

  bool isAverageMode = true;

  Widget _buildHomeTab() {
    return ListView(
      padding: _listPadding(context),
      children: [
        _sectionTitle('옥탄 계산'),
        const SizedBox(height: 12),

        // 🔥 모드 선택 (핵심)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _modeButton('평균', true),
              _modeButton('혼합', false),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 🔥 입력 영역
        _panelCard(
          children: isAverageMode
              ? [
            _numberField(highFuelCtrl, '고급유(L)', hint: '예: 20'),
            const SizedBox(height: 14),
            _numberField(regFuelCtrl, '일반유(L)', hint: '예: 25'),
          ]
              : [
            _numberField(beforeLiterCtrl, '기존 연료(L)', hint: '예: 10'),
            const SizedBox(height: 14),
            _numberField(beforeOctaneCtrl, '기존 옥탄가', hint: '예: 95'),
            const SizedBox(height: 14),
            _numberField(addLiterCtrl, '추가 연료(L)', hint: '예: 30'),
            const SizedBox(height: 14),
            _numberField(addOctaneCtrl, '추가 옥탄가', hint: '예: 98'),
            const SizedBox(height: 14),
            _numberField(carTankCtrl, '연료탱크 용량(L)', hint: '예: 50'),
          ],
        ),

        const SizedBox(height: 18),

        _calcButton(
          '옥탄가 계산',
          onPressed: () {
            if (isAverageMode) {
              _onCalcAverage();
            } else {
              _onCalcMixed();
            }
          },
        ),

        if ((isAverageMode && _avgResult != null) ||
            (!isAverageMode && _mixResult != null)) ...[
          const SizedBox(height: 18),
          _resultPanel(
            isAverageMode ? _avgResult! : _mixResult!,
            isAverageMode ? _avgComment ?? '' : _mixComment ?? '',
          ),
        ],
      ],
    );
  }

  Widget _modeButton(String text, bool isAvg) {
    final selected = isAverageMode == isAvg;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isAverageMode = isAvg;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF8B3A3A) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAverageTab() {
    return ListView(
      padding: _listPadding(context),
      children: [
        _sectionTitle('입력'),
        const SizedBox(height: 12),
        _panelCard(
          children: [
            _numberField(highFuelCtrl, '고급유(L)', hint: '예: 20'),
            const SizedBox(height: 14),
            _numberField(regFuelCtrl, '일반유(L)', hint: '예: 25'),
          ],
        ),
        const SizedBox(height: 18),
        _calcButton('옥탄가 계산', onPressed: _onCalcAverage),
        if (_avgResult != null) ...[
          const SizedBox(height: 18),
          _resultPanel(_avgResult!, _avgComment ?? ''),
        ],
      ],
    );
  }

  Widget _buildMixedTab() {
    return ListView(
      padding: _listPadding(context),
      children: [
        _sectionTitle('입력'),
        const SizedBox(height: 12),
        _panelCard(
          children: [
            _numberField(beforeLiterCtrl, '기존 연료(L)', hint: '예: 10'),
            const SizedBox(height: 14),
            _numberField(beforeOctaneCtrl, '기존 옥탄가(RON)', hint: '예: 95'),
            const SizedBox(height: 14),
            _numberField(addLiterCtrl, '추가 연료(L)', hint: '예: 30'),
            const SizedBox(height: 14),
            _numberField(addOctaneCtrl, '추가 옥탄가(RON)', hint: '예: 98'),
          ],
        ),
        const SizedBox(height: 18),
        _calcButton('옥탄가 계산', onPressed: _onCalcMixed),
        if (_mixResult != null) ...[
          const SizedBox(height: 18),
          _resultPanel(_mixResult!, _mixComment ?? ''),
        ],
      ],
    );
  }

  Widget _resultPanel(double value, String comment) {
    final st = _status(value);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _statusChip(st),
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: value - 0.45, end: value),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) {
                  return Text(
                    animatedValue.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade300),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(st.icon, size: 18, color: st.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      comment,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(_Status st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: st.color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: st.color.withOpacity(0.34), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(st.icon, size: 16, color: st.color),
          const SizedBox(width: 7),
          Text(
            st.label,
            style: TextStyle(
              color: st.color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(List<OctaneLog> logs) {
    final values = logs.map((e) => e.result).toList();

    final avg = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statItem('평균', avg),
                _statItem('최고', max),
                _statItem('최저', min),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              '총 기록 ${logs.length}개',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String title, double value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<OctaneLog>('octane_logs').listenable(),
      builder: (context, Box<OctaneLog> box, _) {
        if (box.isEmpty) {
          return Center(
            child: Text(
              '저장된 기록이 없습니다',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        final logs = box.values.toList();

        return ListView(
          padding: _listPadding(context),
          children: [
            _buildStatsCard(logs), // 🔥 추가
            _buildOctaneChart(logs),
            const SizedBox(height: 10),
            ...List.generate(box.length, (index) {
              final log = box.getAt(box.length - 1 - index)!;
              return _historyItem(log, indexFromTop: index);
            }),
          ],
        );
      },
    );
  }

  Widget _buildOctaneChart(List<OctaneLog> logs) {
    if (logs.isEmpty) return const SizedBox.shrink();
    final car = Hive.box<CarProfile>('car_profile').get('main');

    final spots = List.generate(
      logs.length,
          (i) => FlSpot(i.toDouble(), logs[i].result),
    );

    final latest = logs.last.result;
    final prev = logs.length > 1 ? logs[logs.length - 2].result : latest;
    final diff = latest - prev;
    final displayValue = _touchedValue ?? latest;
    final selectedLabel = _selectedSpotIndex != null
        ? '${_selectedSpotIndex! + 1}번째 기록'
        : '최신 기록';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (car != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${car.name} (${car.year}) • 기준 ${car.recommendedOctane}/${car.warningOctane}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 옥탄가',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (diff >= 0
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE53935))
                      .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${diff >= 0 ? '▲' : '▼'} ${diff.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    color: diff >= 0
                        ? const Color(0xFF43A047)
                        : const Color(0xFFD32F2F),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              displayValue.toStringAsFixed(2),
              key: ValueKey('${displayValue.toStringAsFixed(2)}_${_selectedSpotIndex ?? -1}'),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _touchedValue != null ? '선택값 · $selectedLabel' : '최신값 기준',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 172,
            child: LineChart(
              LineChartData(
                minX: -0.1,
                maxX: spots.length - 1 + 0.1,
                minY: 88,
                maxY: 100,
                clipData: const FlClipData.all(),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.10),
                      strokeWidth: 1,
                    );
                  },
                ),
                extraLinesData: ExtraLinesData(
                  verticalLines: _selectedSpotIndex != null
                      ? [
                    VerticalLine(
                      x: _selectedSpotIndex!.toDouble(),
                      color: const Color(0xFF8B3A3A).withOpacity(0.20),
                      strokeWidth: 1.2,
                      dashArray: [6, 4],
                    ),
                  ]
                      : [],
                ),
                showingTooltipIndicators: _selectedSpotIndex != null
                    ? [
                  ShowingTooltipIndicators([
                    LineBarSpot(
                      LineChartBarData(spots: spots),
                      0,
                      spots[_selectedSpotIndex!],
                    ),
                  ])
                ]
                    : [],
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchSpotThreshold: 22,
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent ||
                        event is FlPanEndEvent ||
                        event is FlLongPressEnd) {
                      return;
                    }

                    final lineSpots = response?.lineBarSpots;
                    if (lineSpots != null && lineSpots.isNotEmpty) {
                      final spot = lineSpots.first;
                      setState(() {
                        _touchedValue = spot.y;
                        _selectedSpotIndex = spot.x.toInt();
                      });
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          spot.y.toStringAsFixed(2),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.20,
                    preventCurveOverShooting: true,
                    color: Colors.deepOrange.shade500,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isSelected = _selectedSpotIndex == index;
                        final isLatest = index == spots.length - 1;

                        if (isSelected) {
                          return FlDotCirclePainter(
                            radius: 7.5,
                            color: Colors.deepOrange.shade500,
                            strokeWidth: 4,
                            strokeColor: Colors.white,
                          );
                        }

                        if (isLatest) {
                          return FlDotCirclePainter(
                            radius: 5.5,
                            color: Colors.deepOrange.shade500,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }

                        return FlDotCirclePainter(
                          radius: 4.5,
                          color: Colors.white,
                          strokeWidth: 2.6,
                          strokeColor: Colors.deepOrange.shade500,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.deepOrange.withOpacity(0.08),
                      applyCutOffY: true,
                      cutOffY: 88,
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(OctaneLog log, {required int indexFromTop}) {
    final st = _status(log.result);
    final brand = Theme.of(context).colorScheme.primary;

    final typeTitle = _typeTitle(log.type);
    final typeIcon = log.type == 'average'
        ? Icons.calculate_rounded
        : Icons.alt_route_rounded;

    final date =
        '${log.time.year}.${log.time.month.toString().padLeft(2, '0')}.${log.time.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onLongPress: () {
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: brand.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(typeIcon, color: brand, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF181313),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _statusChip(st),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                log.result.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeTitle(String type) {
    switch (type) {
      case 'average':
        return '평균 계산';
      case 'mixed':
        return '혼합 계산';
      default:
        return type;
    }
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _panelCard({required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: children),
      ),
    );
  }

  Widget _calcButton(String text, {required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.calculate_rounded, size: 26),
      label: Text(text),
      onPressed: onPressed,
    );
  }

  Widget _numberField(
      TextEditingController ctrl,
      String label, {
        String? hint,
      }) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }


  Widget _buildCarTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            '곧 오픈 준비중이에요 🚧',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '차량 프로필 기능은 곧 추가됩니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  /*
  Widget _buildCarTab() {
    final car = Hive.box<CarProfile>('car_profile').get('main');
    if (car != null) {
      carTankCtrl.text = car.tankCapacity?.toString() ?? '';
    }
    return ListView(
      padding: _listPadding(context),
      children: [
        _sectionTitle('차량 프로필'),
        const SizedBox(height: 12),

        if (car != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${car.name} (${car.year}) • 기준 ${car.recommendedOctane}/${car.warningOctane}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        _panelCard(
          children: [
            TextField(
              controller: carNameCtrl,
              decoration: const InputDecoration(
                labelText: '차량명',
                hintText: '예: 셀토스 1.6T',
              ),
            ),
            const SizedBox(height: 14),
            _numberField(carYearCtrl, '연식', hint: '예: 2020'),
            const SizedBox(height: 14),
            _numberField(carRecCtrl, '권장 옥탄가', hint: '예: 95'),
            const SizedBox(height: 14),
            _numberField(carWarnCtrl, '경고 기준', hint: '예: 91'),
          ],
        ),

        const SizedBox(height: 18),

        ElevatedButton(
          onPressed: () {
            _saveCarProfile(
              name: carNameCtrl.text,
              year: int.tryParse(carYearCtrl.text) ?? 0,
              recommend: double.tryParse(carRecCtrl.text) ?? 95,
              warning: double.tryParse(carWarnCtrl.text) ?? 91,
              tank: double.tryParse(carTankCtrl.text), // 🔥 추가
            );

            setState(() {});

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('차량 정보 저장 완료')),
            );
          },
          child: const Text('저장'),
        ),
      ],
    );
  }*/
}




class _Status {
  final String label;
  final String message;
  final IconData icon;
  final Color color;

  const _Status(this.label, this.message, this.icon, this.color);
}
