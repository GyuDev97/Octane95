import 'package:flutter/material.dart';
import 'model/octane_log.dart';

class HistoryDetailPage extends StatelessWidget {
  final OctaneLog log;

  const HistoryDetailPage({super.key, required this.log});
  static const Map<String, String> inputLabelMap = {
    "highLiter": "고급유 주유량 (L)",
    "regularLiter": "일반유 주유량 (L)",
    "beforeLiter": "기존 연료 잔량 (L)",
    "beforeOctane": "기존 연료 옥탄가",
    "addLiter": "추가 주유량 (L)",
    "addOctane": "추가 연료 옥탄가",
  };

  @override
  Widget build(BuildContext context) {
    final status = _status(log.result);

    return Scaffold(
      appBar: AppBar(
        title: const Text("기록 상세"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(
            title: "계산 정보",
            children: [
              _row("계산 방식", log.type == "average" ? "평균 계산" : "혼합 계산"),
              _row(
                "계산 시각",
                "${log.time.year}.${log.time.month.toString().padLeft(2, '0')}.${log.time.day.toString().padLeft(2, '0')} "
                    "${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}",
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoCard(
            title: "입력 값",
            children: log.inputs.entries.map((e) {
              final label = inputLabelMap[e.key] ?? e.key;
              return _row(label, e.value.toString());
            }).toList(),
          ),

          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    log.result.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    status.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(l,
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w600))),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  _DetailStatus _status(double v) {
    if (v >= 95) {
      return _DetailStatus("안정", "일반·고속 주행 모두 무난합니다", Colors.green);
    } else if (v >= 92) {
      return _DetailStatus("보통", "일상 주행에는 문제 없습니다", Colors.orange);
    } else if (v >= 90) {
      return _DetailStatus("주의", "급가속·고회전은 자제하세요", Colors.deepOrange);
    } else {
      return _DetailStatus("위험", "노킹 가능성이 있으니 주의하세요", Colors.red);
    }
  }
}

class _DetailStatus {
  final String label;
  final String message;
  final Color color;
  _DetailStatus(this.label, this.message, this.color);
}
