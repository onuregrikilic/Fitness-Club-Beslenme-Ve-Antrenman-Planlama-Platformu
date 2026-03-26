import 'package:flutter/material.dart';
import 'package:fitness_club_mobile/models/food.dart';
import 'package:fitness_club_mobile/models/workout.dart';
import 'package:fitness_club_mobile/screens/dashboard_screen.dart';
import 'package:fitness_club_mobile/screens/nutrition_screen.dart';
import 'package:fitness_club_mobile/screens/workout_screen.dart';
import 'package:fitness_club_mobile/screens/tracking_screen.dart';
import 'package:fitness_club_mobile/services/recommendation_engine.dart';

void main() {
  runApp(const FitnessClubApp());
}

class FitnessClubApp extends StatelessWidget {
  const FitnessClubApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Club Pro',
      debugShowCheckedModeBanner: false,
      // TEMA SADELEŞTİRİLDİ - ARTIK HATA VERMEZ4
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const MainSkeleton(),
    );
  }
}

class MainSkeleton extends StatefulWidget {
  const MainSkeleton({super.key});
  @override
  State<MainSkeleton> createState() => _MainSkeletonState();
}

class _MainSkeletonState extends State<MainSkeleton> {
  int _currentIndex = 0;
  double _targetCalories = 0;
  double _proteinGoal = 0;
  double _carbGoal = 0;
  double _fatGoal = 0;
  String _currentGoal = "Hedef Bekleniyor";
  BudgetLevel _userBudget = BudgetLevel.medium;
  bool _isLactose = false;
  bool _isGluten = false;
  bool _isDiabetes = false;
  CuisineType _cuisine = CuisineType.global;
  List<WorkoutDay> _workoutPlan = [];
  bool _isWorkoutCreated = false;
  double _currentWeight = 0;
  
  // Shared Tracking State
  List<bool> _workoutHistory = [false, false, false, false, false, false, false]; 
  List<bool> _dietHistory = [false, false, false, false, false, false, false];
  
  // Gamification State
  int _xp = 0;
  int _level = 1;
  String _rank = "Başlangıç";
  
  // Weight History
  List<double> _weights = [82.5, 82.1, 81.8, 81.4, 81.2, 80.9];
  
  // Cycle State
  int _planDayCount = 1; // Starts at Day 1

