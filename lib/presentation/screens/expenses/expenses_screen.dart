import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/calculations/meal_rate_calculator.dart';
import '../../../data/models/expense.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/empty_state_view.dart';
import 'add_expense_screen.dart';
import 'add_bazar_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExpenseCategory? _selectedCategory;

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

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.bazar:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.cleaning:
        return Icons.cleaning_services_rounded;
      case ExpenseCategory.repair:
        return Icons.build_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_bus_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();
    final expenses = messProvider.expenses;
    final totalFood = messProvider.financialResult?.totalFoodAndBazar ?? 0.0;
    final totalOther = messProvider.financialResult?.totalOtherExpenses ?? 0.0;

    final filteredExpenses = _selectedCategory == null
        ? expenses
        : expenses.where((e) => e.category == _selectedCategory).toList();

    // Flattened bazar items
    final allBazarItems = <Map<String, dynamic>>[];
    for (final exp in expenses) {
      for (final item in exp.bazarItems) {
        allBazarItems.add({
          'item': item,
          'expense': exp,
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('expenses')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: context.tr('expenses')),
            Tab(text: context.tr('bazar_items')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
            tooltip: 'Add Bazar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBazarScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'Add Expense',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: General Expenses
          Column(
            children: [
              // Category filter pills
              Container(
                height: 52,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) => setState(() => _selectedCategory = null),
                        selectedColor: AppColors.primaryContainer,
                      ),
                    ),
                    ...ExpenseCategory.values.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      String label;
                      switch (cat) {
                        case ExpenseCategory.bazar:
                          label = context.tr('bazar');
                          break;
                        case ExpenseCategory.food:
                          label = context.tr('food');
                          break;
                        case ExpenseCategory.cleaning:
                          label = context.tr('cleaning');
                          break;
                        case ExpenseCategory.repair:
                          label = context.tr('repair');
                          break;
                        case ExpenseCategory.transport:
                          label = context.tr('transport');
                          break;
                        case ExpenseCategory.other:
                          label = 'Other';
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          selectedColor: AppColors.primaryContainer,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // KPI Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surfaceVariant,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Food/Bazar: ${CurrencyFormatter.format(totalFood)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                      ),
                    ),
                    Text(
                      'Other: ${CurrencyFormatter.format(totalOther)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // List of Expenses
              Expanded(
                child: filteredExpenses.isEmpty
                    ? EmptyStateView(
                        icon: Icons.receipt_long_rounded,
                        title: 'No expenses found',
                        message: 'Record bazar and flat expenses to keep track of shared spending.',
                        buttonText: context.tr('add_expense'),
                        onButtonPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredExpenses.length,
                        itemBuilder: (ctx, i) {
                          final exp = filteredExpenses[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: exp.isFoodOrBazar
                                        ? AppColors.primaryContainer
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(exp.category),
                                    size: 20,
                                    color: exp.isFoodOrBazar ? AppColors.primaryDark : AppColors.neutral,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exp.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${exp.paidByName ?? "Member"} • ${DateFormatter.formatShortDate(exp.expenseDate)}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                      ),
                                      if (exp.bazarItems.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${exp.bazarItems.length} items purchased',
                                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(exp.amount),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.neutral),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        final cycleId = messProvider.selectedCycle?.id ?? 'cycle_current';
                                        messProvider.deleteExpense(exp.id, cycleId: cycleId);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // TAB 2: Itemized Bazar List
          allBazarItems.isEmpty
              ? EmptyStateView(
                  icon: Icons.shopping_basket_rounded,
                  title: 'No bazar items recorded',
                  message: 'Add itemized bazar details (e.g. Rice 5kg, Eggs 12pcs, Vegetables ৳280).',
                  buttonText: 'Add Bazar Items',
                  onButtonPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddBazarScreen()),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allBazarItems.length,
                  itemBuilder: (ctx, i) {
                    final item = allBazarItems[i]['item'] as dynamic;
                    final exp = allBazarItems[i]['expense'] as Expense;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.restaurant, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantity} ${item.unit} • ${exp.paidByName ?? "Member"} • ${DateFormatter.formatShortDate(exp.expenseDate)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(item.price),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddBazarScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text('Add Bazar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
