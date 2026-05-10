import 'package:backpackr/features/meetups/models/meetup.dart';

class NearbyMeetupsResult {
  const NearbyMeetupsResult({
    required this.meetups,
    required this.organizerDistances,
  });

  final List<Meetup> meetups;
  final Map<String, double> organizerDistances;
}
