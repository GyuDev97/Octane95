import 'package:hive/hive.dart';

part 'octane_log.g.dart';

@HiveType(typeId: 0)
class OctaneLog {
  @HiveField(0)
  DateTime time;

  @HiveField(1)
  String type; // average | mixed

  @HiveField(2)
  double result;

  @HiveField(3)
  Map<String, dynamic> inputs;

  @HiveField(4)
  String memo;

  OctaneLog({
    required this.time,
    required this.type,
    required this.result,
    required this.inputs,
    this.memo = "",
  });
}
