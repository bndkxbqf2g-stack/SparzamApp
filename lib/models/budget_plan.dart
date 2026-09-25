class BudgetPlan {
  const BudgetPlan({
    this.monthlyBudget = 0,
    this.foodBudget = 0,
    this.foodSpent = 0,
  });

  final double monthlyBudget;
  final double foodBudget;
  final double foodSpent;

  bool get isConfigured => monthlyBudget > 0 || foodBudget > 0;

  BudgetPlan copyWith({
    double? monthlyBudget,
    double? foodBudget,
    double? foodSpent,
  }) =>
      BudgetPlan(
        monthlyBudget: monthlyBudget ?? this.monthlyBudget,
        foodBudget: foodBudget ?? this.foodBudget,
        foodSpent: foodSpent ?? this.foodSpent,
      );
}
