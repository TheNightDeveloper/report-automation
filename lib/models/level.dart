import 'package:hive/hive.dart';
import 'technique.dart';

part 'level.g.dart';

@HiveType(typeId: 9)
class Level {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int order;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final List<Technique> techniques;

  Level({
    required this.id,
    required this.name,
    required this.order,
    this.description,
    required this.techniques,
  });

  Level copyWith({
    String? id,
    String? name,
    int? order,
    String? description,
    List<Technique>? techniques,
  }) {
    return Level(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      description: description ?? this.description,
      techniques: techniques ?? this.techniques,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'description': description,
      'techniques': techniques.map((t) => t.toJson()).toList(),
    };
  }

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      description: json['description'] as String?,
      techniques: (json['techniques'] as List)
          .map((t) => Technique.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Level &&
        other.id == id &&
        other.name == name &&
        other.order == order &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ order.hashCode ^ description.hashCode;
  }
}
