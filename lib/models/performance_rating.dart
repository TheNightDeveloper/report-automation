import 'package:hive/hive.dart';

part 'performance_rating.g.dart';

@HiveType(typeId: 11)
class PerformanceRating {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int order;

  @HiveField(3)
  final String? color; // رنگ برای نمایش در UI (hex format)

  PerformanceRating({
    required this.id,
    required this.name,
    required this.order,
    this.color,
  });

  PerformanceRating copyWith({
    String? id,
    String? name,
    int? order,
    String? color,
  }) {
    return PerformanceRating(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'order': order, 'color': color};
  }

  factory PerformanceRating.fromJson(Map<String, dynamic> json) {
    return PerformanceRating(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      color: json['color'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerformanceRating &&
        other.id == id &&
        other.name == name &&
        other.order == order &&
        other.color == color;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ order.hashCode ^ color.hashCode;
  }
}
