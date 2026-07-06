class DummyOpportunity {
  final String title;
  final String organization;
  final String location;
  final String date;
  final String time;
  final String tag;
  final String tagEmoji;
  final String tagBgColor;
  final String tagTextColor;
  final String image;
  final String distance;
  final int volunteersJoined;
  final int volunteersNeeded;

  const DummyOpportunity({
    required this.title,
    required this.organization,
    required this.location,
    required this.date,
    required this.time,
    required this.tag,
    required this.tagEmoji,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.image,
    required this.distance,
    required this.volunteersJoined,
    required this.volunteersNeeded,
  });

  int get spotsLeft => volunteersNeeded - volunteersJoined;
  double get progress => volunteersJoined / volunteersNeeded;
}

class DummyData {
  DummyData._();

  static const List<String> filterTags = [
    'All',
    'Environment',
    'Education',
    'Community',
    'Healthcare',
  ];

  static const List<DummyOpportunity> opportunities = [
    DummyOpportunity(
      title: 'Tree Planting in Community Park',
      organization: 'GreenEarth Foundation',
      location: 'Riverside Park, Downtown',
      date: 'Tue, Apr 15',
      time: '9:00 AM - 1:00 PM',
      tag: 'environment',
      tagEmoji: '🌱',
      tagBgColor: '0xFFDCFCE7',
      tagTextColor: '0xFF15803D',
      image: 'assets/images/opportunity_1.png',
      distance: '1.2 km',
      volunteersJoined: 18,
      volunteersNeeded: 25,
    ),
    DummyOpportunity(
      title: 'After-School Tutoring Program',
      organization: 'BrightMinds Education',
      location: 'Lincoln Elementary School',
      date: 'Fri, Apr 18',
      time: '3:30 PM - 5:30 PM',
      tag: 'education',
      tagEmoji: '📚',
      tagBgColor: '0xFFDBEAFE',
      tagTextColor: '0xFF1D4ED8',
      image: 'assets/images/opportunity_3.png',
      distance: '1.2 km',
      volunteersJoined: 7,
      volunteersNeeded: 10,
    ),
    DummyOpportunity(
      title: 'Food Bank Distribution Drive',
      organization: 'Community Food Network',
      location: 'City Community Center',
      date: 'Sun, Apr 20',
      time: '8:00 AM - 12:00 PM',
      tag: 'community',
      tagEmoji: '🤝',
      tagBgColor: '0xFFF3E8FF',
      tagTextColor: '0xFF7E22CE',
      image: 'assets/images/opportunity_2.png',
      distance: '1.2 km',
      volunteersJoined: 22,
      volunteersNeeded: 30,
    ),
    DummyOpportunity(
      title: 'Beach Clean-Up Day',
      organization: 'Ocean Guardians',
      location: 'Sunset Beach',
      date: 'Tue, Apr 22',
      time: '7:00 AM - 11:00 AM',
      tag: 'environment',
      tagEmoji: '🌱',
      tagBgColor: '0xFFDCFCE7',
      tagTextColor: '0xFF15803D',
      image: 'assets/images/opportunity_4.png',
      distance: '1.2 km',
      volunteersJoined: 31,
      volunteersNeeded: 50,
    ),
    DummyOpportunity(
      title: 'Animal Shelter Care Day',
      organization: 'Paws & Hearts Shelter',
      location: 'Paws & Hearts Animal Shelter',
      date: 'Fri, Apr 25',
      time: '10:00 AM - 2:00 PM',
      tag: 'animals',
      tagEmoji: '🐾',
      tagBgColor: '0xFFFEF9C3',
      tagTextColor: '0xFFA16207',
      image: 'assets/images/opportunity_5.png',
      distance: '1.2 km',
      volunteersJoined: 9,
      volunteersNeeded: 15,
    ),
    DummyOpportunity(
      title: 'Senior Care Companion Visit',
      organization: 'ElderCare Alliance',
      location: 'Sunrise Senior Living',
      date: 'Mon, Apr 28',
      time: '2:00 PM - 5:00 PM',
      tag: 'healthcare',
      tagEmoji: '❤️',
      tagBgColor: '0xFFFEE2E2',
      tagTextColor: '0xFFB91C1C',
      image: 'assets/images/opportunity_6.png',
      distance: '1.2 km',
      volunteersJoined: 4,
      volunteersNeeded: 12,
    ),
  ];
}
