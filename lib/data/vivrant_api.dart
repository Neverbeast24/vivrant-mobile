import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../shared/models/models.dart';

part 'api/auth_api.dart';
part 'api/today_api.dart';
part 'api/nutrition_api.dart';
part 'api/movement_api.dart';
part 'api/gym_api.dart';
part 'api/wellness_api.dart';
part 'api/household_api.dart';
part 'api/ai_api.dart';
part 'api/profile_api.dart';
part 'api/admin_api.dart';

final vivrantApiProvider = Provider<VivrantApi>((ref) {
  return VivrantApi(ref.watch(apiClientProvider));
});

/// Typed wrappers for `/api/mobile/*` endpoints (see docs/MOBILE_API_SPEC.md).
///
/// Domain methods live in `lib/data/api/*` as same-library extensions.
class VivrantApi {
  VivrantApi(this._client);

  final ApiClient _client;
}
