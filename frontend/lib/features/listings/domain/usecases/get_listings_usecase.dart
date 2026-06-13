import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/network/api_client.dart';

// ---------------------------------------------------------------------------
// GetListingsUseCase
// ---------------------------------------------------------------------------

/// Fetches a paginated, filterable list of property listings from the API.
///
/// Returns the raw `data` map which contains:
///   - `listings` (List): the page of listings
///   - `total` (int): total matching records
///   - `page` (int): current page
///   - `limit` (int): page size
class GetListingsUseCase {
  const GetListingsUseCase(this._ref);

  final Ref _ref;

  Future<Map<String, dynamic>> call({Map<String, dynamic>? params}) async {
    final dio = _ref.read(dioProvider);
    final response = await dio.get(
      '/v1/listings',
      queryParameters: params ?? {},
    );

    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) return data;
      // Some endpoints return the list directly under `data`
      if (data is List) {
        return {
          'listings': data,
          'total': data.length,
          'page': 1,
          'limit': data.length,
        };
      }
    }

    return {};
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final getListingsUseCaseProvider = Provider<GetListingsUseCase>((ref) {
  return GetListingsUseCase(ref);
});
