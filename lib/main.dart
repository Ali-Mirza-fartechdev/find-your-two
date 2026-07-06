import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/charity_provider.dart';
import 'providers/checkin_provider.dart';
import 'providers/group_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/opportunity_provider.dart';
import 'providers/volunteer_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/charity_service.dart';
import 'services/checkin_service.dart';
import 'services/group_service.dart';
import 'services/notification_service.dart';
import 'services/opportunity_service.dart';
import 'services/profile_service.dart';
import 'services/device_service.dart';
import 'services/storage_service.dart';
import 'services/volunteer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final storageService = StorageService();
  final apiService = ApiService(storageService: storageService);
  final authService = AuthService(
    apiService: apiService,
    storageService: storageService,
  );
  final opportunityService = OpportunityService(apiService: apiService);
  final volunteerService = VolunteerService(apiService: apiService);
  final notificationService = NotificationService(apiService: apiService);
  final profileService = ProfileService(
    apiService: apiService,
    storageService: storageService,
  );
  final checkinService = CheckinService(apiService: apiService);
  final charityService = CharityService(apiService: apiService);
  final groupService = GroupService(apiService: apiService);
  final deviceService = DeviceService(apiService: apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: authService,
            profileService: profileService,
            deviceService: deviceService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OpportunityProvider(
            opportunityService: opportunityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => VolunteerProvider(
            volunteerService: volunteerService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CheckinProvider(
            checkinService: checkinService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CharityProvider(
            charityService: charityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => GroupProvider(
            groupService: groupService,
          ),
        ),
      ],
      child: const FindYourTwoApp(),
    ),
  );
}
