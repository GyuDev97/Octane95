import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'history_detail_page.dart';
import 'model/car_profile.dart';
import 'model/octane_log.dart';

Future<void> main() async {
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
  await AnalyticsService.init();
  await AnalyticsService.logAppOpen();

  runApp(const OctaneApp());
}

class AnalyticsService {
  static FirebaseAnalytics? _analytics;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
    } catch (_) {
      _analytics = null;
    }
  }

  static Future<void> logAppOpen() async {
    try {
      await _analytics?.logAppOpen();
    } catch (_) {}
  }

  static Future<void> log(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }
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
      title: '고급유노트',
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
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: _brandDark,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 18,
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
  final TextEditingController mixTankCtrl = TextEditingController();

  final TextEditingController targetOctaneCtrl = TextEditingController();
  final TextEditingController targetCurrentLiterCtrl = TextEditingController();
  final TextEditingController targetCurrentOctaneCtrl = TextEditingController();
  final TextEditingController targetFuelOctaneCtrl = TextEditingController();

  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController totalCostCtrl = TextEditingController();
  final TextEditingController memoCtrl = TextEditingController();

  final TextEditingController carNameCtrl = TextEditingController();
  final TextEditingController carYearCtrl = TextEditingController();
  final TextEditingController carRecCtrl = TextEditingController();
  final TextEditingController carWarnCtrl = TextEditingController();
  final TextEditingController carTankCtrl = TextEditingController();

  double? _avgResult;
  String? _avgComment;

  double? _mixResult;
  String? _mixComment;

  double? _targetRequiredLiter;
  String? _targetComment;
  bool _targetImpossible = false;
  double? _targetResultOctane;

  int _currentMainTab = 0;
  double? _touchedValue;
  int? _selectedSpotIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_syncMainTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOnboardingIfNeeded();
    });
  }

  void _syncMainTab() {
    if (_currentMainTab == _tabController.index) return;
    setState(() {
      _currentMainTab = _tabController.index;
    });
    _logMainTabOpen(_currentMainTab);
  }

  void _logMainTabOpen(int index) {
    if (index == 1) {
      AnalyticsService.log('open_history');
    } else if (index == 2) {
      AnalyticsService.log('open_settings');
    }
  }

  Future<void> _showOnboardingIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('onboarding_shown_v1') ?? false;
    if (alreadyShown || !mounted) return;

    var pageIndex = 0;
    final controller = PageController();

    Future<void> finish() async {
      await prefs.setBool('onboarding_shown_v1', true);
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: SizedBox(
                  height: 420,
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: controller,
                          onPageChanged: (index) {
                            setDialogState(() {
                              pageIndex = index;
                            });
                          },
                          children: const [
                            _OnboardingPage(
                              icon: Icons.calculate_outlined,
                              title: '고급유와 일반유 혼합 옥탄 계산',
                              message:
                                  '주유량을 입력하면 섞인 뒤의 평균 옥탄가를 바로 확인할 수 있습니다.',
                            ),
                            _OnboardingPage(
                              icon: Icons.directions_car_outlined,
                              title: '차량 기준 설정',
                              message:
                                  '권장 옥탄가와 경고 기준을 저장하면 계산 결과를 내 차량 기준으로 판단합니다.',
                            ),
                            _OnboardingPage(
                              icon: Icons.bar_chart_outlined,
                              title: '기록 저장 및 통계 관리',
                              message:
                                  '계산 결과는 기록 저장 버튼을 눌렀을 때만 통계와 그래프에 반영됩니다.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final selected = index == pageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: selected ? 20 : 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF8B3A3A)
                                  : const Color(0xFFE2D9D5),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          TextButton(
                            onPressed: finish,
                            child: const Text('건너뛰기'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              if (pageIndex < 2) {
                                controller.nextPage(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                );
                              } else {
                                finish();
                              }
                            },
                            child: Text(pageIndex < 2 ? '다음' : '시작하기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }
  Future<void> _confirmDeleteLog(int indexFromTop) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('기록 삭제'),
            content: const Text('이 기록을 삭제할까요? 삭제 후에는 복구할 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final box = Hive.box<OctaneLog>('octane_logs');
    box.deleteAt(box.length - 1 - indexFromTop);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('기록을 삭제했습니다.')));
  }

  Future<void> _confirmDeleteCar(Box<CarProfile> box) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('차량 정보 삭제'),
            content: const Text('저장된 차량 정보를 삭제할까요? 기준 옥탄가 설정도 함께 지워집니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    box.delete('main');
    carNameCtrl.clear();
    carYearCtrl.clear();
    carRecCtrl.clear();
    carWarnCtrl.clear();
    carTankCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('차량 정보를 삭제했습니다.')));
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncMainTab);
    _tabController.dispose();
    highFuelCtrl.dispose();
    regFuelCtrl.dispose();
    beforeLiterCtrl.dispose();
    beforeOctaneCtrl.dispose();
    addLiterCtrl.dispose();
    addOctaneCtrl.dispose();
    mixTankCtrl.dispose();
    targetOctaneCtrl.dispose();
    targetCurrentLiterCtrl.dispose();
    targetCurrentOctaneCtrl.dispose();
    targetFuelOctaneCtrl.dispose();
    priceCtrl.dispose();
    totalCostCtrl.dispose();
    memoCtrl.dispose();
    carNameCtrl.dispose();
    carYearCtrl.dispose();
    carRecCtrl.dispose();
    carWarnCtrl.dispose();
    carTankCtrl.dispose();

    super.dispose();
  }

  double _parseDouble(TextEditingController ctrl) {
    return double.tryParse(ctrl.text.trim()) ?? 0;
  }

  double _calcAverageOctane() {
    final high = _parseDouble(highFuelCtrl);
    final reg = _parseDouble(regFuelCtrl);
    final total = high + reg;
    if (total <= 0) return 0;
    return ((high * 97) + (reg * 92)) / total;
  }

  double _calcMixedOctane() {
    final beforeL = _parseDouble(beforeLiterCtrl);
    final beforeO = _parseDouble(beforeOctaneCtrl);
    final addL = _parseDouble(addLiterCtrl);
    final addO = _parseDouble(addOctaneCtrl);
    final total = beforeL + addL;
    if (total <= 0) return 0;
    return ((beforeL * beforeO) + (addL * addO)) / total;
  }

  double _mixedTotalLiter() {
    return _parseDouble(beforeLiterCtrl) + _parseDouble(addLiterCtrl);
  }

  double? _calcTargetRequiredLiter() {
    final target = _parseDouble(targetOctaneCtrl);
    final currentL = _parseDouble(targetCurrentLiterCtrl);
    final currentO = _parseDouble(targetCurrentOctaneCtrl);
    final fuelO = _parseDouble(targetFuelOctaneCtrl);

    if (target <= 0 || currentL <= 0 || currentO <= 0 || fuelO <= 0) {
      return null;
    }

    if (currentO >= target) {
      return 0;
    }

    if (fuelO <= target) {
      return double.infinity;
    }

    return ((target - currentO) * currentL) / (fuelO - target);
  }

  CarProfile? _mainCar() {
    return Hive.box<CarProfile>('car_profile').get('main');
  }

  void _saveLog({
    required String type,
    required double result,
    required Map<String, dynamic> inputs,
    String memo = '',
  }) {
    final box = Hive.box<OctaneLog>('octane_logs');
    box.add(
      OctaneLog(
        time: DateTime.now(),
        type: type,
        result: result,
        inputs: inputs,
        memo: memo,
      ),
    );
    AnalyticsService.log('save_record', parameters: {'type': type});
  }

  _Status _status(double v) {
    final car = _mainCar();
    if (car == null) {
      return const _Status(
        '차량 기준 미설정',
        '차량 정보를 저장하면 권장/경고 기준으로 결과를 판단합니다.',
        Icons.tune_rounded,
        Colors.blueGrey,
      );
    }

    final recommend = car.recommendedOctane;
    final warning = car.warningOctane;

    if (v >= recommend) {
      return const _Status(
        '권장 기준 충족',
        '차량 기준에서 권장 옥탄가를 충족했습니다.',
        Icons.verified_rounded,
        Colors.green,
      );
    } else if (v >= warning) {
      return const _Status(
        '보통',
        '일상 주행은 가능하지만 권장 옥탄가까지 여유가 크진 않습니다.',
        Icons.info_outline_rounded,
        Colors.orange,
      );
    } else {
      return const _Status(
        '주의',
        '고부하 주행은 피하고 다음 주유에서 옥탄가를 보강하는 편이 좋습니다.',
        Icons.warning_amber_rounded,
        Colors.red,
      );
    }
  }

  String _statusSentence(double v) => _status(v).message;
  _TankInsight? _tankInsight() {
    final manualTank = _parseDouble(mixTankCtrl);
    final tankCapacity =
        manualTank > 0 ? manualTank : _mainCar()?.tankCapacity;
    if (tankCapacity == null || tankCapacity <= 0) {
      return null;
    }

    final total = _mixedTotalLiter();
    if (total <= 0) {
      return null;
    }

    final remaining = tankCapacity - total;
    if (remaining < 0) {
      return _TankInsight(
        title: '탱크 용량 초과',
        message:
            '총 ${total.toStringAsFixed(1)}L로 탱크 용량을 ${remaining.abs().toStringAsFixed(1)}L 초과합니다.',
        color: Colors.red,
        icon: Icons.warning_amber_rounded,
        progress: 1,
      );
    }

    final usageRatio = (total / tankCapacity).clamp(0.0, 1.0);
    return _TankInsight(
      title: '탱크 충전 상태',
      message:
          '총 ${total.toStringAsFixed(1)}L로 ${(usageRatio * 100).toStringAsFixed(0)}% 충전됩니다. 여유는 ${remaining.toStringAsFixed(1)}L입니다.',
      color: Colors.blueGrey,
      icon: Icons.local_gas_station_rounded,
      progress: usageRatio,
    );
  }

  void _saveAverageLog() {
    final value = _avgResult;
    if (value == null || value <= 0) return;

    _saveLog(
      type: 'average',
      result: value,
      inputs: {
        'highLiter': highFuelCtrl.text.trim(),
        'regularLiter': regFuelCtrl.text.trim(),
        ..._recordInputs(),
      },
      memo: memoCtrl.text.trim(),
    );
    setState(() {
      _avgResult = null;
      _avgComment = null;
    });
    _showSavedSnackBar();
  }

  void _saveMixedLog() {
    final value = _mixResult;
    if (value == null || value <= 0) return;

    _saveLog(
      type: 'mixed',
      result: value,
      inputs: {
        'beforeLiter': beforeLiterCtrl.text.trim(),
        'beforeOctane': beforeOctaneCtrl.text.trim(),
        'addLiter': addLiterCtrl.text.trim(),
        'addOctane': addOctaneCtrl.text.trim(),
        if (mixTankCtrl.text.trim().isNotEmpty)
          'tankCapacity': mixTankCtrl.text.trim()
        else if (_mainCar()?.tankCapacity != null)
          'tankCapacity': _mainCar()!.tankCapacity!.toStringAsFixed(1),
        ..._recordInputs(),
      },
      memo: memoCtrl.text.trim(),
    );
    setState(() {
      _mixResult = null;
      _mixComment = null;
    });
    _showSavedSnackBar();
  }

  void _saveTargetLog() {
    final value = _targetResultOctane;
    final requiredLiter = _targetRequiredLiter;
    if (value == null || value <= 0 || requiredLiter == null || _targetImpossible) {
      return;
    }

    _saveLog(
      type: 'target',
      result: value,
      inputs: {
        'targetOctane': targetOctaneCtrl.text.trim(),
        'currentLiter': targetCurrentLiterCtrl.text.trim(),
        'currentOctane': targetCurrentOctaneCtrl.text.trim(),
        'fuelOctane': targetFuelOctaneCtrl.text.trim(),
        'requiredLiter': requiredLiter.toStringAsFixed(1),
        ..._recordInputs(),
      },
      memo: memoCtrl.text.trim(),
    );
    setState(() {
      _targetRequiredLiter = null;
      _targetResultOctane = null;
      _targetComment = null;
      _targetImpossible = false;
    });
    _showSavedSnackBar();
  }

  void _showSavedSnackBar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ 기록이 저장되었습니다.')));
  }

  void _onCalcAverage() {
    final value = _calcAverageOctane();
    setState(() {
      _avgResult = value;
      _avgComment = _statusSentence(value);
    });
    AnalyticsService.log('calculate_simple');
  }

  void _onCalcMixed() {
    final value = _calcMixedOctane();
    setState(() {
      _mixResult = value;
      _mixComment = _statusSentence(value);
    });
    AnalyticsService.log('calculate_tank');
  }

  Map<String, dynamic> _recordInputs() {
    return {
      if (priceCtrl.text.trim().isNotEmpty) 'unitPrice': priceCtrl.text.trim(),
      if (totalCostCtrl.text.trim().isNotEmpty)
        'totalCost': totalCostCtrl.text.trim(),
    };
  }

  void _onCalcTarget() {
    final requiredLiter = _calcTargetRequiredLiter();
    final target = _parseDouble(targetOctaneCtrl);
    final currentOctane = _parseDouble(targetCurrentOctaneCtrl);
    final fuelOctane = _parseDouble(targetFuelOctaneCtrl);

    if (requiredLiter == null) {
      setState(() {
        _targetRequiredLiter = null;
        _targetResultOctane = null;
        _targetImpossible = true;
        _targetComment = '목표 옥탄가, 현재 잔량, 현재 옥탄가, 추가 연료 옥탄가를 입력해 주세요.';
      });
      AnalyticsService.log('calculate_target');
      return;
    }

    final impossible = requiredLiter.isInfinite;
    final resultOctane = currentOctane >= target ? currentOctane : target;

    setState(() {
      _targetRequiredLiter = impossible ? null : requiredLiter;
      _targetResultOctane = impossible || target <= 0 ? null : resultOctane;
      _targetImpossible = impossible;
      if (impossible) {
        _targetComment = '추가할 연료 옥탄가가 목표 ${target.toStringAsFixed(1)}보다 높아야 도달할 수 있습니다.';
      } else if (requiredLiter <= 0) {
        _targetComment = '현재 연료가 이미 목표 옥탄가를 충족합니다.';
      } else {
        _targetComment =
            '${fuelOctane.toStringAsFixed(1)} 옥탄 연료를 ${requiredLiter.toStringAsFixed(1)}L 이상 넣으면 목표 ${target.toStringAsFixed(1)}에 도달합니다.';
      }
    });
    AnalyticsService.log('calculate_target');
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
        tankCapacity: tank, // ?뵦 異붽?
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isHome = _currentMainTab == 0;

    return Scaffold(
      backgroundColor:
          isHome ? const Color(0xFF07111B) : Theme.of(context).scaffoldBackgroundColor,
      appBar: isHome
          ? null
          : AppBar(
              title: const Text('고급유노트'),
              actions: [
                IconButton(
                  tooltip: '설정',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _tabController.animateTo(2),
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorWeight: 4,
                tabs: const [
                  Tab(text: '홈'),
                  Tab(text: '기록'),
                  Tab(text: '설정'),
                ],
              ),
            ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            if (!isHome) return null;
            return TextStyle(
              color: selected ? const Color(0xFF00D084) : const Color(0xFF7F8D9C),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            if (!isHome) return null;
            return IconThemeData(
              color: selected ? const Color(0xFF00D084) : const Color(0xFF7F8D9C),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentMainTab,
          height: 72,
          backgroundColor: isHome ? const Color(0xFF07111B) : Colors.white,
          indicatorColor:
              isHome ? const Color(0xFF063D2E) : const Color(0xFFF2DCDD),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            setState(() {
              _currentMainTab = index;
            });
            _logMainTabOpen(index);
            _tabController.animateTo(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: '기록',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: '설정',
            ),
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

  int _calcMode = 0;

  bool get _isAverageMode => _calcMode == 0;
  bool get _isMixedMode => _calcMode == 1;
  bool get _isTargetMode => _calcMode == 2;

  bool get _hasPendingResult {
    return (_isAverageMode && _avgResult != null) ||
        (_isMixedMode && _mixResult != null) ||
        (_isTargetMode &&
            (_targetRequiredLiter != null || _targetComment != null));
  }

  bool get _shouldExpandInput {
    return !_hasPendingResult ||
        (_isTargetMode && _targetImpossible && _targetRequiredLiter == null);
  }

  Widget _buildHomeTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<CarProfile>('car_profile').listenable(),
      builder: (context, Box<CarProfile> carBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<OctaneLog>('octane_logs').listenable(),
          builder: (context, Box<OctaneLog> logBox, _) {
            final car = carBox.get('main');
            final logs = logBox.values.toList();
            final latest = logs.isEmpty ? null : logs.last;
            final previous =
                logs.length >= 2 ? logs[logs.length - 2] : null;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                12,
                16,
                12,
                MediaQuery.of(context).padding.bottom + 18,
              ),
              children: [
                _dashboardHeader(),
                const SizedBox(height: 14),
                _dashboardVehicleCard(car, latest),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _dashboardMetricCard(
                        title: '이번 주유 품질',
                        subtitle: latest == null ? '기록 없음' : _typeTitle(latest.type),
                        value: latest == null
                            ? '--'
                            : latest.result.toStringAsFixed(1),
                        unit: '',
                        icon: Icons.local_gas_station_rounded,
                        accent: const Color(0xFF00B874),
                        footer: latest == null || previous == null
                            ? '첫 기록 대기'
                            : _signedDiff(latest.result - previous.result),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dashboardMetricCard(
                        title: '차량 기준',
                        subtitle: car == null ? '미설정' : '권장 / 경고',
                        value: car == null
                            ? '--'
                            : car.recommendedOctane.toStringAsFixed(1),
                        unit: car == null
                            ? ''
                            : ' / ${car.warningOctane.toStringAsFixed(1)}',
                        icon: Icons.speed_rounded,
                        accent: const Color(0xFF1BD199),
                        footer: latest == null
                            ? '기록 저장 전'
                            : _status(latest.result).label,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _dashboardRecentFuelCard(latest),
                const SizedBox(height: 14),
                _dashboardSevenDayCard(logs),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _showRecordSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A866),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Text('주유 기록하기'),
                ),
                if (_hasPendingResult) ...[
                  const SizedBox(height: 18),
                  _darkSectionTitle('저장 대기 중인 계산'),
                  const SizedBox(height: 10),
                  if (_isAverageMode && _avgResult != null)
                    _resultPanel(
                      _avgResult!,
                      _avgComment ?? '',
                      onSave: _saveAverageLog,
                    ),
                  if (_isMixedMode && _mixResult != null)
                    _resultPanel(
                      _mixResult!,
                      _mixComment ?? '',
                      onSave: _saveMixedLog,
                    ),
                  if (_isTargetMode &&
                      (_targetRequiredLiter != null ||
                          _targetComment != null))
                    _targetResultPanel(),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _dashboardHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '고급유 노트',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          tooltip: '설정',
          onPressed: () => _tabController.animateTo(2),
          icon: const Icon(
            Icons.settings_outlined,
            color: Color(0xFF86D9C2),
          ),
        ),
      ],
    );
  }

  Widget _dashboardVehicleCard(CarProfile? car, OctaneLog? latest) {
    final title = car == null ? '차량 설정 필요' : '${car.name} ${car.year}';
    final tank = car?.tankCapacity;
    final fuelLabel = latest == null
        ? '최근 주유 기록 없음'
        : latest.result >= (car?.recommendedOctane ?? 95)
            ? '연료 타입\n고급유 기준'
            : '연료 타입\n혼합 또는 일반';

    return _darkDashboardCard(
      padding: const EdgeInsets.fromLTRB(18, 17, 12, 17),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tank == null ? '탱크 용량 미설정' : '탱크 ${tank.toStringAsFixed(0)} L',
                  style: const TextStyle(
                    color: Color(0xFFB8C4D1),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  fuelLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 122,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E3D4C),
                  Color(0xFF111C28),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white.withOpacity(0.28),
                  size: 74,
                ),
                Positioned(
                  right: 12,
                  bottom: 10,
                  child: Icon(
                    Icons.local_gas_station_rounded,
                    color: const Color(0xFF00B874).withOpacity(0.9),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardMetricCard({
    required String title,
    required String subtitle,
    required String value,
    required String unit,
    required IconData icon,
    required Color accent,
    required String footer,
  }) {
    return _darkDashboardCard(
      padding: const EdgeInsets.fromLTRB(15, 15, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB8C4D1),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: const TextStyle(
                        color: Color(0xFFB8C4D1),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  footer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboardRecentFuelCard(OctaneLog? latest) {
    final liter = latest == null ? null : _logFuelLiter(latest);
    final cost = latest == null ? null : _logCost(latest);

    return _darkDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 주유',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _dashboardTinyStat(
                  '날짜',
                  latest == null ? '--' : _dateOnly(latest.time),
                ),
              ),
              Expanded(
                child: _dashboardTinyStat(
                  '옥탄가',
                  latest == null ? '--' : latest.result.toStringAsFixed(1),
                ),
              ),
              Expanded(
                child: _dashboardTinyStat(
                  '주유량',
                  liter == null ? '--' : '${liter.toStringAsFixed(1)} L',
                ),
              ),
              Expanded(
                child: _dashboardTinyStat(
                  '주유비',
                  cost == null ? '--' : _formatWon(cost),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboardSevenDayCard(List<OctaneLog> logs) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = logs.where((log) => log.time.isAfter(cutoff)).toList();
    final totalCost = recent.fold<double>(
      0,
      (sum, log) => sum + (_logCost(log) ?? 0),
    );
    final totalLiter = recent.fold<double>(
      0,
      (sum, log) => sum + (_logFuelLiter(log) ?? 0),
    );

    return _darkDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7일 리포트 요약',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _dashboardReportItem('주유', '${recent.length}')),
              const SizedBox(width: 8),
              Expanded(
                child: _dashboardReportItem(
                  '주유량',
                  totalLiter <= 0 ? '--' : '${totalLiter.toStringAsFixed(1)} L',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dashboardReportItem(
                  '주유비',
                  totalCost <= 0 ? '--' : _formatWon(totalCost),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboardTinyStat(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7F8D9C),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardReportItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF97A4B1),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkDashboardCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF111C28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1D2B38)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _darkSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  void _showRecordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF8F7F6),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: _inputInfoCard(),
            ),
          ),
        );
      },
    );
  }

  double? _logFuelLiter(OctaneLog log) {
    final inputs = log.inputs;
    final high = _asDouble(inputs['highLiter']);
    final regular = _asDouble(inputs['regularLiter']);
    if (high != null || regular != null) {
      return (high ?? 0) + (regular ?? 0);
    }

    final addLiter = _asDouble(inputs['addLiter']);
    if (addLiter != null) return addLiter;

    final requiredLiter = _asDouble(inputs['requiredLiter']);
    return requiredLiter;
  }

  double? _logCost(OctaneLog log) {
    return _asDouble(log.inputs['totalCost']);
  }

  double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = value.toString().replaceAll(',', '').trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  String _formatWon(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${buffer}원';
  }

  String _signedDiff(double value) {
    final sign = value >= 0 ? '+' : '-';
    return '$sign${value.abs().toStringAsFixed(1)}';
  }

  double? _pendingResultValue() {
    if (_isAverageMode) return _avgResult;
    if (_isMixedMode) return _mixResult;
    if (_isTargetMode) return _targetResultOctane;
    return null;
  }

  double _currentModeTotalLiter() {
    if (_isAverageMode) {
      return _parseDouble(highFuelCtrl) + _parseDouble(regFuelCtrl);
    }
    if (_isMixedMode) {
      return _mixedTotalLiter();
    }
    return _parseDouble(targetCurrentLiterCtrl);
  }

  String _recommendationText() {
    if (_isTargetMode) {
      if (_targetImpossible) {
        return '목표보다 높은 옥탄가의 연료를 선택해야 도달할 수 있습니다.';
      }
      if (_targetRequiredLiter != null) {
        final fuelOctane = _parseDouble(targetFuelOctaneCtrl);
        if (_targetRequiredLiter! <= 0) {
          return '현재 연료가 이미 목표 옥탄가를 충족합니다.';
        }
        return '${fuelOctane.toStringAsFixed(1)} 옥탄 연료를 ${_targetRequiredLiter!.toStringAsFixed(1)}L 이상 넣으면 목표에 도달합니다.';
      }
    }

    final result = _pendingResultValue();
    if (result == null) {
      return '값을 입력하고 계산하면 차량 기준에 맞춘 추천을 보여줍니다.';
    }

    final car = _mainCar();
    if (car == null) {
      return '차량 기준을 저장하면 권장/경고 기준에 맞춘 추천을 받을 수 있습니다.';
    }

    if (result >= car.recommendedOctane) {
      return '권장 기준을 충족합니다. 현재 주유 조합을 기록해두면 다음 주유 때 비교하기 쉽습니다.';
    }

    final totalLiter = _currentModeTotalLiter();
    const refillOctane = 98.0;
    if (totalLiter > 0 && refillOctane > car.recommendedOctane) {
      final requiredLiter =
          ((car.recommendedOctane - result) * totalLiter) /
              (refillOctane - car.recommendedOctane);
      if (requiredLiter.isFinite && requiredLiter > 0) {
        return '98 옥탄 고급유를 약 ${requiredLiter.toStringAsFixed(1)}L 보강하면 권장 ${car.recommendedOctane.toStringAsFixed(1)}에 가까워집니다.';
      }
    }

    if (result >= car.warningOctane) {
      return '일상 주행은 가능하지만 권장 기준까지 여유가 적습니다. 다음 주유에서 고급유 비중을 늘려보세요.';
    }

    return '경고 기준보다 낮습니다. 고부하 주행은 피하고 고급유로 옥탄가를 보강하는 편이 좋습니다.';
  }

  Widget _recommendationCard() {
    final result = _pendingResultValue();
    final status = result == null ? null : _status(result);
    final color = status?.color ?? const Color(0xFF8B3A3A);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.local_gas_station_rounded, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '추천 전략',
                    style: TextStyle(
                      color: Color(0xFF151823),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _recommendationText(),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '단가와 총액을 함께 남기면 비용 비교 기능으로 확장할 수 있습니다.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _runCurrentCalculation() {
    if (_isAverageMode) {
      _onCalcAverage();
    } else if (_isMixedMode) {
      _onCalcMixed();
    } else {
      _onCalcTarget();
    }
  }

  double _currentOctaneValue() {
    final box = Hive.box<OctaneLog>('octane_logs');
    if (box.isNotEmpty) return box.values.last.result;
    return _mainCar()!.recommendedOctane;
  }

  double? _previousOctaneValue() {
    final box = Hive.box<OctaneLog>('octane_logs');
    if (box.length < 2) return null;
    return box.values.elementAt(box.length - 2).result;
  }

  void _showCurrentOctaneHelp(bool hasLog) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(hasLog ? '최근 기록 기준' : '차량 기준 옥탄가'),
          content: Text(
            hasLog
                ? '마지막으로 저장한 기록의 옥탄가를 보여줍니다. 계산만 한 값은 기록 저장을 누르기 전까지 여기에 반영되지 않습니다.'
                : '저장된 기록이 없어서 차량 설정에 입력한 권장 옥탄가를 보여줍니다. 첫 기록을 저장하면 최근 기록 기준으로 바뀝니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Widget _currentOctaneCard() {
    final hasLog = Hive.box<OctaneLog>('octane_logs').isNotEmpty;
    final car = _mainCar();
    if (!hasLog && car == null) {
      return _starterGuideCard();
    }

    final value = _currentOctaneValue();
    final status = _status(value);
    final previous = _previousOctaneValue();
    final diff = previous == null ? null : value - previous;
    final diffColor = diff == null || diff >= 0
        ? Colors.white.withOpacity(0.88)
        : const Color(0xFFFFB4A7);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFAB4C4F),
            Color(0xFF732D31),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E3335).withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                hasLog ? '최근 기록 기준' : '차량 기준 옥탄가',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showCurrentOctaneHelp(hasLog),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white.withOpacity(0.72),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: value - 0.45, end: value),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return Text(
                animatedValue.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _filledStatusChip(status),
          const SizedBox(height: 16),
          Text(
            diff == null
                ? status.message
                : '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)} (이전 기록 대비)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: diffColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _starterGuideCard() {
    final brand = Theme.of(context).colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: brand.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.directions_car_rounded, color: brand),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '차량 정보를 먼저 설정해 주세요',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF151823),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '권장 옥탄가와 경고 기준을 저장하면 계산 결과를 내 차량 기준으로 판단합니다. 계산만으로는 기록이 저장되지 않습니다.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _guideStep('1', '차량 기준 저장')),
                const SizedBox(width: 8),
                Expanded(child: _guideStep('2', '옥탄가 계산')),
                const SizedBox(width: 8),
                Expanded(child: _guideStep('3', '필요할 때 기록')),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(2),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('차량 설정하기'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: const Color(0xFF312827),
                side: const BorderSide(color: Color(0xFFE0D8D4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideStep(String number, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7DFDB)),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Color(0xFF8B3A3A),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF343A46),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filledStatusChip(_Status status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            status.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputInfoCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('input_${_shouldExpandInput}_${_calcMode}'),
          initiallyExpanded: _shouldExpandInput,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(Icons.tune_rounded),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  '입력 정보',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                onTap: _showInputHelp,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: Colors.grey.shade700,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            _shouldExpandInput ? '계산 방식을 선택하고 값을 입력' : '값을 수정하려면 펼쳐서 다시 계산',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            _modeSelector(),
            const SizedBox(height: 10),
            _modeDescriptionCard(),
            const SizedBox(height: 14),
            ..._calculationFields(),
            const SizedBox(height: 14),
            _optionalRecordCard(),
            const SizedBox(height: 16),
            _calcButton(_calcButtonText(), onPressed: _runCurrentCalculation),
          ],
        ),
      ),
    );
  }

  String _inputHelpTitle() {
    if (_isAverageMode) return '단순 혼합 사용법';
    if (_isMixedMode) return '탱크 기준 사용법';
    return '목표 맞추기 사용법';
  }

  String _inputHelpMessage() {
    if (_isAverageMode) {
      return '고급유와 일반유를 함께 넣었을 때 평균 옥탄가를 계산합니다.\n\n예: 고급유 20L, 일반유 25L를 입력하면 두 연료가 섞인 평균값을 볼 수 있습니다.';
    }

    if (_isMixedMode) {
      return '이미 탱크에 남아 있는 연료와 이번에 넣을 연료가 섞였을 때 최종 옥탄가를 계산합니다.\n\n현재 남은 연료량, 현재 추정 옥탄가, 이번 주유량, 이번 연료 옥탄가를 입력해 주세요.';
    }

    return '원하는 목표 옥탄가에 도달하려면 새 연료를 몇 L 넣어야 하는지 계산합니다.\n\n목표 옥탄가, 현재 남은 연료량, 현재 추정 옥탄가, 넣을 연료 옥탄가를 입력해 주세요.';
  }

  void _showInputHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_inputHelpTitle()),
          content: Text(_inputHelpMessage()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Widget _modeSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _modeButton('단순 혼합', 0),
          _modeButton('탱크 기준', 1),
          _modeButton('목표 맞추기', 2),
        ],
      ),
    );
  }

  Widget _modeDescriptionCard() {
    final icon = switch (_calcMode) {
      0 => Icons.blender_outlined,
      1 => Icons.local_gas_station_outlined,
      _ => Icons.flag_outlined,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7DFDB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8B3A3A), size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _modeDescription(),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _modeDescription() {
    if (_isAverageMode) return '고급유와 일반유를 함께 넣었을 때 평균 옥탄가를 계산합니다.';
    if (_isMixedMode) return '현재 탱크에 남은 연료 상태를 반영해 최종 옥탄가를 계산합니다.';
    return '목표 옥탄가를 맞추기 위해 필요한 주유량을 계산합니다.';
  }

  List<Widget> _calculationFields() {
    if (_isAverageMode) {
      return [
        _numberField(highFuelCtrl, '고급유 주유량 (L)', hint: '예: 20'),
        const SizedBox(height: 14),
        _numberField(regFuelCtrl, '일반유 주유량 (L)', hint: '예: 25'),
      ];
    }

    if (_isMixedMode) {
      return [
        _numberField(beforeLiterCtrl, '현재 남은 연료량 (L)', hint: '예: 10'),
        const SizedBox(height: 14),
        _numberField(beforeOctaneCtrl, '현재 추정 옥탄가', hint: '예: 92'),
        const SizedBox(height: 14),
        _numberField(addLiterCtrl, '이번에 넣을 주유량 (L)', hint: '예: 30'),
        const SizedBox(height: 14),
        _numberField(addOctaneCtrl, '이번에 넣을 연료 옥탄가', hint: '예: 98'),
        const SizedBox(height: 14),
        _numberField(mixTankCtrl, '탱크 용량 (L)', hint: '차량 설정값 사용 가능'),
      ];
    }

    return [
      _numberField(targetOctaneCtrl, '목표 옥탄가', hint: '예: 95'),
      const SizedBox(height: 14),
      _numberField(targetCurrentLiterCtrl, '현재 남은 연료량 (L)', hint: '예: 15'),
      const SizedBox(height: 14),
      _numberField(targetCurrentOctaneCtrl, '현재 추정 옥탄가', hint: '예: 92'),
      const SizedBox(height: 14),
      _numberField(targetFuelOctaneCtrl, '넣을 연료 옥탄가', hint: '예: 98'),
    ];
  }

  String _calcButtonText() {
    if (_isAverageMode) return '평균 옥탄가 계산';
    if (_isMixedMode) return '최종 옥탄가 계산';
    return '필요 주유량 계산';
  }

  Widget _modeButton(String text, int mode) {
    final selected = _calcMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _calcMode = mode;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF8B3A3A) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 13,
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
        _sectionTitle('?낅젰'),
        const SizedBox(height: 12),
        _panelCard(
          children: [
            _numberField(highFuelCtrl, '고급유 주유량 (L)', hint: '예: 20'),
            const SizedBox(height: 14),
            _numberField(regFuelCtrl, '일반유 주유량 (L)', hint: '예: 25'),
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
        _sectionTitle('?낅젰'),
        const SizedBox(height: 12),
        _panelCard(
          children: [
            _numberField(beforeLiterCtrl, '기존 연료량 (L)', hint: '예: 10'),
            const SizedBox(height: 14),
            _numberField(beforeOctaneCtrl, '기존 연료 옥탄가 (RON)', hint: '예: 95'),
            const SizedBox(height: 14),
            _numberField(addLiterCtrl, '추가 주유량 (L)', hint: '예: 30'),
            const SizedBox(height: 14),
            _numberField(addOctaneCtrl, '추가 연료 옥탄가 (RON)', hint: '예: 98'),
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

  Widget _optionalRecordCard() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7DFDB)),
        ),
        child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: const Icon(Icons.receipt_long_rounded),
            title: const Text(
              '기록 정보',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: const Text('단가, 총액, 메모 선택 입력'),
            children: [
              _numberField(priceCtrl, '리터당 단가 (원)', hint: '예: 1890'),
              const SizedBox(height: 14),
              _numberField(totalCostCtrl, '총 주유 금액 (원)', hint: '예: 70000'),
              const SizedBox(height: 14),
              TextField(
                controller: memoCtrl,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  labelText: '메모',
                  hintText: '예: 노킹 없음, 출력 괜찮음',
                ),
              ),
            ]),
      ),
    );
  }

  double? _diffFromLatestRecord(double value) {
    final box = Hive.box<OctaneLog>('octane_logs');
    if (box.isEmpty) return null;
    return value - box.values.last.result;
  }

  Widget _changePill(double value) {
    final diff = _diffFromLatestRecord(value);
    if (diff == null) {
      return _mutedPill('첫 기록 후보', Icons.fiber_new_rounded);
    }

    final isUp = diff >= 0;
    final color = isUp ? const Color(0xFF2C83C8) : const Color(0xFFC3363B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 3),
          Text(
            '${isUp ? '+' : '-'}${diff.abs().toStringAsFixed(2)} (최근 기록 대비)',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mutedPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 16),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _unsavedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8C98D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFF9A6500),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '⚠ 아직 기록에 저장되지 않았습니다.\n기록 저장 버튼을 눌러야 통계 및 그래프에 반영됩니다.',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.28), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetResultPanel() {
    final color = _targetImpossible ? Colors.red : const Color(0xFF2E7D32);
    final icon = _targetImpossible
        ? Icons.warning_amber_rounded
        : Icons.local_gas_station_rounded;
    final label = _targetImpossible ? '도달 불가' : '필요 주유량';
    final value = _targetRequiredLiter == null
        ? '--'
        : '${_targetRequiredLiter!.toStringAsFixed(1)}L';
    final resultOctane = _targetResultOctane;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                _statusBadge(label, icon, color),
                const Spacer(),
                if (resultOctane != null) _changePill(resultOctane),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              '필요 주유량',
              style: TextStyle(
                color: Color(0xFF5F504C),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: Colors.black87,
              ),
            ),
            if (!_targetImpossible && _targetRequiredLiter != null) ...[
              const SizedBox(height: 8),
              _unsavedNotice(),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _targetComment ?? '',
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
            if (!_targetImpossible && _targetRequiredLiter != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveTargetLog,
                icon: const Icon(Icons.save_rounded),
                label: const Text('기록 저장'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultPanel(
    double value,
    String comment, {
    VoidCallback? onSave,
  }) {
    final st = _status(value);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  _statusBadge(st.label, st.icon, st.color),
                  const Spacer(),
                  _changePill(value),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                '계산 결과',
                style: TextStyle(
                  color: Color(0xFF5F504C),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: value - 0.45, end: value),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) {
                  return Text(
                    animatedValue.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
              if (onSave != null && value > 0) ...[
                const SizedBox(height: 8),
                _unsavedNotice(),
              ],
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
              if (onSave != null && value > 0) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('기록 저장'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _tankInsightCard(_TankInsight insight) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(insight.icon, size: 18, color: insight.color),
                const SizedBox(width: 8),
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: insight.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: insight.progress,
                minHeight: 10,
                backgroundColor: insight.color.withOpacity(0.10),
                valueColor: AlwaysStoppedAnimation<Color>(insight.color),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              insight.message,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
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
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
            const SizedBox(height: 22),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _statItem('평균', avg, Colors.black87)),
                  const VerticalDivider(color: Color(0xFFE7DFDB), width: 1),
                  Expanded(
                    child: _statItem(
                      '최고',
                      max,
                      const Color(0xFF8B2F32),
                    ),
                  ),
                  const VerticalDivider(color: Color(0xFFE7DFDB), width: 1),
                  Expanded(
                    child: _statItem(
                      '최저',
                      min,
                      const Color(0xFF2C83C8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '총 기록 ${logs.length}개',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String title, double value, Color valueColor) {
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
          style: TextStyle(
            color: valueColor,
            fontSize: 22,
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
              '저장된 기록이 없습니다.',
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
            _buildStatsCard(logs),
            const SizedBox(height: 14),
            _buildOctaneChart(logs),
            const SizedBox(height: 14),
            _targetMatchCard(logs.last),
            const SizedBox(height: 14),
            _historyListCard(logs),
          ],
        );
      },
    );
  }

  Widget _buildOctaneChart(List<OctaneLog> logs) {
    if (logs.isEmpty) return const SizedBox.shrink();
    final car = Hive.box<CarProfile>('car_profile').get('main');
    final target = car?.recommendedOctane;
    final chartLogs = logs.length > 5 ? logs.sublist(logs.length - 5) : logs;

    final spots = List.generate(
      chartLogs.length,
          (i) => FlSpot(i.toDouble(), chartLogs[i].result),
    );

    final latest = chartLogs.last.result;
    final prev = chartLogs.length > 1 ? chartLogs[chartLogs.length - 2].result : latest;
    final diff = latest - prev;
    final displayValue = _touchedValue ?? latest;
    final selectedLabel = _selectedSpotIndex != null
        ? '${_selectedSpotIndex! + 1}번째 기록'
        : '최신 기록';
    final status = _status(displayValue);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '기록 추세',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF151823),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: (diff >= 0
                      ? const Color(0xFF2C83C8)
                      : const Color(0xFFC3363B))
                      .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      diff >= 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 17,
                      color: diff >= 0
                          ? const Color(0xFF2C83C8)
                          : const Color(0xFFC3363B),
                    ),
                    const SizedBox(width: 3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${diff >= 0 ? '+' : '-'}${diff.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: diff >= 0
                                ? const Color(0xFF2C83C8)
                                : const Color(0xFFC3363B),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '최근 변화',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Color(0xFF151823),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _softStatusChip(status),
          const SizedBox(height: 12),
          Text(
            _touchedValue != null ? '선택한 기록  $selectedLabel' : '현재 위치: 최신 기록',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 218,
            child: LineChart(
              LineChartData(
                minX: spots.length == 1 ? -0.5 : 0,
                maxX: spots.length == 1 ? 0.5 : (spots.length - 1).toDouble(),
                minY: 90,
                maxY: 99,
                clipData: const FlClipData.all(),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= chartLogs.length) {
                          return const SizedBox.shrink();
                        }
                        final isFirst = index == 0;
                        final isLast = index == chartLogs.length - 1;
                        final sameAsPrevious = index > 0 &&
                            _dateOnly(chartLogs[index].time) ==
                                _dateOnly(chartLogs[index - 1].time);
                        if (!isFirst && !isLast && sameAsPrevious) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${chartLogs[index].time.month}/${chartLogs[index].time.day}',
                            style: const TextStyle(
                              color: Color(0xFF343A46),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.16),
                      strokeWidth: 1,
                    );
                  },
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (target != null)
                      HorizontalLine(
                        y: target,
                        color: const Color(0xFFC83E43).withOpacity(0.42),
                        strokeWidth: 1,
                        dashArray: [4, 3],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.centerRight,
                          labelResolver: (_) =>
                              '${target.toStringAsFixed(0)} (목표)',
                          style: const TextStyle(
                            color: Color(0xFFC83E43),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
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
                    color: const Color(0xFFC83E43),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isSelected = _selectedSpotIndex == index;
                        final isLatest = index == spots.length - 1;

                        if (isSelected) {
                          return FlDotCirclePainter(
                            radius: 7.5,
                            color: const Color(0xFFC83E43),
                            strokeWidth: 4,
                            strokeColor: Colors.white,
                          );
                        }

                        if (isLatest) {
                          return FlDotCirclePainter(
                            radius: 5.5,
                            color: const Color(0xFFC83E43),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }

                        return FlDotCirclePainter(
                          radius: 4.5,
                          color: Colors.white,
                          strokeWidth: 2.6,
                          strokeColor: const Color(0xFFC83E43),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFC83E43).withOpacity(0.09),
                      applyCutOffY: true,
                      cutOffY: 90,
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

  Widget _targetMatchCard(OctaneLog latest) {
    final status = _status(latest.result);
    final brand = Theme.of(context).colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '목표 맞추기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: brand.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.flag_rounded, color: brand, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dateOnly(latest.time),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _statusChip(status),
                    ],
                  ),
                ),
                Text(
                  latest.result.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF151823),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _softStatusChip(_Status st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: st.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        st.label,
        style: TextStyle(
          color: st.color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _historyListCard(List<OctaneLog> logs) {
    final recent = logs.reversed.take(3).toList();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '기록 목록',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(recent.length, (index) {
              return _compactHistoryItem(
                recent[index],
                previous: _previousForRecent(logs, index),
                indexFromTop: index,
              );
            }),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showAllHistory(logs),
              icon: const Icon(Icons.list_rounded),
              label: const Text('전체 기록 보기'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: const Color(0xFF312827),
                side: const BorderSide(color: Color(0xFFE0D8D4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactHistoryItem(
    OctaneLog log, {
    required double? previous,
    required int indexFromTop,
  }) {
    final double diff = previous == null ? 0.0 : log.result - previous;
    final isUp = diff >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE8E1DD)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onLongPress: () => _confirmDeleteLog(indexFromTop),
          onTap: () {
            final box = Hive.box<OctaneLog>('octane_logs');
            final logKey = box.keyAt(box.length - 1 - indexFromTop);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryDetailPage(log: log, logKey: logKey),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dateTimeShort(log.time),
                    style: const TextStyle(
                      color: Color(0xFF343A46),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  log.result.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF151823),
                  ),
                ),
                const SizedBox(width: 10),
                _diffPill(diff, isUp),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _diffPill(double diff, bool isUp) {
    final color = isUp ? const Color(0xFF2C83C8) : const Color(0xFFC3363B);
    final icon = isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 2),
          Text(
            '${isUp ? '+' : '-'}${diff.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllHistory(List<OctaneLog> logs) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final recent = logs.reversed.toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: List.generate(recent.length, (index) {
            return _compactHistoryItem(
              recent[index],
              previous: _previousForRecent(logs, index),
              indexFromTop: index,
            );
          }),
        );
      },
    );
  }

  double? _previousForRecent(List<OctaneLog> logs, int indexFromTop) {
    final originalIndex = logs.length - 1 - indexFromTop;
    if (originalIndex <= 0) return null;
    return logs[originalIndex - 1].result;
  }

  String _dateOnly(DateTime time) {
    return '${time.year}.${time.month.toString().padLeft(2, '0')}.${time.day.toString().padLeft(2, '0')}';
  }

  String _dateTimeShort(DateTime time) {
    return '${_dateOnly(time)} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _historyItem(OctaneLog log, {required int indexFromTop}) {
    final st = _status(log.result);
    final brand = Theme.of(context).colorScheme.primary;

    final typeTitle = _typeTitle(log.type);
    final typeIcon = switch (log.type) {
      'average' => Icons.calculate_rounded,
      'target' => Icons.flag_rounded,
      _ => Icons.alt_route_rounded,
    };

    final date =
        '${log.time.year}.${log.time.month.toString().padLeft(2, '0')}.${log.time.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onLongPress: () => _confirmDeleteLog(indexFromTop),
        onTap: () {
          final box = Hive.box<OctaneLog>('octane_logs');
          final logKey = box.keyAt(box.length - 1 - indexFromTop);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HistoryDetailPage(log: log, logKey: logKey),
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
        return '단순 혼합';
      case 'mixed':
        return '탱크 기준';
      case 'target':
        return '목표 맞추기';
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

  void _fillCarForm(CarProfile car) {
    carNameCtrl.text = car.name;
    carYearCtrl.text = car.year.toString();
    carRecCtrl.text = car.recommendedOctane.toString();
    carWarnCtrl.text = car.warningOctane.toString();
    carTankCtrl.text = car.tankCapacity?.toString() ?? '';
  }

  Widget _buildCarTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<CarProfile>('car_profile').listenable(),
      builder: (context, Box<CarProfile> box, _) {
        final car = box.get('main');
        if (car != null && carNameCtrl.text.isEmpty) {
          _fillCarForm(car);
        }

        return ListView(
          padding: _listPadding(context),
          children: [
            _sectionTitle('설정'),
            const SizedBox(height: 12),
            _settingsGroupLabel('차량'),
            const SizedBox(height: 8),
            _vehicleSettingsCard(box, car),
            const SizedBox(height: 16),
            _settingsGroupLabel('도움말'),
            const SizedBox(height: 8),
            _usageGuideCard(),
            const SizedBox(height: 16),
            _contactCard(),
            const SizedBox(height: 16),
            _settingsGroupLabel('정보'),
            const SizedBox(height: 8),
            _updateHistoryCard(),
          ],
        );
      },
    );
  }

  Widget _settingsGroupLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _vehicleSettingsCard(Box<CarProfile> box, CarProfile? car) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: car == null,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(Icons.directions_car_outlined),
          title: const Text(
            '차량 설정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            car == null
                ? '권장 옥탄가와 경고 기준을 저장해 주세요'
                : '${car.name} (${car.year})  권장 ${car.recommendedOctane} / 경고 ${car.warningOctane}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            if (car == null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '아직 저장된 차량 정보가 없습니다.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (car != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE7DFDB)),
                ),
                child: Text(
                  '${car.name} (${car.year})  권장 ${car.recommendedOctane} / 경고 ${car.warningOctane}'
                  '${car.tankCapacity != null ? '  탱크 ${car.tankCapacity}L' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE7DFDB)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: carNameCtrl,
                    decoration: const InputDecoration(
                      labelText: '차량명',
                      hintText: '예: 아반떼 N',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _numberField(carYearCtrl, '연식', hint: '예: 2023'),
                  const SizedBox(height: 14),
                  _numberField(carRecCtrl, '권장 옥탄가', hint: '예: 95'),
                  const SizedBox(height: 14),
                  _numberField(carWarnCtrl, '경고 기준 옥탄가', hint: '예: 91'),
                  const SizedBox(height: 14),
                  _numberField(carTankCtrl, '탱크 용량 (L)', hint: '예: 50'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                final name = carNameCtrl.text.trim();
                final year = int.tryParse(carYearCtrl.text.trim());
                final recommend = double.tryParse(carRecCtrl.text.trim());
                final warning = double.tryParse(carWarnCtrl.text.trim());
                final tankText = carTankCtrl.text.trim();
                final tank = tankText.isEmpty ? null : double.tryParse(tankText);

                String? error;
                final currentYear = DateTime.now().year;
                if (name.isEmpty) {
                  error = '차량명을 입력해 주세요.';
                } else if (year == null || year < 1980 || year > currentYear + 1) {
                  error = '연식은 1980~${currentYear + 1} 사이로 입력해 주세요.';
                } else if (recommend == null || warning == null) {
                  error = '권장 옥탄가와 경고 기준을 모두 입력해 주세요.';
                } else if (warning > recommend) {
                  error = '경고 기준은 권장 옥탄가보다 높을 수 없습니다.';
                } else if (tank != null && tank <= 0) {
                  error = '탱크 용량은 0보다 커야 합니다.';
                }

                if (error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
                  return;
                }

                _saveCarProfile(
                  name: name,
                  year: year!,
                  recommend: recommend!,
                  warning: warning!,
                  tank: tank,
                );

                FocusScope.of(context).unfocus();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('차량 정보를 저장했습니다.')));
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('차량 정보 저장'),
            ),
            if (car != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _confirmDeleteCar(box),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('저장된 차량 삭제'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openContactEmail() async {
    AnalyticsService.log('send_email_inquiry');
    final uri = Uri(
      scheme: 'mailto',
      path: 'bgpoilkj@naver.com',
      queryParameters: {
        'subject': '고급유노트 문의',
      },
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_) {
      // Fall back to copying the address below.
    }

    await Clipboard.setData(const ClipboardData(text: 'bgpoilkj@naver.com'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('메일 앱을 열 수 없어 이메일 주소를 복사했습니다.')),
    );
  }

  Widget _usageGuideCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(Icons.help_outline_rounded),
          title: const Text(
            '사용 방법',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            '계산과 기록 흐름 안내',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            _usageStep(
              icon: Icons.directions_car_outlined,
              title: '차량 기준 설정',
              message: '권장 옥탄가와 경고 기준을 저장하면 계산 결과를 내 차량 기준으로 판단합니다.',
            ),
            const SizedBox(height: 10),
            _usageStep(
              icon: Icons.calculate_outlined,
              title: '계산하기',
              message: '단순 혼합, 탱크 기준, 목표 맞추기 중 상황에 맞는 방식을 선택하고 값을 입력합니다.',
            ),
            const SizedBox(height: 10),
            _usageStep(
              icon: Icons.save_outlined,
              title: '필요할 때 기록 저장',
              message: '계산만으로는 기록이 저장되지 않습니다. 결과를 남기고 싶을 때 기록 저장을 눌러주세요.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _usageStep({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7DFDB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8B3A3A), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF151823),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(Icons.mail_outline_rounded),
          title: const Text(
            '문의',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            'bgpoilkj@naver.com',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE7DFDB)),
              ),
              child: Text(
                '오류 제보, 개선 의견, 차량 기준 관련 문의를 보내주세요.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _openContactEmail,
              icon: const Icon(Icons.mail_rounded),
              label: const Text('메일 보내기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _updateHistoryCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(Icons.new_releases_outlined),
          title: const Text(
            '업데이트 내역',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            '최근 개선 사항',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: const [
            _ReleaseNote(
              version: 'v1.0.2',
              items: [
                '계산 결과와 추천 전략을 화면 상단에 배치',
                '계산 결과가 자동으로 기록되지 않도록 변경',
                '저장 전 상태와 최근 기록 대비 변화량 표시',
                '첫 실행 시 차량 설정 가이드 추가',
                '설정, 문의, 사용 방법 메뉴 정리',
              ],
            ),
            SizedBox(height: 12),
            _ReleaseNote(
              version: 'v1.0.1',
              items: [
                '차량별 권장/경고 옥탄가 설정 추가',
                '최근 기록 통계와 그래프 화면 개선',
              ],
            ),
          ],
        ),
      ),
    );
  }
}




class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: brand.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: brand, size: 38),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF151823),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}



class _ReleaseNote extends StatelessWidget {
  final String version;
  final List<String> items;

  const _ReleaseNote({
    required this.version,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7DFDB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            version,
            style: const TextStyle(
              color: Color(0xFF8B3A3A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '- ',
                    style: TextStyle(
                      color: Color(0xFF343A46),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}




class _Status {
  final String label;
  final String message;
  final IconData icon;
  final Color color;

  const _Status(this.label, this.message, this.icon, this.color);
}










class _TankInsight {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final double progress;

  const _TankInsight({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.progress,
  });
}

