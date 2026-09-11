enum BrokerProvider {
  mofid,
  iPasargad,
}

extension BrokerProviderLabel on BrokerProvider {
  String get label => switch (this) {
        BrokerProvider.mofid => 'مفید',
        BrokerProvider.iPasargad => 'آی‌پاسارگاد',
      };
}
