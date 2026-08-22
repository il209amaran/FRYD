class CurrencyOption {
  const CurrencyOption(this.code, this.symbol, this.name);

  final String code;
  final String symbol;
  final String name;

  static const supported = [
    CurrencyOption('INR', '₹', 'Indian Rupee'),
    CurrencyOption('USD', r'$', 'US Dollar'),
    CurrencyOption('EUR', '€', 'Euro'),
    CurrencyOption('GBP', '£', 'British Pound'),
    CurrencyOption('AED', 'AED ', 'UAE Dirham'),
    CurrencyOption('SGD', r'S$', 'Singapore Dollar'),
    CurrencyOption('AUD', r'A$', 'Australian Dollar'),
    CurrencyOption('CAD', r'C$', 'Canadian Dollar'),
    CurrencyOption('JPY', '¥', 'Japanese Yen'),
  ];

  static CurrencyOption forCode(String code) => supported.firstWhere(
    (currency) => currency.code == code,
    orElse: () => supported.first,
  );
}

class BusinessSettings {
  const BusinessSettings({
    required this.businessName,
    required this.businessType,
    required this.address,
    required this.phone,
    required this.email,
    required this.country,
    required this.currencyCode,
    required this.taxRegistrationNumber,
    required this.taxEnabled,
    required this.taxName,
    required this.taxRate,
    required this.taxInclusive,
    required this.setupCompleted,
  });

  final String businessName;
  final String businessType;
  final String address;
  final String phone;
  final String email;
  final String country;
  final String currencyCode;
  final String taxRegistrationNumber;
  final bool taxEnabled;
  final String taxName;
  final double taxRate;
  final bool taxInclusive;
  final bool setupCompleted;

  CurrencyOption get currency => CurrencyOption.forCode(currencyCode);

  factory BusinessSettings.fromMap(Map<String, Object?> map) =>
      BusinessSettings(
        businessName: map['business_name'] as String,
        businessType: map['business_type'] as String,
        address: map['address'] as String,
        phone: map['phone'] as String,
        email: map['email'] as String,
        country: map['country'] as String,
        currencyCode: map['currency_code'] as String,
        taxRegistrationNumber: map['tax_registration_number'] as String,
        taxEnabled: map['tax_enabled'] == 1,
        taxName: map['tax_name'] as String,
        taxRate: (map['tax_rate'] as num).toDouble(),
        taxInclusive: map['tax_inclusive'] == 1,
        setupCompleted: map['setup_completed'] == 1,
      );

  Map<String, Object?> toMap() => {
    'id': 1,
    'business_name': businessName.trim(),
    'business_type': businessType,
    'address': address.trim(),
    'phone': phone.trim(),
    'email': email.trim(),
    'country': country,
    'currency_code': currencyCode,
    'tax_registration_number': taxRegistrationNumber.trim(),
    'tax_enabled': taxEnabled ? 1 : 0,
    'tax_name': taxName.trim(),
    'tax_rate': taxRate,
    'tax_inclusive': taxInclusive ? 1 : 0,
    'setup_completed': setupCompleted ? 1 : 0,
  };

  BusinessSettings copyWith({
    String? businessName,
    String? businessType,
    String? address,
    String? phone,
    String? email,
    String? country,
    String? currencyCode,
    String? taxRegistrationNumber,
    bool? taxEnabled,
    String? taxName,
    double? taxRate,
    bool? taxInclusive,
    bool? setupCompleted,
  }) => BusinessSettings(
    businessName: businessName ?? this.businessName,
    businessType: businessType ?? this.businessType,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    country: country ?? this.country,
    currencyCode: currencyCode ?? this.currencyCode,
    taxRegistrationNumber: taxRegistrationNumber ?? this.taxRegistrationNumber,
    taxEnabled: taxEnabled ?? this.taxEnabled,
    taxName: taxName ?? this.taxName,
    taxRate: taxRate ?? this.taxRate,
    taxInclusive: taxInclusive ?? this.taxInclusive,
    setupCompleted: setupCompleted ?? this.setupCompleted,
  );
}
