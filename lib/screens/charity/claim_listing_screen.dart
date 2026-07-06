import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../providers/charity_provider.dart';
import '../../utils/helpers.dart';
import 'charity_shell.dart';

class ClaimListingScreen extends StatefulWidget {
  const ClaimListingScreen({super.key});

  @override
  State<ClaimListingScreen> createState() => _ClaimListingScreenState();
}

class _ClaimListingScreenState extends State<ClaimListingScreen> {
  int _step = 0;
  final _searchController = TextEditingController();
  final _tokenController = TextEditingController();
  Timer? _debounce;
  Map<String, dynamic>? _selectedOrg;
  bool _isClaiming = false;
  bool _isConfirming = false;

  @override
  void dispose() {
    _searchController.dispose();
    _tokenController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().length >= 2) {
        context.read<CharityProvider>().searchUnclaimed(query.trim());
      }
    });
  }

  Future<void> _claimOrganization() async {
    if (_selectedOrg == null) return;
    setState(() => _isClaiming = true);

    final provider = context.read<CharityProvider>();
    final result = await provider.claimListing(_selectedOrg!['id'] as int);

    if (!mounted) return;
    setState(() => _isClaiming = false);

    if (result != null) {
      setState(() => _step = 2);
    } else {
      Helpers.showSnackBar(
        context,
        message: provider.claimError ?? 'Failed to submit claim',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _confirmClaim() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      Helpers.showSnackBar(
        context,
        message: 'Please enter the confirmation code',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isConfirming = true);

    final provider = context.read<CharityProvider>();
    final success = await provider.confirmClaim(token);

    if (!mounted) return;
    setState(() => _isConfirming = false);

    if (success) {
      setState(() => _step = 3);
    } else {
      Helpers.showSnackBar(
        context,
        message: provider.claimError ?? 'Invalid confirmation code',
        backgroundColor: Colors.red,
      );
    }
  }

  void _goToDashboard() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CharityShell()),
      (route) => false,
    );
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
            height: 1763,
            child: SvgPicture.asset(
              'assets/images/home_bg_blob.svg',
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildStepContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header ---------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_step > 0 && _step < 3) {
                setState(() => _step = _step - 1);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF262222).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconlyLight.arrow_left,
                size: 18,
                color: Color(0xFF262222),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            _step == 0
                ? 'Claim Your Organization'
                : _step == 1
                    ? 'Confirm Details'
                    : _step == 2
                        ? 'Enter Code'
                        : 'Success',
            style: GoogleFonts.ptSerif(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step Router ----------------------------------------------------------

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildSearchStep();
      case 1:
        return _buildConfirmStep();
      case 2:
        return _buildCodeStep();
      case 3:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step 0: Search -------------------------------------------------------

  Widget _buildSearchStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildSearchBar(),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer<CharityProvider>(
            builder: (context, provider, _) {
              if (provider.isClaimLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF4A583),
                  ),
                );
              }

              if (provider.claimError != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      provider.claimError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF262222).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              }

              if (_searchController.text.trim().length < 2) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconlyLight.search,
                          size: 48,
                          color: const Color(0xFF262222).withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Search for your organization\nby name to claim it',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF262222)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (provider.unclaimedResults.isEmpty) {
                return Center(
                  child: Text(
                    'No unclaimed organizations found',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color:
                          const Color(0xFF262222).withValues(alpha: 0.5),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 20),
                itemCount: provider.unclaimedResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final org = provider.unclaimedResults[index];
                  return _buildOrgCard(org);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          cursorColor: const Color(0xFFF4A583),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF262222),
          ),
          decoration: InputDecoration(
            hintText: 'Search organization name...',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF262222).withValues(alpha: 0.35),
            ),
            prefixIcon: Icon(
              IconlyLight.search,
              size: 18,
              color: const Color(0xFF262222).withValues(alpha: 0.35),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildOrgCard(Map<String, dynamic> org) {
    final logoUrl = org['logo_url'] as String?;
    final orgName = org['org_name'] as String? ?? '';
    final email = org['email'] as String? ?? '';
    final description = org['description'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOrg = org;
          _step = 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo or placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF4A583).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: Icon(IconlyLight.category,
                            size: 20, color: Color(0xFFF4A583)),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                          IconlyLight.category,
                          size: 20,
                          color: Color(0xFFF4A583)),
                    )
                  : const Icon(IconlyLight.category,
                      size: 20, color: Color(0xFFF4A583)),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orgName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF262222),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color:
                            const Color(0xFF262222).withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color:
                            const Color(0xFF262222).withValues(alpha: 0.4),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              IconlyLight.arrow_right_2,
              size: 16,
              color: const Color(0xFF262222).withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Confirm Details ----------------------------------------------

  Widget _buildConfirmStep() {
    if (_selectedOrg == null) return const SizedBox.shrink();

    final org = _selectedOrg!;
    final logoUrl = org['logo_url'] as String?;
    final orgName = org['org_name'] as String? ?? '';
    final email = org['email'] as String? ?? '';
    final phone = org['phone'] as String? ?? '';
    final website = org['website'] as String? ?? '';
    final description = org['description'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 40),
      child: Column(
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF4A583).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl != null && logoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: logoUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: Icon(IconlyLight.category,
                          size: 32, color: Color(0xFFF4A583)),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                        IconlyLight.category,
                        size: 32,
                        color: Color(0xFFF4A583)),
                  )
                : const Icon(IconlyLight.category,
                    size: 32, color: Color(0xFFF4A583)),
          ),
          const SizedBox(height: 16),
          Text(
            orgName,
            style: GoogleFonts.ptSerif(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Detail rows
          _buildDetailCard([
            if (email.isNotEmpty) _buildDetailRow(IconlyLight.message, 'Email', email),
            if (phone.isNotEmpty) _buildDetailRow(IconlyLight.call, 'Phone', phone),
            if (website.isNotEmpty) _buildDetailRow(IconlyLight.discovery, 'Website', website),
          ]),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14.5),
            _buildDetailCard([
              Padding(
                padding: const EdgeInsets.all(14.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: GoogleFonts.inter(
                        fontSize: 10.6,
                        color: const Color(0xFF262222).withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF262222),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ],
          const SizedBox(height: 30),
          // Claim button
          GestureDetector(
            onTap: _isClaiming ? null : _claimOrganization,
            child: Container(
              width: double.infinity,
              height: 51,
              decoration: BoxDecoration(
                color: const Color(0xFFF4A583),
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: Alignment.center,
              child: _isClaiming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Claim This Organization',
                      style: GoogleFonts.inter(
                        fontSize: 13.254,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.64),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6.373,
            offset: Offset(0, 2.752),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14.5, 12, 14.5, 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFF4A583)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.6,
                    color: const Color(0xFF262222).withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12.4,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF262222),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Enter Code ---------------------------------------------------

  Widget _buildCodeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(25, 50, 25, 40),
      child: Column(
        children: [
          // Mail icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF4A583).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconlyLight.message,
              size: 36,
              color: Color(0xFFF4A583),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Check Your Email',
            style: GoogleFonts.ptSerif(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF262222),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Check the email associated with this organization for a confirmation code.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF262222).withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Token input
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: const Color(0xFFF4A583).withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _tokenController,
              textAlign: TextAlign.center,
              cursorColor: const Color(0xFFF4A583),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
                letterSpacing: 6,
              ),
              decoration: InputDecoration(
                hintText: '------',
                hintStyle: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF262222).withValues(alpha: 0.15),
                  letterSpacing: 6,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              maxLength: 6,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            ),
          ),
          const SizedBox(height: 24),
          // Confirm button
          GestureDetector(
            onTap: _isConfirming ? null : _confirmClaim,
            child: Container(
              width: double.infinity,
              height: 51,
              decoration: BoxDecoration(
                color: const Color(0xFFF4A583),
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: Alignment.center,
              child: _isConfirming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Confirm',
                      style: GoogleFonts.inter(
                        fontSize: 13.254,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Success ------------------------------------------------------

  Widget _buildSuccessStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF15B789).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconlyBold.tick_square,
                size: 40,
                color: Color(0xFF15B789),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Organization Claimed!',
              style: GoogleFonts.ptSerif(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF262222),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can now manage your organization, create opportunities, and connect with volunteers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF262222).withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _goToDashboard,
              child: Container(
                width: double.infinity,
                height: 51,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A583),
                  borderRadius: BorderRadius.circular(99),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Go to Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 13.254,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
