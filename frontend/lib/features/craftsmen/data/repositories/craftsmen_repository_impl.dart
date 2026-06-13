import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/entities/craftsman.dart';
import '../../domain/repositories/craftsmen_repository.dart';
import '../datasources/craftsmen_remote_datasource.dart';

final craftsmenRepositoryProvider = Provider<CraftsmenRepository>(
  (ref) => CraftsmenRepositoryImpl(ref.watch(craftsmenRemoteDatasourceProvider)),
);

class CraftsmenRepositoryImpl implements CraftsmenRepository {
  const CraftsmenRepositoryImpl(this._datasource);

  final CraftsmenRemoteDatasource _datasource;

  @override
  Future<List<Craftsman>> getCraftsmen(CraftsmenFilters filters) async {
    return _datasource.getCraftsmen(filters);
  }

  @override
  Future<List<Craftsman>> searchCraftsmen(
    String query, {
    CraftsmenFilters? filters,
  }) async {
    return _datasource.searchCraftsmen(query, filters: filters);
  }

  @override
  Future<Craftsman> getCraftsmanById(String id) async {
    return _datasource.getCraftsmanById(id);
  }

  @override
  Future<Craftsman> createCraftsmanProfile(Map<String, dynamic> data) async {
    return _datasource.createCraftsmanProfile(data);
  }

  @override
  Future<Craftsman> updateCraftsmanProfile(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _datasource.updateCraftsmanProfile(id, data);
  }

  @override
  Future<void> deleteCraftsmanProfile(String id) async {
    return _datasource.deleteCraftsmanProfile(id);
  }

  @override
  Future<int> getCraftsmenCount(CraftsmenFilters filters) async {
    return _datasource.getCraftsmenCount(filters);
  }
}
