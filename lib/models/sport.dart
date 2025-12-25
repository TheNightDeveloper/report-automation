import 'package:hive/hive.dart';
import 'level.dart';
import 'performance_rating.dart';

part 'sport.g.dart';

@HiveType(typeId: 8)
class Sport {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final List<Level> levels;

  @HiveField(4)
  final List<PerformanceRating> performanceRatings;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final bool isDefault; // آیا این رشته پیش‌فرض است (مثل شنا)

  Sport({
    required this.id,
    required this.name,
    this.description,
    required this.levels,
    required this.performanceRatings,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  Sport copyWith({
    String? id,
    String? name,
    String? description,
    List<Level>? levels,
    List<PerformanceRating>? performanceRatings,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return Sport(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      levels: levels ?? this.levels,
      performanceRatings: performanceRatings ?? this.performanceRatings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'levels': levels.map((l) => l.toJson()).toList(),
      'performanceRatings': performanceRatings
          .map((pr) => pr.toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      levels: (json['levels'] as List)
          .map((l) => Level.fromJson(l as Map<String, dynamic>))
          .toList(),
      performanceRatings: (json['performanceRatings'] as List)
          .map((pr) => PerformanceRating.fromJson(pr as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sport &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        isDefault.hashCode;
  }
}
