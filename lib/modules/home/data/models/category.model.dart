// lib/modules/home/data/models/category.model.dart
import 'package:rexone_mobile/constants/constants.dart';

/// Admin-managed atom category (a "molecule") shown on Home and in the
/// create-flow picker.
class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final int position;

  /// Kept atoms inside this molecule (server-computed, shown on home cards).
  final int atomsCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.description,
    this.position = 0,
    this.atomsCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json[ApiKeys.id]?.toString() ?? '',
      name: json[CategoryKeys.name]?.toString() ?? '',
      slug: json[CategoryKeys.slug]?.toString() ?? '',
      description: json[CategoryKeys.description]?.toString(),
      position: json[CategoryKeys.position] as int? ?? 0,
      atomsCount: json[CategoryKeys.atomsCount] as int? ?? 0,
    );
  }
}
