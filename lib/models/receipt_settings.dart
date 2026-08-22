class ReceiptSettings {
  const ReceiptSettings({
    required this.showBusinessName,
    required this.showAddress,
    required this.showPhone,
    required this.showEmail,
    required this.showTaxNumber,
    required this.header,
    required this.footer,
  });

  final bool showBusinessName;
  final bool showAddress;
  final bool showPhone;
  final bool showEmail;
  final bool showTaxNumber;
  final String header;
  final String footer;

  factory ReceiptSettings.fromMap(Map<String, Object?> map) => ReceiptSettings(
    showBusinessName: map['show_business_name'] == 1,
    showAddress: map['show_address'] == 1,
    showPhone: map['show_phone'] == 1,
    showEmail: map['show_email'] == 1,
    showTaxNumber: map['show_tax_number'] == 1,
    header: map['header'] as String,
    footer: map['footer'] as String,
  );

  Map<String, Object?> toMap() => {
    'id': 1,
    'show_business_name': showBusinessName ? 1 : 0,
    'show_address': showAddress ? 1 : 0,
    'show_phone': showPhone ? 1 : 0,
    'show_email': showEmail ? 1 : 0,
    'show_tax_number': showTaxNumber ? 1 : 0,
    'header': header.trim(),
    'footer': footer.trim(),
  };

  ReceiptSettings copyWith({
    bool? showBusinessName,
    bool? showAddress,
    bool? showPhone,
    bool? showEmail,
    bool? showTaxNumber,
    String? header,
    String? footer,
  }) => ReceiptSettings(
    showBusinessName: showBusinessName ?? this.showBusinessName,
    showAddress: showAddress ?? this.showAddress,
    showPhone: showPhone ?? this.showPhone,
    showEmail: showEmail ?? this.showEmail,
    showTaxNumber: showTaxNumber ?? this.showTaxNumber,
    header: header ?? this.header,
    footer: footer ?? this.footer,
  );
}
