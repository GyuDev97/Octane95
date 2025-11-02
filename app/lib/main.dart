import 'package:flutter/material.dart';

void main() {
  runApp(const OctaneApp());
}

class OctaneApp extends StatelessWidget {
  const OctaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFFF4A4A);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '옥탄가 계산기',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryRed),
        useMaterial3: true,
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
  int _currentTab = 0;

  // 평균 옥탄가 계산
  final tankSizeCtrl = TextEditingController();
  final highOctaneCtrl = TextEditingController(text: "100");
  final highFuelCtrl = TextEditingController();
  final regOctaneCtrl = TextEditingController(text: "91");
  final regFuelCtrl = TextEditingController();

  // 목표 옥탄가 계산
  final targetOctaneCtrl = TextEditingController(text: "95");
  final remainCtrl = TextEditingController();
  final totalCtrl = TextEditingController();
  double mixRatio = 50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_currentTab != _tabController.index) {
        setState(() {
          _currentTab = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    tankSizeCtrl.dispose();
    highOctaneCtrl.dispose();
    highFuelCtrl.dispose();
    regOctaneCtrl.dispose();
    regFuelCtrl.dispose();
    targetOctaneCtrl.dispose();
    remainCtrl.dispose();
    totalCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // 평균 옥탄가
  double _calcAverageOctane() {
    final highO = double.tryParse(highOctaneCtrl.text) ?? 0;
    final highL = double.tryParse(highFuelCtrl.text) ?? 0;
    final regO = double.tryParse(regOctaneCtrl.text) ?? 0;
    final regL = double.tryParse(regFuelCtrl.text) ?? 0;
    final totalL = highL + regL;
    if (totalL == 0) return 0;
    return (highO * highL + regO * regL) / totalL;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 영역
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "OctaneCalc",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCustomTabBar(const Color(0xFFFF4A4A)),
                ],
              ),
            ),

            // 본문
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAverageTab(context),
                  _buildTargetTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 커스텀 탭바
  Widget _buildCustomTabBar(Color primaryRed) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton(0, "평균 옥탄가 계산", primaryRed),
          _buildTabButton(1, "목표 옥탄가 계산", primaryRed),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, Color primaryRed) {
    final bool isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? primaryRed : const Color(0xFF555555),
            ),
          ),
        ),
      ),
    );
  }

  // 평균 옥탄가 탭
  Widget _buildAverageTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("내 차량 연료탱크 크기 (L) (선택)"),
            const SizedBox(height: 8),
            _inputField(tankSizeCtrl, hint: "예: 50"),
            const SizedBox(height: 20),
            Row(
              children: const [
                Text("🚗 고급유",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            _label("옥탄가"),
            const SizedBox(height: 6),
            _inputField(highOctaneCtrl, hint: "예: 100"),
            const SizedBox(height: 10),
            _label("주유량 (L)"),
            const SizedBox(height: 6),
            _inputField(highFuelCtrl, hint: "예: 20"),
            const SizedBox(height: 20),
            Row(
              children: const [
                Text("🟥 일반유",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            _label("옥탄가"),
            const SizedBox(height: 6),
            _inputField(regOctaneCtrl, hint: "예: 91"),
            const SizedBox(height: 10),
            _label("주유량 (L)"),
            const SizedBox(height: 6),
            _inputField(regFuelCtrl, hint: "예: 15"),
            const SizedBox(height: 26),
            _primaryButton(
              text: "평균 옥탄가 계산",
              onPressed: () {
                final avg = _calcAverageOctane();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("평균 옥탄가: ${avg.toStringAsFixed(2)}"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 목표 옥탄가 탭
  Widget _buildTargetTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("목표 옥탄가"),
            const SizedBox(height: 6),
            _inputField(targetOctaneCtrl, hint: "예: 95"),
            const SizedBox(height: 14),
            _label("현재 탱크 잔여량 (L) (선택)"),
            const SizedBox(height: 6),
            _inputField(remainCtrl, hint: "예: 10"),
            const SizedBox(height: 14),
            _label("탱크 총 용량 (L)"),
            const SizedBox(height: 6),
            _inputField(totalCtrl, hint: "예: 50"),
            const SizedBox(height: 20),
            const Text(
              "혼합 비율 (%)",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Slider(
              value: mixRatio,
              min: 0,
              max: 100,
              divisions: 100,
              label: "${mixRatio.toInt()}%",
              onChanged: (v) => setState(() => mixRatio = v),
            ),
            const SizedBox(height: 8),
            const Text(
              "탱크 용량을 입력하면 비율을 추천해 드립니다.",
              style: TextStyle(color: Colors.grey, fontSize: 12.5),
            ),
            const SizedBox(height: 22),
            _primaryButton(
              text: "추천 비율 시뮬레이션",
              onPressed: () {
                _runSimulation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- 계산 로직 ----------------

  void _runSimulation(BuildContext context) {
    // 평균 탭에서 입력한 고급유/일반유 옥탄가를 그대로 가져다 씀
    final premiumOctane = double.tryParse(highOctaneCtrl.text) ?? 100.0;
    final regularOctane = double.tryParse(regOctaneCtrl.text) ?? 91.0;

    final target = double.tryParse(targetOctaneCtrl.text) ?? 0;
    final remain = double.tryParse(remainCtrl.text) ?? 0;
    final total = double.tryParse(totalCtrl.text) ?? 0;

    if (total <= 0) {
      _showMsg(context, "탱크 총 용량(L)을 먼저 입력하세요.");
      return;
    }

    final fillable = total - remain; // 넣을 수 있는 양

    if (fillable <= 0) {
      _showMsg(context, "넣을 수 있는 연료가 없습니다. (잔여량이 탱크보다 같거나 큽니다)");
      return;
    }

    // 목표가 일반유보다 낮으면 → 그냥 일반유
    if (target <= regularOctane) {
      _showMsg(
        context,
        "목표 옥탄가가 일반유(${regularOctane.toStringAsFixed(0)})보다 낮거나 같아요.\n"
            "👉 일반유 ${fillable.toStringAsFixed(2)} L 넣으면 됩니다.",
      );
      return;
    }

    // 목표가 고급유보다 높으면 → 그냥 고급유
    if (target >= premiumOctane) {
      _showMsg(
        context,
        "목표 옥탄가가 고급유(${premiumOctane.toStringAsFixed(0)})보다 높거나 같아요.\n"
            "👉 고급유 ${fillable.toStringAsFixed(2)} L 넣으면 됩니다.",
      );
      return;
    }

    //  regular < target < premium 인 경우 → 혼합해서 맞춤
    // x = fillable * (T - regular) / (premium - regular)
    final premiumL =
        fillable * (target - regularOctane) / (premiumOctane - regularOctane);
    final regularL = fillable - premiumL;

    final premiumPct = premiumL / fillable * 100;
    final regularPct = regularL / fillable * 100;

    _showMsg(
      context,
      "총 주유 가능량: ${fillable.toStringAsFixed(2)} L\n"
          "목표 옥탄가: ${target.toStringAsFixed(1)}\n\n"
          "👉 고급유: ${premiumL.toStringAsFixed(2)} L (${premiumPct.toStringAsFixed(1)}%)\n"
          "👉 일반유: ${regularL.toStringAsFixed(2)} L (${regularPct.toStringAsFixed(1)}%)",
    );
  }

  void _showMsg(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("추천 혼합 비율"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인"),
          )
        ],
      ),
    );
  }

  // ---------------- UI helper ----------------

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
        color: Color(0xFF444444),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, {String? hint}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFFF4A4A), width: 1.4),
        ),
      ),
    );
  }

  Widget _primaryButton(
      {required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4A4A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
