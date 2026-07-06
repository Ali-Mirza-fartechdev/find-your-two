import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/opportunity.dart';
import '../../providers/charity_provider.dart';
import '../../utils/helpers.dart';
import 'location_picker_screen.dart';

class CreateOpportunityScreen extends StatefulWidget {
  final Opportunity? opportunity;
  final VoidCallback? onSaved;

  const CreateOpportunityScreen({super.key, this.opportunity, this.onSaved});

  @override
  State<CreateOpportunityScreen> createState() =>
      _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState extends State<CreateOpportunityScreen> {
  File? _eventImage;
  final _imagePicker = ImagePicker();

  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _volunteersCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final Set<String> _selectedCategories = {};

  double? _latitude;
  double? _longitude;

  bool? _kidsOk; // true=yes, false=no, null=not specified
  bool _acceptsGroups = false;
  final _maxGroupSizeCtrl = TextEditingController();

  String? _submittingAs;

  bool get _isEditing => widget.opportunity != null;

  final _categories = [
    {'emoji': '🌿', 'label': 'Environment'},
    {'emoji': '📚', 'label': 'Education'},
    {'emoji': '🐾', 'label': 'Animals'},
    {'emoji': '🤝', 'label': 'Community'},
    {'emoji': '💊', 'label': 'Healthcare'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final opp = widget.opportunity!;
      _titleCtrl.text = opp.title;
      _locationCtrl.text = opp.address ?? '';
      _volunteersCtrl.text =
          (opp.volunteersNeeded ?? 0) > 0 ? opp.volunteersNeeded.toString() : '';
      _descriptionCtrl.text = opp.description ?? '';
      _latitude = opp.latitude;
      _longitude = opp.longitude;

      // Capitalize categories for chip matching
      for (final cat in opp.category) {
        final capitalized =
            cat.isNotEmpty ? '${cat[0].toUpperCase()}${cat.substring(1)}' : cat;
        _selectedCategories.add(capitalized);
      }

      _kidsOk = opp.kidsOk;
      _acceptsGroups = opp.acceptsGroups;
      if (opp.maxGroupSize != null) _maxGroupSizeCtrl.text = opp.maxGroupSize.toString();

      // Parse startDatetime
      final dt = Helpers.parseApiDatetime(opp.startDatetime);
      if (dt != null) {
        _selectedDate = DateTime(dt.year, dt.month, dt.day);
        _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _volunteersCtrl.dispose();
    _descriptionCtrl.dispose();
    _maxGroupSizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: -295,
            top: -261,
            width: 979,
            height: 1499,
            child: SvgPicture.asset(
              'assets/images/home_bg_blob.svg',
              fit: BoxFit.fill,
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildDarkHeader(context)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                  child: Column(
                    children: [
                      _buildImageUpload(),
                      const SizedBox(height: 15),
                      _buildTextField(
                        icon: IconlyLight.edit,
                        label: 'Event Title',
                        hint: 'e.g. Park Clean-Up Day',
                        controller: _titleCtrl,
                      ),
                      const SizedBox(height: 15),
                      _buildLocationField(),
                      const SizedBox(height: 15),
                      _buildDatePicker(),
                      const SizedBox(height: 15),
                      _buildTimePicker(),
                      const SizedBox(height: 15),
                      _buildTextField(
                        icon: IconlyLight.user,
                        label: 'Volunteers Required',
                        hint: 'e.g. 30',
                        controller: _volunteersCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      _buildKidsPolicySelector(),
                      const SizedBox(height: 15),
                      _buildAcceptsGroupsToggle(),
                      if (_acceptsGroups) ...[
                        const SizedBox(height: 15),
                        _buildTextField(
                          icon: IconlyLight.user,
                          label: 'Max group per signup',
                          hint: 'e.g. 8',
                          controller: _maxGroupSizeCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 15),
                      _buildDescriptionField(),
                      const SizedBox(height: 15),
                      _buildCategorySelector(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Dark Header ──────────────────────────────────────────────────

  Widget _buildDarkHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 147,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -0.5),
          end: Alignment(1, 1),
          colors: [Color(0xFF262222), Color(0xFF0D0808)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Navigator.of(context).canPop()) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.23),
                    ),
                  ),
                  child: const Icon(
                    IconlyLight.arrow_left,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 15),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Opportunity' : 'Create Opportunity',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 26.923 / 18,
                  ),
                ),
                Text(
                  'Fill in event details',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 15.385 / 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Image Upload ─────────────────────────────────────────────────

  Widget _buildImageUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 139,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.286),
          border: Border.all(
            color: const Color(0xFFF4A583).withValues(alpha: 0.3),
            width: 1.857,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: _eventImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(_eventImage!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44.571,
                    height: 44.571,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(22.286),
                    ),
                    child: const Icon(
                      IconlyLight.upload,
                      size: 22,
                      color: Color(0xFFF4A583),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload Event Image',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG, JPG up to 10MB',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF262222).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Text Field Card ──────────────────────────────────────────────

  Widget _buildTextField({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6.53,
            offset: Offset(0, 2.82),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label row
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
            child: Row(
              children: [
                _buildIconCircle(icon),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF262222),
                  ),
                ),
              ],
            ),
          ),
          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(55, 0, 15, 12),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF262222),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF262222).withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Location Field ─────────────────────────────────────────────────

  Widget _buildLocationField() {
    return GestureDetector(
      onTap: _openLocationPicker,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6.53,
              offset: Offset(0, 2.82),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
              child: Row(
                children: [
                  _buildIconCircle(IconlyLight.location),
                  const SizedBox(width: 10),
                  Text(
                    'Location / Address',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(55, 6, 15, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _locationCtrl.text.isNotEmpty
                          ? _locationCtrl.text
                          : 'e.g. Central Park, NYC',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _locationCtrl.text.isNotEmpty
                            ? const Color(0xFF262222)
                            : const Color(0xFF262222).withValues(alpha: 0.5),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    IconlyLight.arrow_right_2,
                    size: 17,
                    color: const Color(0xFF262222).withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Date Picker ──────────────────────────────────────────────────

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6.53,
              offset: Offset(0, 2.82),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
              child: Row(
                children: [
                  _buildIconCircle(IconlyLight.calendar),
                  const SizedBox(width: 10),
                  Text(
                    'Date',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(55, 6, 15, 12),
              child: Row(
                children: [
                  Text(
                    _selectedDate != null
                        ? DateFormat('MM/dd/yyyy').format(_selectedDate!)
                        : 'mm/dd/yyyy',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _selectedDate != null
                          ? const Color(0xFF262222)
                          : const Color(0xFF262222).withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    IconlyLight.calendar,
                    size: 17,
                    color: const Color(0xFF262222).withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Time Picker ──────────────────────────────────────────────────

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6.53,
              offset: Offset(0, 2.82),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
              child: Row(
                children: [
                  _buildIconCircle(IconlyLight.time_circle),
                  const SizedBox(width: 10),
                  Text(
                    'Time',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(55, 6, 15, 12),
              child: Row(
                children: [
                  Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : '--:-- --',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _selectedTime != null
                          ? const Color(0xFF262222)
                          : const Color(0xFF262222).withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    IconlyLight.time_circle,
                    size: 17,
                    color: const Color(0xFF262222).withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Description ──────────────────────────────────────────────────

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6.53,
            offset: Offset(0, 2.82),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
            child: Row(
              children: [
                _buildIconCircle(IconlyLight.info_square),
                const SizedBox(width: 10),
                Text(
                  'Description',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF262222),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(55, 0, 15, 12),
            child: TextField(
              controller: _descriptionCtrl,
              maxLines: 4,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF262222),
              ),
              decoration: InputDecoration(
                hintText:
                    'Describe the volunteer event, what\nvolunteers will do, what to bring...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF262222).withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Category Selector ────────────────────────────────────────────

  Widget _buildCategorySelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6.53,
            offset: Offset(0, 2.82),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconCircle(IconlyLight.category),
              const SizedBox(width: 10),
              Text(
                'Category',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _categories.map((cat) {
              final label = cat['label']!;
              final isSelected = _selectedCategories.contains(label);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(label);
                    } else {
                      _selectedCategories.add(label);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17.455,
                    vertical: 6.545,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF4A583)
                        : const Color(0xFF262222).withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(108),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: const Color(
                              0xFF262222,
                            ).withValues(alpha: 0.1),
                            width: 1.091,
                          ),
                  ),
                  child: Text(
                    '${cat['emoji']} $label',
                    style: GoogleFonts.inter(
                      fontSize: 8.73,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF262222).withValues(alpha: 0.5),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Kids Policy Selector ────────────────────────────────────────

  Widget _buildKidsPolicySelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6.53,
            offset: Offset(0, 2.82),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconCircle(IconlyLight.shield_done),
              const SizedBox(width: 10),
              Text(
                'Kids Policy',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildKidsPolicyChip('Kids welcome', true),
              const SizedBox(width: 7),
              _buildKidsPolicyChip('Adults only', false),
              const SizedBox(width: 7),
              _buildKidsPolicyChip('Not specified', null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKidsPolicyChip(String label, bool? value) {
    final isSelected = _kidsOk == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _kidsOk = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF4A583)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(108),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF4A583)
                  : const Color(0xFF262222).withValues(alpha: 0.15),
              width: 1.091,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF262222).withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Accepts Groups Toggle ─────────────────────────────────────

  Widget _buildAcceptsGroupsToggle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6.53,
            offset: Offset(0, 2.82),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildIconCircle(IconlyLight.user),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Accepts Groups',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
          ),
          Switch(
            value: _acceptsGroups,
            onChanged: (val) => setState(() => _acceptsGroups = val),
            activeTrackColor: const Color(0xFFF4A583),
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Save Draft
        Expanded(
          child: GestureDetector(
            onTap: _submittingAs != null
                ? null
                : () => _submitOpportunity('draft'),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.286),
                border: Border.all(
                  color: const Color(0xFF262222).withValues(alpha: 0.3),
                  width: 0.929,
                ),
              ),
              alignment: Alignment.center,
              child: _submittingAs == 'draft'
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF262222),
                      ),
                    )
                  : Text(
                      'Save Draft',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF262222),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        // Publish / Update
        Expanded(
          child: GestureDetector(
            onTap: _submittingAs != null
                ? null
                : () => _submitOpportunity('active'),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF4A583),
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: Alignment.center,
              child: _submittingAs == 'active'
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Update \u2192' : 'Publish \u2192',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared Icon Circle ───────────────────────────────────────────

  Widget _buildIconCircle(IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFF4A583).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: const Color(0xFFF4A583)),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _eventImage = File(picked.path));
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialAddress:
              _locationCtrl.text.isNotEmpty ? _locationCtrl.text : null,
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          bottomOffset: 100, // Clear charity shell nav bar
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _locationCtrl.text = result.address;
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null && _selectedDate!.isAfter(DateTime.now())
          ? _selectedDate
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF4A583),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF4A583),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submitOpportunity(String status) async {
    // Validate
    final title = _titleCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final volunteersText = _volunteersCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();

    if (title.isEmpty) {
      _showError('Please enter a title');
      return;
    }
    if (location.isEmpty) {
      _showError('Please select a location');
      return;
    }
    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_selectedTime == null) {
      _showError('Please select a time');
      return;
    }
    int? volunteersNeeded;
    if (volunteersText.isNotEmpty) {
      volunteersNeeded = int.tryParse(volunteersText);
      if (volunteersNeeded != null && volunteersNeeded <= 0) {
        _showError('Volunteers needed must be a positive number');
        return;
      }
    }

    setState(() => _submittingAs = status);

    // Build datetime string
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final startDatetime = DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);

    // Geocode address if no lat/lng
    double? lat = _latitude;
    double? lng = _longitude;
    if (lat == null || lng == null) {
      try {
        final locations = await locationFromAddress(location);
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
        }
      } catch (_) {
        // Continue without coordinates
      }
    }

    final provider = context.read<CharityProvider>();
    final categories = _selectedCategories
        .map((c) => c.toLowerCase())
        .toList();

    Map<String, dynamic>? result;

    try {
      if (_isEditing) {
        result = await provider.updateOpportunity(
          id: widget.opportunity!.id,
          title: title,
          description: description.isNotEmpty ? description : null,
          address: location,
          startDatetime: startDatetime,
          volunteersNeeded: volunteersNeeded,
          category: categories.isNotEmpty ? categories : null,
          imagePath: _eventImage?.path,
          latitude: lat,
          longitude: lng,
          status: status,
          kidsOk: _kidsOk,
          acceptsGroups: _acceptsGroups,
          maxGroupSize: _acceptsGroups ? int.tryParse(_maxGroupSizeCtrl.text.trim()) : null,
        );
      } else {
        result = await provider.createOpportunity(
          title: title,
          address: location,
          startDatetime: startDatetime,
          volunteersNeeded: volunteersNeeded,
          description: description.isNotEmpty ? description : null,
          category: categories.isNotEmpty ? categories : null,
          imagePath: _eventImage?.path,
          latitude: lat,
          longitude: lng,
          status: status,
          kidsOk: _kidsOk,
          acceptsGroups: _acceptsGroups,
          maxGroupSize: _acceptsGroups ? int.tryParse(_maxGroupSizeCtrl.text.trim()) : null,
        );
      }
    } catch (_) {
      // Error handled below via provider.errorMessage
    }

    if (!mounted) return;
    setState(() => _submittingAs = null);

    if (result != null) {
      final label = _isEditing
          ? 'Opportunity updated'
          : (status == 'draft' ? 'Draft saved' : 'Opportunity published');

      // Refresh dashboard data
      provider.fetchDashboard();
      provider.fetchCharityOpportunities();

      if (Navigator.of(context).canPop()) {
        // Pushed as a route — pop back
        Navigator.of(context).pop(true);
      } else {
        // Tab root — clear form and switch to dashboard
        _clearForm();
        widget.onSaved?.call();
      }

      // Show snackbar after navigation settles
      if (mounted) {
        Helpers.showSnackBar(
          context,
          message: label,
          backgroundColor: const Color(0xFF15B789),
        );
      }
    } else {
      _showError(provider.errorMessage ?? 'Something went wrong');
    }
  }

  void _clearForm() {
    setState(() {
      _titleCtrl.clear();
      _locationCtrl.clear();
      _volunteersCtrl.clear();
      _descriptionCtrl.clear();
      _selectedDate = null;
      _selectedTime = null;
      _selectedCategories.clear();
      _latitude = null;
      _longitude = null;
      _eventImage = null;
      _kidsOk = null;
      _acceptsGroups = false;
      _maxGroupSizeCtrl.clear();
    });
  }

  void _showError(String message) {
    Helpers.showSnackBar(context, message: message);
  }
}
