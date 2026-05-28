// ============================================================
// Q-Route | StockCRM Uganda
// FILE: lib/features/customers/presentation/pages/new_customer_page.dart
// DESCRIPTION: On-the-go customer onboarding form for field reps.
//              Captures shop name, contact, phone, route & geolocation.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Domain Model ─────────────────────────────────────────────

class NewCustomerForm {
  String shopName;
  String contactPerson;
  String phoneNumber;
  String route;
  String? subCounty;
  String? landmark;
  double? latitude;
  double? longitude;
  CustomerType customerType;

  NewCustomerForm({
    this.shopName = '',
    this.contactPerson = '',
    this.phoneNumber = '',
    this.route = '',
    this.subCounty,
    this.landmark,
    this.latitude,
    this.longitude,
    this.customerType = CustomerType.retailShop,
  });
}

enum CustomerType { retailShop, wholesaler, kiosk, supermarket, hotel }

extension CustomerTypeLabel on CustomerType {
  String get label {
    switch (this) {
      case CustomerType.retailShop: return 'Retail Shop';
      case CustomerType.wholesaler: return 'Wholesaler';
      case CustomerType.kiosk: return 'Kiosk / Duka';
      case CustomerType.supermarket: return 'Supermarket';
      case CustomerType.hotel: return 'Hotel / Lodge';
    }
  }

  IconData get icon {
    switch (this) {
      case CustomerType.retailShop: return Icons.storefront_outlined;
      case CustomerType.wholesaler: return Icons.warehouse_outlined;
      case CustomerType.kiosk: return Icons.store_outlined;
      case CustomerType.supermarket: return Icons.shopping_cart_outlined;
      case CustomerType.hotel: return Icons.hotel_outlined;
    }
  }
}

// ── Uganda Routes (populate from Supabase in production) ─────

const List<String> kUgandaRoutes = [
  'Kikuubo Zone A',
  'Kikuubo Zone B',
  'Nakasero Market',
  'Owino Market',
  'Kalerwe Zone',
  'Wandegeya Route',
  'Ntinda – Kiwatule',
  'Kireka – Namugongo',
  'Nansana Route',
  'Entebbe Road',
  'Masaka Road',
  'Jinja Road East',
  'Mbarara Route',
  'Gulu North Route',
];

// ── Page ──────────────────────────────────────────────────────

class NewCustomerPage extends StatefulWidget {
  const NewCustomerPage({super.key});

  @override
  State<NewCustomerPage> createState() => _NewCustomerPageState();
}

