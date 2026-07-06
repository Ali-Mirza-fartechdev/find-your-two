import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../models/opportunity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/opportunity_provider.dart';
import '../../utils/helpers.dart';

class EnrollmentScreen extends StatefulWidget {
  final Opportunity opportunity;

  const EnrollmentScreen({
    super.key,
    required this.opportunity,
  });

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  int _partySize = 1;
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _fullNameController.text = user.name;
      _emailController.text = user.email;
    }
    context.read<GroupProvider>().fetchGroups();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleEnroll() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<OpportunityProvider>();
    await provider.enrollInOpportunity(
      widget.opportunity.id,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      partySize: _partySize,
      groupId: _selectedGroupId,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (provider.errorMessage != null) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          message: provider.errorMessage!,
          backgroundColor: const Color(0xFFEF4343),
        );
      }
      provider.clearError();
    } else {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          message: 'Enrolled in "${widget.opportunity.title}" successfully!',
          backgroundColor: const Color(0xFF15B789),
        );
        Navigator.of(context).pop(true);
      }
    }
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
            width: 894,
            height: 1308,
            child: SvgPicture.asset(
              'assets/images/home_bg_blob.svg',
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          _buildOpportunityCard(),
                          _buildDivider(),
                          const SizedBox(height: 28),
                          _buildForm(),
                          const SizedBox(height: 30),
                          _buildConfirmButton(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 16, 25, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF262222).withValues(alpha: 0.6),
                  width: 0.685,
                ),
              ),
              child: const Center(
                child: Icon(IconlyLight.arrow_left, size: 16, color: Color(0xFF262222)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                'Enroll In Opportunity',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222),
                  height: 26.923 / 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fill details to enroll yourself.',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF262222),
                  height: 15.385 / 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFF4A583).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFF4A583), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 91,
              height: 72,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: widget.opportunity.imageUrl != null &&
                          widget.opportunity.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.opportunity.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.opportunity.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF262222),
                        height: 15 / 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.opportunity.charityName,
                      style: GoogleFonts.inter(
                        fontSize: 11.143,
                        color: const Color(0xFF262222).withValues(alpha: 0.5),
                        height: 14.857 / 11.143,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${Helpers.formatApiDate(widget.opportunity.startDatetime)} · ${Helpers.formatApiTimeRange(widget.opportunity.startDatetime, widget.opportunity.endDatetime)}',
                      style: GoogleFonts.inter(
                        fontSize: 11.143,
                        color: const Color(0xFF262222).withValues(alpha: 0.5),
                        height: 14.857 / 11.143,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Icon(IconlyLight.heart, size: 24, color: Color(0xFFCBD5E1)),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Divider(
        color: const Color(0xFF262222).withValues(alpha: 0.1),
        height: 1,
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          _buildTextField(
            label: 'Full Name',
            isRequired: true,
            controller: _fullNameController,
            hintText: 'Enter your full name',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            label: 'Phone Number',
            isRequired: true,
            controller: _phoneController,
            hintText: 'Enter your phone number',
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            label: 'Email Address',
            isRequired: true,
            controller: _emailController,
            hintText: 'Enter your email address',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 15),
          _buildGroupPicker(),
          const SizedBox(height: 15),
          _buildPartySizeStepper(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required bool isRequired,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F1729).withValues(alpha: 0.4),
              height: 16 / 10,
            ),
            children: [
              TextSpan(text: '$label '),
              if (isRequired)
                TextSpan(
                  text: '*',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4343),
                    height: 16 / 10,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: const Color(0xFF0D0808).withValues(alpha: 0.1),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 4,
                offset: Offset(-2, 3),
              ),
            ],
          ),
          child: Center(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D0808),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF0D0808).withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                errorStyle: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFFEF4343),
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isCollapsed: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupPicker() {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        final groups = groupProvider.groups;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F1729).withValues(alpha: 0.4),
                  height: 16 / 10,
                ),
                children: [
                  const TextSpan(text: 'Sign up as...'),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Pick a group to sign up with (optional)',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: const Color(0xFF0F1729).withValues(alpha: 0.3),
                height: 14 / 9,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: const Color(0xFF0D0808).withValues(alpha: 0.1),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(-2, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedGroupId,
                    isExpanded: true,
                    icon: const Icon(
                      IconlyLight.arrow_down_2,
                      size: 16,
                      color: Color(0xFF262222),
                    ),
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D0808),
                    ),
                    hint: Text(
                      'Just me',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF0D0808).withValues(alpha: 0.3),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'Just me',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0D0808),
                          ),
                        ),
                      ),
                      ...groups.map(
                        (group) => DropdownMenuItem<int?>(
                          value: group.id,
                          child: Text(
                            group.name,
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0D0808),
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGroupId = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPartySizeStepper() {
    final opportunity = widget.opportunity;
    final int? maxGroupSize = opportunity.maxGroupSize;
    final bool isUncapped = opportunity.isUncapped;
    final int spotsLeft = opportunity.spotsLeft;

    // Determine the maximum party size
    int? maxParty;
    if (maxGroupSize != null) {
      maxParty = maxGroupSize;
    } else if (!isUncapped && spotsLeft > 0) {
      maxParty = spotsLeft;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F1729).withValues(alpha: 0.4),
              height: 16 / 10,
            ),
            children: [
              const TextSpan(text: 'Party Size '),
              TextSpan(
                text: '*',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4343),
                  height: 16 / 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'How many people total (including you)?',
          style: GoogleFonts.inter(
            fontSize: 9,
            color: const Color(0xFF0F1729).withValues(alpha: 0.3),
            height: 14 / 9,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_partySize > 1) {
                  setState(() => _partySize--);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _partySize > 1
                      ? const Color(0xFFF4A583)
                      : const Color(0xFFF4A583).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.remove, size: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Text(
              '$_partySize',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                if (maxParty == null || _partySize < maxParty) {
                  setState(() => _partySize++);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (maxParty == null || _partySize < maxParty)
                      ? const Color(0xFFF4A583)
                      : const Color(0xFFF4A583).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        if (maxGroupSize != null) ...[
          const SizedBox(height: 6),
          Text(
            'Max group size: $maxGroupSize',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF0F1729).withValues(alpha: 0.4),
            ),
          ),
        ] else if (!isUncapped && spotsLeft > 0) ...[
          const SizedBox(height: 6),
          Text(
            '$spotsLeft spots left',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF0F1729).withValues(alpha: 0.4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _handleEnroll,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF4A583),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFF4A583).withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
              side: BorderSide(
                color: const Color(0xFFF4A583).withValues(alpha: 0.2),
              ),
            ),
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Confirm Enrollment',
                  style: GoogleFonts.ptSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
