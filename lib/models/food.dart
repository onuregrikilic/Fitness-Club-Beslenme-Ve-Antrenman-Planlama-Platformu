

enum BudgetLevel { low, medium, high }
enum MealType { breakfast, main }
enum CuisineType { turkish, global }

class Food {
  final String name;
  final double calories; // 100g için
  final double protein;
  final double carb;
  final double fat;
  final String type;
  final BudgetLevel budget;
  final MealType mealType;
  final bool isLactoseFree;
  final bool isGlutenFree;
  final CuisineType cuisine;

  const Food({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.type,
    required this.budget,
    required this.mealType,
    this.isLactoseFree = true,
    this.isGlutenFree = true,
    this.cuisine = CuisineType.global,
  });
}
