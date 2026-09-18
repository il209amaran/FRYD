import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/business_settings.dart';
import '../../../models/receipt_settings.dart';
import '../data/business_settings_repository.dart';
import '../data/receipt_settings_repository.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({this.setupMode = false, super.key});

  final bool setupMode;

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  static const _types = [
    'Restaurant',
    'Cafe',
    'Bakery',
    'Takeaway',
    'Retail',
    'Salon',
    'Other',
  ];
  static const _countries = [
    'India',
    'United States',
    'United Kingdom',
    'United Arab Emirates',
    'Singapore',
    'Australia',
    'Canada',
    'Japan',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _repository = BusinessSettingsRepository();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _taxNumber = TextEditingController();
  final _taxName = TextEditingController();
  final _taxRate = TextEditingController();
  final _receiptHeader = TextEditingController();
  final _receiptFooter = TextEditingController();
  String _type = _types.first;
  String _country = _countries.first;
  String _currency = 'INR';
  bool _loading = true;
  bool _saving = false;
  BusinessSettings? _settings;
  ReceiptSettings? _receiptSettings;
  bool _taxEnabled = false;
  bool _taxInclusive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _repository.get(),
      ReceiptSettingsRepository().get(),
    ]);
    final settings = results[0] as BusinessSettings;
    final receipt = results[1] as ReceiptSettings;
    if (!mounted) return;
    _settings = settings;
    _name.text = widget.setupMode && settings.businessName == 'Kanakki'
        ? ''
        : settings.businessName;
    _address.text = settings.address;
    _phone.text = settings.phone;
    _email.text = settings.email;
    _taxNumber.text = settings.taxRegistrationNumber;
    _taxName.text = settings.taxName;
    _taxRate.text = settings.taxRate.toString();
    _receiptHeader.text = receipt.header;
    _receiptFooter.text = receipt.footer;
    _receiptSettings = receipt;
    setState(() {
      _type = settings.businessType;
      _country = settings.country;
      _currency = settings.currencyCode;
      _taxEnabled = settings.taxEnabled;
      _taxInclusive = settings.taxInclusive;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _settings == null) return;
    setState(() => _saving = true);
    final updated = _settings!.copyWith(
      businessName: _name.text,
      businessType: _type,
      address: _address.text,
      phone: _phone.text,
      email: _email.text,
      country: _country,
      currencyCode: _currency,
      taxRegistrationNumber: _taxNumber.text,
      taxEnabled: widget.setupMode ? _taxEnabled : null,
      taxName: widget.setupMode ? _taxName.text : null,
      taxRate: widget.setupMode
          ? (double.tryParse(_taxRate.text.trim()) ?? 0)
          : null,
      taxInclusive: widget.setupMode ? _taxInclusive : null,
      setupCompleted: true,
    );
    try {
      // Update the formatter before the repository broadcasts the settings
      // change so offstage Billing/Product pages rebuild with the new symbol.
      CurrencyFormatter.update(updated);
      await _repository.save(updated);
      if (widget.setupMode && _receiptSettings != null) {
        await ReceiptSettingsRepository().save(
          _receiptSettings!.copyWith(
            header: _receiptHeader.text,
            footer: _receiptFooter.text,
          ),
        );
      }
      if (!mounted) return;
      if (widget.setupMode) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (_) => false,
        );
      } else {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _taxNumber.dispose();
    _taxName.dispose();
    _taxRate.dispose();
    _receiptHeader.dispose();
    _receiptFooter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.setupMode
        ? null
        : AppBar(title: const Text('Business Profile')),
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.setupMode
                              ? 'Welcome to Kanakki'
                              : 'Business Profile',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (widget.setupMode) ...[
                          const SizedBox(height: 8),
                          const Text("Let's set up your business."),
                        ],
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Business Name',
                          ),
                          validator: _required,
                        ),
                        if (widget.setupMode) ...[
                          const SizedBox(height: 22),
                          Text(
                            'Tax Configuration',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _taxEnabled,
                            title: const Text('Enable Tax'),
                            onChanged: (value) =>
                                setState(() => _taxEnabled = value),
                          ),
                          if (_taxEnabled) ...[
                            TextFormField(
                              controller: _taxName,
                              decoration: const InputDecoration(
                                labelText: 'Tax Name',
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _taxRate,
                              decoration: const InputDecoration(
                                labelText: 'Tax Percentage',
                                suffixText: '%',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                final rate = double.tryParse(value ?? '');
                                return rate == null || rate < 0 || rate > 100
                                    ? 'Enter a percentage from 0 to 100.'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Exclusive'),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Inclusive'),
                                ),
                              ],
                              selected: {_taxInclusive},
                              onSelectionChanged: (selection) => setState(
                                () => _taxInclusive = selection.single,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Text(
                            'Receipt Details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _receiptHeader,
                            decoration: const InputDecoration(
                              labelText: 'Receipt Header',
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _receiptFooter,
                            decoration: const InputDecoration(
                              labelText: 'Receipt Footer',
                            ),
                            maxLines: 3,
                          ),
                        ],
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _type,
                          decoration: const InputDecoration(
                            labelText: 'Business Type',
                          ),
                          items: _types
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _type = value!),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _address,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth < 660
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 14) / 2;
                            return Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                SizedBox(
                                  width: width,
                                  child: TextFormField(
                                    controller: _phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone',
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: TextFormField(
                                    controller: _email,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _country,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                          ),
                          items: _countries
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _country = value!),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _currency,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                          ),
                          items: CurrencyOption.supported
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value.code,
                                  child: Text(
                                    '${value.code} — ${value.symbol}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _currency = value!),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _taxNumber,
                          decoration: const InputDecoration(
                            labelText: 'Tax / Registration Number',
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              widget.setupMode ? 'Continue' : 'Save Profile',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
}