  void _gainXP(int amount) {
    setState(() {
      _xp += amount;
      // Simple leveling: Level * 1000 XP needed for next level
      int nextLevelXp = _level * 500;
      if (_xp >= nextLevelXp) {
        _level++;
        _xp -= nextLevelXp;
        _rank = _getLevelTitle(_level);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("TEBRİKLER! SEVİYE ATLADIN! 🎉 Yeni Seviye: $_level ($_rank)"),
          backgroundColor: Colors.amber,
          duration: const Duration(seconds: 4),
        ));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("+$amount XP Kazandın!"),
          backgroundColor: Colors.indigoAccent,
          duration: const Duration(milliseconds: 1500),
        ));
      }
    });
  }

  String _getLevelTitle(int lvl) {
    if(lvl >= 50) return "Efsane";
    if(lvl >= 30) return "Olimpik Sporcu";
    if(lvl >= 20) return "Elit Atlet";
    if(lvl >= 10) return "Profesyone";
    if(lvl >= 5) return "Düzenli Sporcu";
    if(lvl >= 2) return "Hırslı Çaylak";
    return "Başlangıç";
  }

  void _updateGoals(double cal, double p, double c, double f, String g, BudgetLevel b, bool l, bool glu, bool dia, CuisineType cui) {
    setState(() {
      _targetCalories = cal; _proteinGoal = p; _carbGoal = c; _fatGoal = f; _currentGoal = g;
      _userBudget = b; _isLactose = l; _isGluten = glu; _isDiabetes = dia; _cuisine = cui;
    });
  }

  void _setWorkout(List<WorkoutDay> plan) {
    setState(() { _workoutPlan = plan; _isWorkoutCreated = true; });
  }

  void _handleCheckIn(bool isWorkout, bool val) {
    setState(() {
       if (isWorkout) _workoutHistory[0] = val;
       else _dietHistory[0] = val;
    });
    if(val) _gainXP(isWorkout ? 50 : 25); // Manual checkin small reward
  }
  
  void _handleWorkoutComplete() {
      // Mark today as done!
      _handleCheckIn(true, true);
      _gainXP(150); // Big reward + bonus (total 200 with checkin)
  }

  void _handleWeightUpdate(double w) {
     double prevW = _weights.isNotEmpty ? _weights.last : w;
     setState(() {
         _currentWeight = w;
         _weights.add(w);
         if(_weights.length > 7) _weights.removeAt(0);
         _gainXP(50);
     });
     
     // Immediate Check (Feedback for user action)
     _checkForRevision(prevW, w, isPeriodic: false);
  }

  void _checkForRevision(double prevW, double currentW, {required bool isPeriodic}) {
     if (_targetCalories == 0) return;
     
     // Detect goal
     String goal = (_currentGoal.contains("Ver") || _currentGoal.contains("Cut") || _currentGoal.contains("Yak")) ? 'Ver' : 
                   ((_currentGoal.contains("Al") || _currentGoal.contains("Bulk") || _currentGoal.contains("Kaz")) ? 'Al' : 'Koru');
                   
     // Calculate suggestion
     double newCal = RecommendationEngine.calculateAdjustment(
        currentCalories: _targetCalories,
        startWeight: prevW, // Compare with last week or last entry
        currentWeight: currentW,
        goal: goal,
        daysElapsed: 7 // Simulate logic
     );
     
     if (newCal != _targetCalories) {
        // Show Dialog
        showDialog(context: context, builder: (c) => AlertDialog(
           title: Row(children: [const Icon(Icons.auto_awesome, color: Colors.purple), const SizedBox(width: 10), Text(isPeriodic ? "Haftalık Kontrol" : "Akıllı Koç Önerisi")]),
           content: Text(isPeriodic 
             ? "7 günü tamamladın! Kilo değişimine göre planını revize edelim mi?\n\n" 
             : "Kilo değişimine göre planını güncellememizi ister misin?\n\n"
             "Eski Hedef: ${_targetCalories.round()} kcal\n"
             "Yeni Öneri: ${newCal.round()} kcal"
           ),
           actions: [
              TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Hayır")),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white), onPressed: () {
                 // Update Logic
                 double pR = _proteinGoal * 4 / _targetCalories;
                 double cR = _carbGoal * 4 / _targetCalories;
                 double fR = _fatGoal * 9 / _targetCalories;
                 if(_targetCalories == 0) { pR=0.3; cR=0.35; fR=0.35; }

                 setState(() {
                    _targetCalories = newCal;
                    _proteinGoal = (newCal * pR) / 4;
                    _carbGoal = (newCal * cR) / 4;
                    _fatGoal = (newCal * fR) / 9;
                    _xp += 100;
                 });
                 Navigator.pop(c);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Planın güncellendi!")));
              }, child: const Text("Uygula"))
           ]
        ));
     }
  }

  void _advanceDay() {
    setState(() {
      // 1. Shift History
      _workoutHistory.insert(0, false);
      _workoutHistory.removeLast();
      _dietHistory.insert(0, false);
      _dietHistory.removeLast();
      
      // 2. Increment Day Count
      _planDayCount++;
      
      // 3. Check for 21-Day Cycle
      if (_planDayCount > 21) {
         _showCycleCompleteDialog();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("☀️ Günaydın! Planın $_planDayCount. Gününe başladın."),
          backgroundColor: Colors.orangeAccent,
        ));
        
        // NEW: Specific check on Day 7, 14, etc.
        if (_planDayCount % 7 == 1) { // e.g. Day 8 (completed 7 days)
            // Trigger periodic check using first and last weight of history
            if(_weights.isNotEmpty) {
               double startW = _weights.first;
               double endW = _weights.last;
               // We need slight delay to show dialog after snackbar/transition
               Future.delayed(const Duration(seconds: 1), () {
                   _checkForRevision(startW, endW, isPeriodic: true);
               });
            }
        }
      }
    });
  }
  
  void _showCycleCompleteDialog() {
     showDialog(
       context: context,
       barrierDismissible: false, // User MUST update
       builder: (ctx) => AlertDialog(
         title: const Text("Tebrikler! 21 Gün Tamamlandı! 🏆"),
         content: const Text(
           "Harika bir iş çıkardın ve bir alışkanlık kazandın!\n\n"
           "Vücudun artık 21 gün öncesiyle aynı değil. Gelişimini sürdürmek için vücut ölçülerini ve hedeflerini güncellemeliyiz.\n\n"
           "Hazır mısın?"
         ),
         actions: [
           ElevatedButton(
             onPressed: () {
               setState(() {
                 // Reset goals to 0 triggers the InputForm in Dashboard
                 _targetCalories = 0; 
                 // Reset Day Count
                 _planDayCount = 1;
                 // Note: We KEEP _xp and _level!
               });
               Navigator.pop(ctx); // Close dialog
               // Switch to Dashboard tab (Index 0)
               // Since we are using basic setState navigation, user might be on any tab. 
               // Assuming navigation structure relies on `screens` being rebuilt.
               // We don't have a TabController here, but since the screens are rebuilt, 
               // if the user is on Dashboard, they will see the form. 
               // If they are on other tabs, they will see empty data.
             },
             child: const Text("Ölçüleri Güncelle & Devam Et"),
           )
         ],
       )
     );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        targetCalories: _targetCalories, protein: _proteinGoal, carb: _carbGoal, fat: _fatGoal, goalName: _currentGoal,
        userBudget: _userBudget, isLactose: _isLactose, isGluten: _isGluten, isDiabetes: _isDiabetes, cuisine: _cuisine, onUpdate: _updateGoals,
        currentWeight: _currentWeight, onWeightUpdate: (w)=>setState(() { _currentWeight=w; _gainXP(50); }),
        xp: _xp, level: _level, rank: _rank,
        onNextDay: _advanceDay, // Pass the function
      ),
      NutritionScreen(
        dailyCalories: _targetCalories, proteinGoal: _proteinGoal, carbGoal: _carbGoal, fatGoal: _fatGoal,
        userBudget: _userBudget, isLactose: _isLactose, isGluten: _isGluten, cuisine: _cuisine
      ),
      WorkoutScreen(
        goalName: _currentGoal, workoutPlan: _workoutPlan, isCreated: _isWorkoutCreated, 
        onPlanCreated: _setWorkout, onWorkoutComplete: _handleWorkoutComplete
      ),
      TrackingScreen(
        workoutPlan: _workoutPlan, targetCalories: _targetCalories, proteinGoal: _proteinGoal, goalName: _currentGoal, 
        onWeightUpdate: _handleWeightUpdate,
        workoutHistory: _workoutHistory, dietHistory: _dietHistory, onCheckIn: _handleCheckIn,
        weightHistory: _weights,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Durum'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), label: 'Beslenme'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), label: 'Antrenman'),
          NavigationDestination(icon: Icon(Icons.checklist_rtl), label: 'Takip'),
        ],
      ),
    );
  }
}