class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'FindYourTwo';
  static const String appTagline = 'Change Your World';

  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_complete';

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);

  // User Roles
  static const String roleVolunteer = 'volunteer';
  static const String roleCharity = 'charity';
  static const String roleAdmin = 'administrator';

  // Splash Screen Duration
  static const Duration splashDuration = Duration(seconds: 3);
}
