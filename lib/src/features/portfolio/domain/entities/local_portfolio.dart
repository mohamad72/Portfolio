import 'package:equatable/equatable.dart';

class LocalPortfolio extends Equatable {
  const LocalPortfolio({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  LocalPortfolio copyWith({String? name}) => LocalPortfolio(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LocalPortfolio.fromJson(Map<String, dynamic> json) => LocalPortfolio(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  @override
  List<Object?> get props => <Object?>[id, name, createdAt];
}
