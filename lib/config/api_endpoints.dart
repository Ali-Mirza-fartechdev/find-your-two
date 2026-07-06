/// All backend API endpoint paths for the FYT2 REST API.
///
/// Base URL: https://findyourtwo.org/wp-json/fyt2/v1
/// These are path suffixes appended to [Env.apiBaseUrl].
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Authentication ──────────────────────────────────────────────

  /// POST - Register a new user (volunteer or charity).
  /// Body: { name, email, password, confirm_password, role }
  /// Response: { token, user }
  static const String register = '/auth/register';

  /// POST - Login with email and password.
  /// Body: { email, password }
  /// Response: { token, user }
  static const String login = '/auth/login';

  /// GET - Get the currently authenticated user's info.
  /// Headers: `Authorization: Bearer {token}`
  /// Response: `{ id, name, email, mode, avatar_url, location, skills, interests, availability }`
  static const String me = '/auth/me';

  /// PUT - Switch between volunteer and charity mode.
  /// Body: { mode: 'volunteer' | 'charity' }
  static const String switchMode = '/auth/mode';

  /// POST - Request a password reset OTP.
  /// Body: { email }
  static const String forgotPassword = '/auth/forgot-password';

  /// POST - Verify OTP and get reset token.
  /// Body: { email, otp }
  /// Response: { message, reset_token }
  static const String verifyOtp = '/auth/verify-otp';

  /// POST - Reset password using reset token.
  /// Body: { email, new_password, confirm_password, reset_token }
  static const String resetPassword = '/auth/reset-password';

  /// DELETE - Delete the authenticated user's account entirely.
  /// Removes both volunteer and charity profiles.
  static const String deleteAccount = '/auth/delete-account';

  // ─── Opportunities ───────────────────────────────────────────────

  /// GET - List all opportunities (paginated, filterable).
  ///   Query: page, per_page, category, search
  ///   Response: { data: [...], pagination: { page, per_page, total } }
  /// POST - Create a new opportunity (charity only).
  ///   Body: { title, address, start_datetime, volunteers_needed, ... }
  static const String opportunities = '/opportunities';

  /// GET - List nearby opportunities based on user location.
  ///   Query: lat, lng, radius?
  ///   Response: { count, data: [...] }
  static const String nearbyOpportunities = '/opportunities/nearby';

  /// GET/PUT/DELETE a single opportunity by ID.
  /// Use: '${opportunities}/$id'
  static String opportunityById(int id) => '/opportunities/$id';

  // ─── Enrollment ──────────────────────────────────────────────────

  /// POST - Enroll the authenticated volunteer in an opportunity.
  ///   Body: { full_name, phone_number, email }
  /// DELETE - Withdraw from an opportunity.
  static String enroll(int opportunityId) =>
      '/opportunities/$opportunityId/enroll';

  // ─── Volunteer ───────────────────────────────────────────────────

  /// GET - List opportunities the authenticated volunteer is enrolled in.
  ///   Response: { upcoming_count, past_count, data: [...] }
  static const String volunteerOpportunities = '/volunteer/opportunities';

  // ─── Check-in ────────────────────────────────────────────────────

  /// POST - Check in to an opportunity via QR code scan.
  /// Body: { qr_data }
  static String checkinQr(int opportunityId) =>
      '/opportunities/$opportunityId/checkin/qr';

  /// POST - Check in to an opportunity via GPS location.
  /// Body: { latitude, longitude }
  static String checkinGps(int opportunityId) =>
      '/opportunities/$opportunityId/checkin/gps';

  /// GET - Get the check-in status for an opportunity.
  static String checkinStatus(int opportunityId) =>
      '/opportunities/$opportunityId/checkin/status';

  // ─── Profile ─────────────────────────────────────────────────────

  /// GET - Get the authenticated user's profile (same shape as /auth/me).
  /// PUT - Update the authenticated user's profile.
  ///   Body: { name?, location?, skills?, interests?, availability? }
  static const String profile = '/profile';

  /// POST - Upload a profile avatar image (multipart/form-data).
  static const String profileAvatar = '/profile/avatar';

  // ─── Impact & Achievements ───────────────────────────────────────

  /// GET - Get all impact data in one call.
  ///   Response: { summary, impact_score, monthly_hours, achievements }
  static const String impact = '/impact';

  /// GET - Get monthly impact data for charts.
  ///   Query: year?
  ///   Response: [ { month, hours }, ... ]
  static const String impactMonthly = '/impact/monthly';

  /// GET - Get the volunteer's achievements/badges.
  static const String achievements = '/achievements';

  // ─── Notifications ───────────────────────────────────────────────

  /// GET - List all notifications for the authenticated user.
  ///   Response: { unread_count, data: [...] }
  static const String notifications = '/notifications';

  /// PUT - Mark all notifications as read.
  static const String notificationsReadAll = '/notifications/read-all';

  /// PUT - Mark a single notification as read.
  static String notificationRead(int id) => '/notifications/$id/read';

  /// DELETE - Delete a single notification.
  static String notificationDelete(int id) => '/notifications/$id';

  // ─── Push Notification Devices ───────────────────────────────────

  /// POST - Register a device for push notifications.
  /// Body: { fcm_token }
  static const String devices = '/devices';

  /// DELETE - Unregister a device token.
  static String deviceDelete(String token) => '/devices/$token';

  // ─── Charity Dashboard ───────────────────────────────────────────

  /// GET - Get the charity's dashboard summary data.
  ///   Response: { total_opportunities, total_volunteers, ... }
  static const String charityDashboard = '/charity/dashboard';

  /// GET/PUT - Get or update the charity's organization profile.
  static const String charityProfile = '/charity/profile';

  /// GET - List opportunities created by the authenticated charity.
  static const String charityOpportunities = '/charity/opportunities';

  // ─── Charity Volunteer Management ────────────────────────────────

  /// GET - List volunteers enrolled in a specific opportunity.
  static String opportunityVolunteers(int opportunityId) =>
      '/opportunities/$opportunityId/volunteers';

  /// PUT - Mark attendance for volunteers in an opportunity.
  /// Body: { volunteers: [ { id, status: 'present'|'absent' } ] }
  static String opportunityAttendance(int opportunityId) =>
      '/opportunities/$opportunityId/attendance';

  /// GET - Export attendance data as CSV/Excel for an opportunity.
  static String opportunityAttendanceExport(int opportunityId) =>
      '/opportunities/$opportunityId/attendance/export';

  /// GET - Get/generate a QR code for check-in at an opportunity.
  static String opportunityQr(int opportunityId) =>
      '/opportunities/$opportunityId/qr';

  // ─── Media ───────────────────────────────────────────────────────

  /// POST - Upload an image file (multipart/form-data).
  ///   Response: { url, id }
  static const String mediaUpload = '/media/upload';

  // ─── Settings ────────────────────────────────────────────────────

  /// GET/PUT - Get or update notification preferences.
  static const String settingsNotifications = '/settings/notifications';

  /// PUT - Change email address.
  /// Body: { new_email, password }
  static const String settingsEmail = '/settings/email';

  /// PUT - Change password.
  /// Body: { current_password, new_password }
  static const String settingsPassword = '/settings/password';

  /// GET/PUT - Charity notification settings.
  static const String charitySettingsNotifications =
      '/charity/settings/notifications';

  // ─── Support ─────────────────────────────────────────────────────

  /// POST - Send a support/contact form message.
  /// Body: { subject, message }
  static const String supportContact = '/support/contact';

  // ─── Saved Opportunities ────────────────────────────────────

  /// POST /opportunities/:id/save — Save an opportunity.
  /// DELETE /opportunities/:id/save — Unsave an opportunity.
  static String opportunitySave(int id) => '/opportunities/$id/save';

  /// GET /saved-opportunities — List all saved opportunities (not paginated).
  static const String savedOpportunities = '/saved-opportunities';

  // ─── External Signup / Track Click ──────────────────────────

  /// POST /opportunities/:id/track-click — Log click, returns { url } to open.
  static String trackClick(int id) => '/opportunities/$id/track-click';

  // ─── Groups ─────────────────────────────────────────────────

  /// POST /groups — Create group. Body: { name }
  /// GET /groups — List my groups.
  static const String groups = '/groups';

  /// GET /groups/:id — Group detail with members.
  static String groupById(int id) => '/groups/$id';

  /// POST /groups/:id/invite — Invite by email. Body: { email }
  static String groupInvite(int id) => '/groups/$id/invite';

  /// POST /groups/join — Join via invite token. Body: { token }
  static const String groupJoin = '/groups/join';

  /// POST /groups/:id/leave — Leave a group (not for owners).
  static String groupLeave(int id) => '/groups/$id/leave';

  /// DELETE /groups/:id/members/:memberId — Remove a member.
  /// memberId is the membership record ID, NOT the user ID.
  static String groupRemoveMember(int groupId, int memberId) =>
      '/groups/$groupId/members/$memberId';

  // ─── Charity Claim Flow ─────────────────────────────────────

  /// GET /charity/search-unclaimed?query= — Search unclaimed orgs.
  static const String charitySearchUnclaimed = '/charity/search-unclaimed';

  /// POST /charity/claim — Claim an org. Body: { charity_id }
  static const String charityClaim = '/charity/claim';

  /// POST /charity/claim/confirm — Confirm claim with token. Body: { token }
  static const String charityClaimConfirm = '/charity/claim/confirm';
}
