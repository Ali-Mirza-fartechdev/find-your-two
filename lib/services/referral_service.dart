import '../models/referral.dart';

/// Referral endpoint is not available in the current API.
/// This service is stubbed and returns empty data until the backend adds it.
class ReferralService {

  Future<List<Referral>> getReferrals({
    int page = 1,
    int perPage = 20,
  }) async {
    return [];
  }
}
