import 'package:fitness_club_mobile/models/food.dart';

final List<Food> foodDatabase = [
  // KAHVALTI
  const Food(name: "Haşlanmış Yumurta", calories: 155, protein: 13, carb: 1.1, fat: 11, type: 'protein', budget: BudgetLevel.low, mealType: MealType.breakfast),
  const Food(name: "Lor Peyniri", calories: 98, protein: 11, carb: 3.4, fat: 4, type: 'protein', budget: BudgetLevel.low, mealType: MealType.breakfast, isLactoseFree: false, cuisine: CuisineType.turkish),
  const Food(name: "Ezine Peyniri", calories: 280, protein: 18, carb: 2, fat: 20, type: 'protein', budget: BudgetLevel.medium, mealType: MealType.breakfast, isLactoseFree: false, cuisine: CuisineType.turkish),
  const Food(name: "Hindi Füme", calories: 110, protein: 22, carb: 2, fat: 1, type: 'protein', budget: BudgetLevel.medium, mealType: MealType.breakfast),
  const Food(name: "Yulaf Ezmesi", calories: 370, protein: 13, carb: 59, fat: 7, type: 'carb', budget: BudgetLevel.low, mealType: MealType.breakfast, isGlutenFree: false),
  const Food(name: "Tam Buğday Ekmeği", calories: 250, protein: 10, carb: 45, fat: 3, type: 'carb', budget: BudgetLevel.low, mealType: MealType.breakfast, isGlutenFree: false),
  const Food(name: "Simit (Çeyrek)", calories: 160, protein: 5, carb: 30, fat: 3, type: 'carb', budget: BudgetLevel.low, mealType: MealType.breakfast, isGlutenFree: false, cuisine: CuisineType.turkish),
  const Food(name: "Menemen", calories: 120, protein: 7, carb: 6, fat: 8, type: 'protein', budget: BudgetLevel.medium, mealType: MealType.breakfast, cuisine: CuisineType.turkish),
  const Food(name: "Sade Omlet", calories: 150, protein: 11, carb: 1, fat: 12, type: 'protein', budget: BudgetLevel.low, mealType: MealType.breakfast),
  const Food(name: "Beyaz Peynir", calories: 250, protein: 16, carb: 2, fat: 20, type: 'protein', budget: BudgetLevel.medium, mealType: MealType.breakfast, isLactoseFree: false, cuisine: CuisineType.turkish),
  const Food(name: "Dil Peyniri", calories: 280, protein: 22, carb: 2, fat: 22, type: 'protein', budget: BudgetLevel.medium, mealType: MealType.breakfast, isLactoseFree: false, cuisine: CuisineType.turkish),
  
  const Food(name: "Avokado Toast", calories: 220, protein: 5, carb: 20, fat: 15, type: 'carb', budget: BudgetLevel.high, mealType: MealType.breakfast),
  const Food(name: "Granola", calories: 400, protein: 10, carb: 60, fat: 15, type: 'carb', budget: BudgetLevel.medium, mealType: MealType.breakfast, isGlutenFree: false),
  const Food(name: "Pancake", calories: 220, protein: 6, carb: 30, fat: 8, type: 'carb', budget: BudgetLevel.low, mealType: MealType.breakfast, isGlutenFree: false),
  
  // ANA YEMEK (PROTEİN)
  const Food(name: "Tavuk Göğsü", calories: 165, protein: 31, carb: 0, fat: 3.6, type: 'protein', budget: BudgetLevel.low, mealType: MealType.main),
  const Food(name: "Kuru Fasulye", calories: 340, protein: 21, carb: 63, fat: 1, type: 'protein', budget: BudgetLevel.low, mealType: MealType.main, cuisine: CuisineType.turkish),
  const Food(name: "Ton Balığı", calories: 120, protein: 26, carb: 0, fat: 1, type: 'protein', budget: BudgetLevel.medium, mealType: MealType.main),
  const Food(name: "Dana Kıyma (Az Yağlı)", calories: 250, protein: 26, carb: 0, fat: 15, type: 'protein', budget: BudgetLevel.medium, mealType: MealType.main),
  const Food(name: "Somon Balığı", calories: 208, protein: 20, carb: 0, fat: 13, type: 'protein', budget: BudgetLevel.high, mealType: MealType.main),
  const Food(name: "Izgara Köfte", calories: 250, protein: 24, carb: 4, fat: 17, type: 'protein', budget: BudgetLevel.medium, mealType: MealType.main, cuisine: CuisineType.turkish),
  const Food(name: "Bonfile Izgara", calories: 190, protein: 28, carb: 0, fat: 9, type: 'protein', budget: BudgetLevel.high, mealType: MealType.main),
  const Food(name: "Levrek Buğulama", calories: 120, protein: 23, carb: 2, fat: 3, type: 'protein', budget: BudgetLevel.high, mealType: MealType.main),
  const Food(name: "Yeşil Mercimek Yemeği", calories: 116, protein: 9, carb: 20, fat: 0.5, type: 'protein', budget: BudgetLevel.low, mealType: MealType.main),
  const Food(name: "Etli Nohut", calories: 160, protein: 10, carb: 18, fat: 6, type: 'protein', budget: BudgetLevel.low, mealType: MealType.main, cuisine: CuisineType.turkish),
  const Food(name: "Fırın Tavuk But", calories: 180, protein: 24, carb: 0, fat: 10, type: 'protein', budget: BudgetLevel.low, mealType: MealType.main),
  const Food(name: "Karnıyarık", calories: 150, protein: 8, carb: 8, fat: 12, type: 'protein', budget: BudgetLevel.medium, mealType: MealType.main, cuisine: CuisineType.turkish),

  // ANA YEMEK (KARBONHİDRAT)
  const Food(name: "Pirinç Pilavı", calories: 130, protein: 2.7, carb: 28, fat: 0.3, type: 'carb', budget: BudgetLevel.low, mealType: MealType.main, cuisine: CuisineType.turkish),
  const Food(name: "Bulgur Pilavı", calories: 110, protein: 3, carb: 25, fat: 0.5, type: 'carb', budget: BudgetLevel.low, mealType: MealType.main, isGlutenFree: false, cuisine: CuisineType.turkish),
  const Food(name: "Makarna", calories: 158, protein: 6, carb: 31, fat: 1, type: 'carb', budget: BudgetLevel.low, mealType: MealType.main, isGlutenFree: false),
  const Food(name: "Haşlanmış Patates", calories: 87, protein: 1.9, carb: 20, fat: 0.1, type: 'carb', budget: BudgetLevel.low, mealType: MealType.main),
  const Food(name: "Basmati Pirinç", calories: 120, protein: 3, carb: 25, fat: 0.4, type: 'carb', budget: BudgetLevel.medium, mealType: MealType.main),
  const Food(name: "Karabuğday", calories: 92, protein: 3, carb: 20, fat: 0.6, type: 'carb', budget: BudgetLevel.medium, mealType: MealType.main),
  const Food(name: "Kinoa", calories: 120, protein: 4, carb: 21, fat: 2, type: 'carb', budget: BudgetLevel.high, mealType: MealType.main),
  const Food(name: "Tatlı Patates", calories: 86, protein: 1.6, carb: 20, fat: 0.1, type: 'carb', budget: BudgetLevel.medium, mealType: MealType.main),
  const Food(name: "Erişte", calories: 138, protein: 4.5, carb: 28, fat: 1, type: 'carb', budget: BudgetLevel.low, mealType: MealType.main, isGlutenFree: false, cuisine: CuisineType.turkish),
  const Food(name: "Tam Buğday Makarna", calories: 124, protein: 5, carb: 27, fat: 0.5, type: 'carb', budget: BudgetLevel.low, mealType: MealType.main, isGlutenFree: false),
  const Food(name: "Sebzeli Kuskus", calories: 112, protein: 3.8, carb: 23, fat: 0.2, type: 'carb', budget: BudgetLevel.low, mealType: MealType.main, isGlutenFree: false),
];
