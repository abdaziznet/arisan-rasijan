import 'package:bani_rasijan/core/services/cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/period_model.dart';

class PeriodsRepository {
  PeriodsRepository({SupabaseClient? client, CacheService? cacheService})
      : _client = client ?? SupabaseConfig.client,
        _cache = cacheService ?? CacheService();

  final SupabaseClient _client;
  final CacheService _cache;
  static const _activePeriodCacheKey = 'activePeriod';

  Future<PeriodModel?> getActivePeriod() async {
    // Prioritas: data fresh dari server. Cache hanya fallback saat offline
    // (lihat PRD §7 — app harus tetap bisa dibuka walau sinyal lemah di lokasi acara).
    try {
      final response = await _client
          .from('arisan_periods')
          .select('*, host:profiles!host_id(*), winner:profiles!winner_id(*)')
          .inFilter('status', ['upcoming', 'ongoing'])
          .order('event_date', ascending: true)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        await _cache.saveData(_activePeriodCacheKey, response);
        return PeriodModel.fromJson(response);
      }

      // Server tidak punya periode aktif → buang cache lama supaya tidak
      // menampilkan data usang saat admin clear tabel.
      await _cache.removeData(_activePeriodCacheKey);
      return null;
    } catch (_) {
      // Gagal koneksi: fallback ke cache yang masih valid.
      final cached = await _cache.getData(_activePeriodCacheKey);
      if (cached == null) rethrow;
      return PeriodModel.fromJson(cached);
    }
  }

  Future<List<PeriodModel>> getPeriods() async {
    final response = await _client
        .from('arisan_periods')
        .select('*, host:profiles!host_id(*), winner:profiles!winner_id(*)')
        .order('period_number', ascending: false);

    final list = response as List<dynamic>;
    return list
        .map((json) => PeriodModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PeriodModel?> getLatestCompletedPeriod() async {
    final response = await _client
        .from('arisan_periods')
        .select('*, host:profiles!host_id(*), winner:profiles!winner_id(*)')
        .eq('status', 'completed')
        .not('winner_id', 'is', null)
        .order('event_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return PeriodModel.fromJson(response);
  }

  Future<PeriodModel> createPeriod(PeriodModel period) async {
    final payload = period.toJson();
    payload.remove('id');

    final response = await _client
        .from('arisan_periods')
        .insert(payload)
        .select('*, host:profiles!host_id(*), winner:profiles!winner_id(*)')
        .single();

    await _cache.saveData(_activePeriodCacheKey, response);
    return PeriodModel.fromJson(response);
  }

  Future<PeriodModel> updatePeriod(PeriodModel period) async {
    final response = await _client
        .from('arisan_periods')
        .update(period.toJson())
        .eq('id', period.id)
        .select('*, host:profiles!host_id(*), winner:profiles!winner_id(*)')
        .single();

    await _cache.saveData(_activePeriodCacheKey, response);
    return PeriodModel.fromJson(response);
  }
}
