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

  Future<NutritionLog> updateMeal(int id, Map<String, dynamic> body) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/api/mobile/nutrition/meals/$id',
      data: body,
    );
    return NutritionLog.fromJson(
      Map<String, dynamic>.from(res.data?['meal'] ?? res.data ?? {}),
    );
  }

  Future<Map<String, dynamic>> estimateMealAi(
    String description, {
    String? photoPath,
  }) async {
    if (photoPath != null && photoPath.isNotEmpty) {
      final name = photoPath.split(RegExp(r'[\\/]')).last;
      final mime = imageMediaType(name);
      final ext = mime.subtype == 'jpeg' ? 'jpg' : mime.subtype;
      final form = FormData.fromMap({
        'description': description,
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: 'meal.$ext',
          contentType: mime,
        ),
      });
      final res = await _client.postMultipart<Map<String, dynamic>>(
        '/api/mobile/nutrition/estimate',
        form,
        options: ApiClient.aiOptions,
      );
      return Map<String, dynamic>.from(res.data ?? {});
    }

    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/nutrition/estimate',
      data: {'description': description},
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  /// BMI-aware next-meal idea from pantry + today's logs.
  Future<Map<String, dynamic>> suggestMealAi() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/nutrition/suggest',
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<void> addWater(int ml) async {
    await _client.post('/api/mobile/nutrition/water', data: {'ml': ml});
  }
}
