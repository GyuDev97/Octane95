import 'package:hive/hive.dart';

part 'car_profile.g.dart';

@HiveType(typeId: 1)
class CarProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int year;

  @HiveField(2)
  double recommendedOctane;

  @HiveField(3)
  double warningOctane;

  CarProfile({
    required this.name,
    required this.year,
    required this.recommendedOctane,
    required this.warningOctane,
  });
}