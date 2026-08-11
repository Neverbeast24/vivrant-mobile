part of '../vivrant_api.dart';

extension VivrantHouseholdApi on VivrantApi {
  Future<List<GroceryItem>> listGroceries() async {
    final res =
        await _client.get<Map<String, dynamic>>('/api/mobile/groceries');
    return (res.data?['items'] as List? ?? [])
        .map((e) => GroceryItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<GroceryItem> addGrocery(Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/groceries',
      data: body,
    );
    return GroceryItem.fromJson(
      Map<String, dynamic>.from(res.data?['item'] ?? res.data ?? {}),
    );
  }

  Future<void> toggleGrocery(int id, bool checked) async {
    await _client.patch(
      '/api/mobile/groceries/$id',
      data: {'is_checked': checked},
    );
  }

  Future<void> deleteGrocery(int id) async {
    await _client.delete('/api/mobile/groceries/$id');
  }

  Future<void> clearCompletedGroceries() async {
    await _client.post('/api/mobile/groceries/clear-completed');
  }

  Future<void> restockPantryFromChecked() async {
    await _client.post('/api/mobile/groceries/restock-pantry');
  }

  Future<Map<String, dynamic>> smartGroceryPlan() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/groceries/plan',
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<Map<String, dynamic>> estimateGroceryCostAi({
    required String name,
    String? quantity,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/groceries/estimate-cost',
      data: {
        'name': name,
        if (quantity != null && quantity.isNotEmpty) 'quantity': quantity,
      },
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<PantryItem>> listPantry() async {
    final res = await _client.get<Map<String, dynamic>>('/api/mobile/pantry');
    return (res.data?['items'] as List? ?? [])
        .map((e) => PantryItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PantryItem> addPantry(Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/pantry',
      data: body,
    );
    return PantryItem.fromJson(
      Map<String, dynamic>.from(res.data?['item'] ?? res.data ?? {}),
    );
  }

  Future<void> updatePantryStock(int id, int stockLevel) async {
    await _client.patch(
      '/api/mobile/pantry/$id',
      data: {'stock_level': stockLevel},
    );
  }

  Future<void> deletePantry(int id) async {
    await _client.delete('/api/mobile/pantry/$id');
  }

  Future<void> addLowStockToGrocery() async {
    await _client.post('/api/mobile/pantry/low-stock-to-grocery');
  }

  Future<Map<String, dynamic>> spendingOverview() async {
    final res =
        await _client.get<Map<String, dynamic>>('/api/mobile/spending');
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<Expense>> listExpenses() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/spending/expenses',
    );
    return (res.data?['expenses'] as List? ?? [])
        .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Expense> addExpense(Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/spending/expenses',
      data: body,
    );
    return Expense.fromJson(
      Map<String, dynamic>.from(res.data?['expense'] ?? res.data ?? {}),
    );
  }

  Future<void> deleteExpense(int id) async {
    await _client.delete('/api/mobile/spending/expenses/$id');
  }

  Future<void> saveBudget(double amount) async {
    await _client.put('/api/mobile/spending/budget', data: {'amount': amount});
  }

  Future<Map<String, dynamic>> coachSpending() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/spending/coach',
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }
}
