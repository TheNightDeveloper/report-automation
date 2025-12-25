import 'package:hive/hive.dart';

part 'technique.g.dart';

@HiveType(typeId: 10)
class Technique {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int order;

  @HiveField(3)
  final String? description;

  Technique({
    required this.id,
    required this.name,
    required this.order,
    this.description,
  });

  Technique copyWith({
    String? id,
    String? name,
    int? order,
    String? description,
  }) {
    return Technique(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'order': order, 'description': description};
  }

  factory Technique.fromJson(Map<String, dynamic> json) {
    return Technique(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Technique &&
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
