class AppRoutes {
  AppRoutes._();

  // Initial
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Volunteer
  static const String locationSetup = '/volunteer/location-setup';
  static const String volunteerHome = '/volunteer/home';
  static const String opportunityDetails = '/volunteer/opportunity';
  static const String volunteerProfile = '/volunteer/profile';
  static const String volunteerHours = '/volunteer/hours';
  static const String volunteerNotifications = '/volunteer/notifications';

  // Charity
  static const String charityHome = '/charity/home';
  static const String createOpportunity = '/charity/create-opportunity';
  static const String charityReports = '/charity/reports';
  static const String charityProfile = '/charity/profile';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminOpportunities = '/admin/opportunities';
  static const String adminReports = '/admin/reports';
}
