import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../shared/models/category_model.dart';
import '../../shared/providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCategoryDialog({CategoryModel? categoryToEdit, required String defaultType}) {
    final nameController = TextEditingController(text: categoryToEdit?.name ?? '');
    String selectedIcon = categoryToEdit?.icon ?? 'category';
    String selectedColor = categoryToEdit?.color ?? '#3B82F6';
    String selectedType = categoryToEdit?.type ?? defaultType;
    final isEditing = categoryToEdit != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Edit Category' : 'Create Category',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g. Books, Subscriptions',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type Selector
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Expense')),
                            selected: selectedType == 'expense',
                            selectedColor: AppColors.expenseRedBg,
                            onSelected: isEditing ? null : (_) => setModalState(() => selectedType = 'expense'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Income')),
                            selected: selectedType == 'income',
                            selectedColor: AppColors.incomeGreenBg,
                            onSelected: isEditing ? null : (_) => setModalState(() => selectedType = 'income'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Icon Picker
                    const Text('Select Icon', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: CategoryModel.availableIcons.map((item) {
                        final isSel = item['name'] == selectedIcon;
                        return InkWell(
                          onTap: () => setModalState(() => selectedIcon = item['name']),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.vibrantBlue : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? AppColors.vibrantBlue : AppColors.border),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              size: 20,
                              color: isSel ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Color Picker Presets
                    const Text('Select Color', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: CategoryModel.presetColors.map((colorHex) {
                        final isSel = colorHex.toLowerCase() == selectedColor.toLowerCase();
                        final color = Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = colorHex),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSel ? Border.all(color: Colors.white, width: 2.5) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        Navigator.pop(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        final catService = ref.read(categoryServiceProvider);

                        try {
                          if (isEditing) {
                            await catService.updateCategory(
                              id: categoryToEdit.id,
                              name: name,
                              type: selectedType,
                              icon: selectedIcon,
                              color: selectedColor,
                            );
                          } else {
                            await catService.createCategory(
                              name: name,
                              type: selectedType,
                              icon: selectedIcon,
                              color: selectedColor,
                            );
                          }

                          ref.invalidate(categoriesProvider);

                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(isEditing ? 'Category updated' : 'Category created'),
                                backgroundColor: AppColors.incomeGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.expenseRed,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(isEditing ? 'Update Category' : 'Create Category'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Category?',
      message: 'Delete "${category.name}"? This is only allowed if no transactions currently use this category.',
      confirmText: 'Delete',
    );

    if (!confirmed || !mounted) return;

    try {
      await ref.read(categoryServiceProvider).deleteCategory(category.id);
      ref.invalidate(categoriesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully'),
            backgroundColor: AppColors.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.expenseRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.vibrantBlue,
          labelColor: AppColors.vibrantBlue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.vibrantBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () {
          final defaultType = _tabController.index == 0 ? 'expense' : 'income';
          _openCategoryDialog(defaultType: defaultType);
        },
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.vibrantBlue)),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) {
          final expenseCats = categories.where((c) => c.type == 'expense').toList();
          final incomeCats = categories.where((c) => c.type == 'income').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenseCats, 'expense'),
              _buildCategoryList(incomeCats, 'income'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, String type) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No $type categories found',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cat = categories[index];
        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cat.parsedColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat.iconData, color: cat.parsedColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat.isDefault ? 'Default Category' : 'Custom Category',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (!cat.isDefault) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                  onPressed: () => _openCategoryDialog(categoryToEdit: cat, defaultType: type),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.expenseRed),
                  onPressed: () => _deleteCategory(cat),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
