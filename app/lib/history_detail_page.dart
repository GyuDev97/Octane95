import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'model/car_profile.dart';
import 'model/octane_log.dart';

class HistoryDetailPage extends StatelessWidget {
  final OctaneLog log;

  const HistoryDetailPage({super.key, required this.log});

  static const Map<String, String> inputLabelMap = {
    'highLiter': '고급유 주유량 (L)',
    'regularLiter': '일반유 주유량 (L)',
    'beforeLiter': '기존 연료량 (L)',
    'beforeOctane': '기존 연료 옥탄가',
    'addLiter': '추가 주유량 (L)',
    'addOctane': '추가 연료 옥탄가',
    'tankCapacity': '탱크 용량 (L)',
  };

  @override
  Widget build(BuildContext context) {
    final status = _status(log.result);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 상세'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(
            title: '계산 정보',
            children: [
              _row('계산 방식', log.type == 'average' ? '평균 계산' : '혼합 계산'),
              _row(
                '계산 시각',
                '${log.time.year}.${log.time.month.toString().padLeft(2, '0')}.${log.time.day.toString().padLeft(2, '0')} '
                '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoCard(
            title: '입력값',
            children: log.inputs.entries.map((entry) {
              final label = inputLabelMap[entry.key] ?? entry.key;
              return _row(label, entry.value.toString());
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  _DetailStatus _status(double value) {
    final car = Hive.box<CarProfile>('car_profile').get('main');
    final recommend = car?.recommendedOctane ?? 95;
    final warning = car?.warningOctane ?? 91;

    if (value >= recommend) {
      return const _DetailStatus(
        '최적',
        '차량 기준에서 권장 옥탄가를 충족한 상태입니다.',
        Colors.green,
      );
    } else if (value >= warning) {
      return const _DetailStatus(
        '보통',
        '일상 주행에는 무리가 없지만 다음 주유에서 보강하면 더 좋습니다.',
        Colors.orange,
      );
    } else {
      return const _DetailStatus(
        '주의',
        '노킹 가능성을 줄이기 위해 고부하 주행을 피하고 옥탄가를 보강해 주세요.',
        Colors.red,
      );
    }
  }
}

class _DetailStatus {
  final String label;
  final String message;
  final Color color;

  const _DetailStatus(this.label, this.message, this.color);
}
