import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String? userId;
  final String name;
  final String type; // 'income' | 'expense'
  final String icon;
  final String color;
  final bool isDefault;

  CategoryModel({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'],
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
      icon: json['icon'] ?? 'category',
      color: json['color'] ?? '#3B82F6',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
    };
  }

  Color get parsedColor {
    try {
      final hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF3B82F6);
  }

  IconData get iconData {
    switch (icon) {
      case 'work':
        return Icons.work_rounded;
      case 'domain':
        return Icons.domain_rounded;
      case 'laptop_mac':
        return Icons.laptop_mac_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'apartment':
        return Icons.apartment_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'flash_on':
        return Icons.flash_on_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'book':
        return Icons.book_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'work', 'icon': Icons.work_rounded, 'label': 'Work'},
    {'name': 'domain', 'icon': Icons.domain_rounded, 'label': 'Business'},
    {'name': 'laptop_mac', 'icon': Icons.laptop_mac_rounded, 'label': 'Freelance'},
    {'name': 'trending_up', 'icon': Icons.trending_up_rounded, 'label': 'Investment'},
    {'name': 'apartment', 'icon': Icons.apartment_rounded, 'label': 'Rental'},
    {'name': 'account_balance_wallet', 'icon': Icons.account_balance_wallet_rounded, 'label': 'Wallet'},
    {'name': 'restaurant', 'icon': Icons.restaurant_rounded, 'label': 'Food'},
    {'name': 'directions_car', 'icon': Icons.directions_car_rounded, 'label': 'Transport'},
    {'name': 'home', 'icon': Icons.home_rounded, 'label': 'Home'},
    {'name': 'flash_on', 'icon': Icons.flash_on_rounded, 'label': 'Utilities'},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag_rounded, 'label': 'Shopping'},
    {'name': 'medical_services', 'icon': Icons.medical_services_rounded, 'label': 'Health'},
    {'name': 'school', 'icon': Icons.school_rounded, 'label': 'Education'},
    {'name': 'movie', 'icon': Icons.movie_rounded, 'label': 'Entertainment'},
    {'name': 'flight', 'icon': Icons.flight_rounded, 'label': 'Travel'},
    {'name': 'credit_card', 'icon': Icons.credit_card_rounded, 'label': 'Loans/Card'},
    {'name': 'people', 'icon': Icons.people_rounded, 'label': 'Family'},
    {'name': 'fitness_center', 'icon': Icons.fitness_center_rounded, 'label': 'Fitness'},
    {'name': 'book', 'icon': Icons.book_rounded, 'label': 'Books'},
  ];

  static const List<String> presetColors = [
    '#3B82F6', // Blue
    '#06B6D4', // Cyan
    '#10B981', // Green
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#14B8A6', // Teal
    '#F97316', // Orange
    '#6366F1', // Indigo
  ];
}
