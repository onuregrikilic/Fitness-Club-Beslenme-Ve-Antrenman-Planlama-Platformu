
class RecommendationEngine {
  /// Calculates personalized calorie and macro targets based on biometrics and goals.
  /// This implements the "Constraint Optimization" logic conceptually by adjusting
  /// ratios based on constraints (Medical) and Objectives (Goal).
  static Map<String, double> calculateTargets({
    required double weight,
    required double height, // in cm
    required int age,
    required String gender,
    required double activityLevel,
    required String goal, // 'Ver', 'Al', 'Koru'
    required List<String> medicalConditions, // ['Diyabet', 'Laktoz', 'Gluten', etc.]
  }) {
    // 1. Calculate BMR (Mifflin-St Jeor Equation)
    // Men: (10 × weight) + (6.25 × height) - (5 × age) + 5
    // Women: (10 × weight) + (6.25 × height) - (5 × age) - 161
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    bmr += (gender == 'Erkek') ? 5 : -161;

    // 2. Calculate TDEE (Total Daily Energy Expenditure)
    double tdee = bmr * activityLevel;

    // 3. Adjust for Goal (Caloric Deficit/Surplus)
    double targetCalories = tdee;
    if (goal == 'Ver') {
      targetCalories -= 500; // Standard cut
    } else if (goal == 'Al') {
      targetCalories += 300; // Standard lean bulk
    }

    // 4. Macro Distribution (Optimization Logic)
    // Default Ratios (Balanced)
    double pRatio = 0.30; // Protein
    double cRatio = 0.35; // Carb
    double fRatio = 0.35; // Fat

    // Goal Based Adjustments
    if (goal == 'Al') {
      // Bulking needs more carbs for energy
      pRatio = 0.25;
      cRatio = 0.55;
      fRatio = 0.20;
    } else if (goal == 'Ver') {
      // Cutting needs high protein to spare muscle
      pRatio = 0.40;
      cRatio = 0.25;
      fRatio = 0.35;
    }

    // Medical Constraint Adjustments (The "Optimization" part)
    // If Diabetes is present, we MUST constrain Carbs to prevent spikes.
    if (medicalConditions.contains('Diyabet')) {
      // Strict Carb Cap. Increase Fats and Protein slightly to compensate.
      // If current carb ratio is high (>30%), clamp it.
      if (cRatio > 0.30) {
        double diff = cRatio - 0.30;
        cRatio = 0.30;
        // Redistribute difference to healthy fats and protein
        fRatio += diff * 0.7; // Mostly fat (keto-ish lean)
        pRatio += diff * 0.3;
      }
    }

    // Ensure Ratios sum to 1.0 (Normalization)
    double total = pRatio + cRatio + fRatio;
    pRatio = pRatio / total;
    cRatio = cRatio / total;
    fRatio = fRatio / total;

    // 5. Convert to Grams
    // Protein = 4 kcal/g, Carb = 4 kcal/g, Fat = 9 kcal/g
    double proteinGrams = (targetCalories * pRatio) / 4;
    double carbGrams = (targetCalories * cRatio) / 4;
    double fatGrams = (targetCalories * fRatio) / 9;

    return {
      "calories": targetCalories,
      "protein": proteinGrams,
      "carb": carbGrams,
      "fat": fatGrams,
    };
  }

  /// Calculates a revised calorie target based on weight progress.
  static double calculateAdjustment({
    required double currentCalories,
    required double startWeight,
    required double currentWeight,
    required String goal, // 'Ver', 'Al', 'Koru'
    required int daysElapsed,
  }) {
    // If not enough time passed (e.g. less than 5 days), don't adjust yet.
    if (daysElapsed < 5) return currentCalories;

    double diff = currentWeight - startWeight;
    double adjustment = 0;

    if (goal == 'Ver') {
       // Goal: Lose weight. Difference should be negative.
       // Expected: ~0.3 - 0.5 kg loss per week.
       if (diff >= 0) {
         // Not losing weight or gained weight -> Cut more calories
         adjustment = -200;
       } else if (diff < -1.5) {
         // Losing too fast (>1.5kg in a week approx) -> Increase slightly to muscle spare
         adjustment = 100;
       }
    } else if (goal == 'Al') {
       // Goal: Gain weight (Muscle). Difference should be positive.
       // Expected: ~0.2 - 0.4 kg gain per week.
       if (diff <= 0) {
         // Not gaining -> Increase calories
         adjustment = 250;
       } else if (diff > 1.0) {
         // Gaining too fast (likely fat) -> Decrease surplus
         adjustment = -150;
       }
    }

    return currentCalories + adjustment;
  }
}
