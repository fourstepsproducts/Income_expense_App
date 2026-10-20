import '../../core/network/api_client.dart';
import '../models/category_model.dart';

class CategoryService {
  final ApiClient _client;

  CategoryService(this._client);

  Future<List<CategoryModel>> getCategories({String? type}) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;

    final response = await _client.get('/categories', queryParams: queryParams);
    final list = response['data'] as List? ?? [];
    return list.map((item) => CategoryModel.fromJson(item)).toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    final response = await _client.post('/categories', body: {
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    });
    return CategoryModel.fromJson(response['data']);
  }

  Future<CategoryModel> updateCategory({
    required String id,
    String? name,
    String? type,
    String? icon,
    String? color,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (type != null) body['type'] = type;
    if (icon != null) body['icon'] = icon;
    if (color != null) body['color'] = color;
    final response = await _client.put('/categories/$id', body: body);
    return CategoryModel.fromJson(response['data']);
  }

  Future<void> deleteCategory(String id) async {
    await _client.delete('/categories/$id');
  }
}