class _NewCustomerPageState extends State<NewCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _form = NewCustomerForm();
  bool _isSaving = false;
  bool _gpsLoading = false;

  // Controllers
  final _shopNameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  // ── GPS Tag ──────────────────────────────────────────────────

  Future<void> _captureGPS() async {
    setState(() => _gpsLoading = true);
    // TODO: Integrate geolocator package
    // final pos = await Geolocator.getCurrentPosition();
    await Future.delayed(const Duration(seconds: 2)); // Simulate
    setState(() {
      _form.latitude = 0.3476;   // mock: Kampala latitude
      _form.longitude = 32.5825; // mock: Kampala longitude
      _gpsLoading = false;
    });
    HapticFeedback.lightImpact();
    _showSnack('📍 Location captured!', success: true);
  }

  // ── Save ─────────────────────────────────────────────────────

  Future<void> _saveCustomer() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnack('Please fill all required fields.', success: false);
      return;
    }
    _formKey.currentState?.save();

    setState(() => _isSaving = true);
    // TODO: Insert into Supabase → customers table
    // await supabase.from('customers').insert({
    //   'shop_name': _form.shopName,
    //   'contact_person': _form.contactPerson,
    //   'phone_number': _form.phoneNumber,
    //   'route': _form.route,
    //   'customer_type': _form.customerType.name,
    //   'latitude': _form.latitude,
    //   'longitude': _form.longitude,
    //   'landmark': _form.landmark,
    //   'created_by': supabase.auth.currentUser?.id,
    // });
    await Future.delayed(const Duration(seconds: 2)); // Simulate network
    setState(() => _isSaving = false);

    _showSnack('✅ ${_form.shopName} registered successfully!', success: true);
    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? const Color(0xFF276749) : const Color(0xFFE53E3E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('🏪 Shop Details', 'Basic identification info'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _shopNameCtrl,
              label: 'Shop Name *',
              hint: 'e.g. Nalubega General Shop',
              icon: Icons.storefront_outlined,
              inputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Shop name is required' : null,
              onSaved: (v) => _form.shopName = v?.trim() ?? '',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _contactCtrl,
              label: 'Proprietor / Contact Person *',
              hint: 'e.g. Nalubega Sarah',
              icon: Icons.person_outline_rounded,
              inputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Contact person is required' : null,
              onSaved: (v) => _form.contactPerson = v?.trim() ?? '',
            ),
            const SizedBox(height: 12),
            _buildPhoneField(),
            const SizedBox(height: 20),

            _buildSectionHeader('📍 Location & Route', 'Where is this shop on your route?'),
            const SizedBox(height: 10),
            _buildRouteDropdown(),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _landmarkCtrl,
              label: 'Landmark / Description',
              hint: 'e.g. Opposite Total petrol station',
              icon: Icons.place_outlined,
              inputAction: TextInputAction.done,
              validator: null,
              onSaved: (v) => _form.landmark = v?.trim(),
            ),
            const SizedBox(height: 12),
            _buildGPSCard(),
            const SizedBox(height: 20),

            _buildSectionHeader('🏷️ Customer Type', 'What kind of outlet is this?'),
            const SizedBox(height: 10),
            _buildCustomerTypeSelector(),
            const SizedBox(height: 24),

            _buildSaveButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A3C5E),
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Customer',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            'Register a new retail shop on your route',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF90CDF4),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: _isSaving ? null : _saveCustomer,
          icon: _isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.check_rounded, color: Color(0xFF68D391), size: 20),
          label: Text(
            _isSaving ? 'Saving…' : 'Save',
            style: const TextStyle(
              color: Color(0xFF68D391),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ── Section Header ───────────────────────────────────────────

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3748),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  // ── Text Field ───────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputAction inputAction,
    required FormFieldValidator<String>? validator,
    required FormFieldSetter<String>? onSaved,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: inputAction,
      validator: validator,
      onSaved: onSaved,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A202C)),
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  // ── Phone Field ──────────────────────────────────────────────

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneCtrl,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 12,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A202C)),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Phone number is required';
        if (v.trim().length < 9) return 'Enter a valid Uganda phone number';
        return null;
      },
      onSaved: (v) => _form.phoneNumber = v?.trim() ?? '',
      decoration: _inputDecoration(
        label: 'Phone Number (WhatsApp) *',
        hint: '256700000000',
        icon: Icons.chat_rounded,
      ).copyWith(
        counterText: '',
        prefixText: '+',
        prefixStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF276749),
          fontSize: 14,
        ),
        helperText: 'Used for sending WhatsApp receipts',
        helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
      ),
    );
  }

  // ── Route Dropdown ───────────────────────────────────────────

  Widget _buildRouteDropdown() {
    return DropdownButtonFormField<String>(
      value: _form.route.isEmpty ? null : _form.route,
      hint: const Text('Select route', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Route / Zone *',
        hint: '',
        icon: Icons.route_rounded,
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Please select a route' : null,
      onChanged: (v) => setState(() => _form.route = v ?? ''),
      onSaved: (v) => _form.route = v ?? '',
      items: kUgandaRoutes
          .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14))))
          .toList(),
    );
  }

  // ── GPS Card ─────────────────────────────────────────────────

  Widget _buildGPSCard() {
    final hasFix = _form.latitude != null;

    return GestureDetector(
      onTap: _gpsLoading ? null : _captureGPS,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasFix ? const Color(0xFFEBF8F0) : const Color(0xFFFFF5E5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFix ? const Color(0xFF68D391) : const Color(0xFFFBD38D),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFix ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              color: hasFix ? const Color(0xFF276749) : const Color(0xFFD69E2E),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFix ? 'GPS Location Captured' : 'Tap to Capture GPS Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: hasFix ? const Color(0xFF276749) : const Color(0xFF744210),
                    ),
                  ),
                  if (hasFix)
                    Text(
                      '${_form.latitude?.toStringAsFixed(4)}, ${_form.longitude?.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF4A5568)),
                    )
                  else
                    const Text(
                      'Optional — helps with route mapping',
                      style: TextStyle(fontSize: 11, color: Color(0xFF718096)),
                    ),
                ],
              ),
            ),
            if (_gpsLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD69E2E)),
              )
            else
              Icon(
                hasFix ? Icons.check_circle_rounded : Icons.my_location_rounded,
                color: hasFix ? const Color(0xFF38A169) : const Color(0xFFD69E2E),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ── Customer Type Selector ────────────────────────────────────

  Widget _buildCustomerTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CustomerType.values.map((type) {
        final selected = _form.customerType == type;
        return GestureDetector(
          onTap: () {
            setState(() => _form.customerType = type);
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1A3C5E) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? const Color(0xFF1A3C5E) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  size: 16,
                  color: selected ? const Color(0xFF90CDF4) : const Color(0xFF718096),
                ),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Save Button ───────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveCustomer,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF276749),
          disabledBackgroundColor: const Color(0xFF9CA3AF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
        label: Text(
          _isSaving ? 'Registering customer…' : 'Register Customer',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ── Input Decoration Helper ────────────────────────────────────

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBCC5D3)),
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF4A90D9)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4A90D9), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFC8181)),
      ),
    );
  }
}
