part of '../vivrant_api.dart';

extension VivrantNutritionApi on VivrantApi {
  Future<List<NutritionLog>> listMeals({String? date}) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/nutrition/meals',
      query: {if (date != null) 'date': date},
    );
    final list = res.data?['meals'] as List? ?? [];
    return list
        .map((e) => NutritionLog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<NutritionLog> logMeal(Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/nutrition/meals',
      data: body,
    );
    return NutritionLog.fromJson(
      Map<String, dynamic>.from(res.data?['meal'] ?? res.data ?? {}),
    );
  }

  Future<void> deleteMeal(int id) async {
    await _client.delete('/api/mobile/nutrition/meals/$id');
  }

  Future<Map<String, dynamic>> estimateMealAi(String description) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/nutrition/estimate',
      data: {'description': description},
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<void> addWater(int ml) async {
    await _client.post('/api/mobile/nutrition/water', data: {'ml': ml});
  }
}
