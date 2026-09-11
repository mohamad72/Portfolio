import 'package:equatable/equatable.dart';

import 'broker_provider.dart';

class InvestmentAccount extends Equatable {
  const InvestmentAccount({
    required this.id,
    required this.provider,
    required this.label,
  });

  final String id;
  final BrokerProvider provider;
  final String label;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'provider': provider.name,
        'label': label,
      };

  factory InvestmentAccount.fromJson(Map<String, dynamic> json) {
    final providerName = json['provider']?.toString();
    final provider = BrokerProvider.values
        .where((item) => item.name == providerName)
        .firstOrNull;
    return InvestmentAccount(
      id: json['id']?.toString() ?? '',
      provider: provider ?? BrokerProvider.iPasargad,
      label: json['label']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[id, provider, label];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
