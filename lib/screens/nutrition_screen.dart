import 'package:flutter/material.dart';
import 'package:fitness_club_mobile/models/food.dart';
import 'package:fitness_club_mobile/data/food_data.dart';

class NutritionScreen extends StatefulWidget {
  final double dailyCalories; final double proteinGoal; final double carbGoal; final double fatGoal;
  final BudgetLevel userBudget; final bool isLactose; final bool isGluten; final CuisineType cuisine;
  const NutritionScreen({super.key, required this.dailyCalories, required this.proteinGoal, required this.carbGoal, required this.fatGoal, required this.userBudget, required this.isLactose, required this.isGluten, required this.cuisine});
  @override State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  late Food _bfP, _bfC, _lnP, _lnC, _dnP, _dnC;
  final Set<String> _dislikedItems = {};
  
  @override void didUpdateWidget(NutritionScreen old) { 
    super.didUpdateWidget(old); 
    if(old.userBudget!=widget.userBudget || old.dailyCalories!=widget.dailyCalories || old.cuisine!=widget.cuisine || old.isLactose!=widget.isLactose || old.isGluten!=widget.isGluten || old.proteinGoal!=widget.proteinGoal || old.carbGoal!=widget.carbGoal || old.fatGoal!=widget.fatGoal) {
      _init(); 
    }
  }
  @override void initState() { super.initState(); _init(); }

  void _init() {
    var bfP=_f('protein',MealType.breakfast); var bfC=_f('carb',MealType.breakfast); _bfP=bfP.isNotEmpty?bfP[0]:foodDatabase[0]; _bfC=bfC.isNotEmpty?bfC[0]:foodDatabase[4];
    var mP=_f('protein',MealType.main); var mC=_f('carb',MealType.main); _lnP=mP.isNotEmpty?mP[0]:foodDatabase[10]; _lnC=mC.isNotEmpty?mC[0]:foodDatabase[13];
    _dnP=mP.length>1?mP[1]:_lnP; _dnC=mC.length>1?mC[1]:_lnC;
  }
  
  List<Food> _f(String t, MealType m) {
    var list = foodDatabase.where((f) => 
      f.type==t && 
      f.mealType==m && 
      (widget.userBudget==BudgetLevel.high || (widget.userBudget==BudgetLevel.medium ? f.budget!=BudgetLevel.high : f.budget==BudgetLevel.low)) && 
      (!widget.isLactose||f.isLactoseFree) && 
      (!widget.isGluten||f.isGlutenFree) && 
      (widget.cuisine==CuisineType.global || f.cuisine==widget.cuisine || f.cuisine==CuisineType.global) &&
      !_dislikedItems.contains(f.name)
    ).toList();
    
    list.sort((a,b) {
      // 1. Cuisine priority: If user selected specific cuisine, prefer it.
      if (widget.cuisine != CuisineType.global) {
        if (a.cuisine == widget.cuisine && b.cuisine != widget.cuisine) return -1;
        if (a.cuisine != widget.cuisine && b.cuisine == widget.cuisine) return 1;
      }
      // 2. Budget priority: Prefer matches closest to user budget.
      // E.g. If specific budget selected, prefer exact match.
      if (a.budget == widget.userBudget && b.budget != widget.userBudget) return -1;
      if (a.budget != widget.userBudget && b.budget == widget.userBudget) return 1;
      return 0;
    });
    
    return list;
  }

  void _swap(String t, String m) {
    MealType mt = m=='bf'?MealType.breakfast:MealType.main; List<Food> l = _f(t, mt);
    showDialog(context: context, builder: (c)=>AlertDialog(title: const Text("Değiştir"), content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: l.length, itemBuilder: (c,i){
      final f=l[i]; 
      return ListTile(
        title: Text(f.name), 
        subtitle: Text("${f.calories} kcal/100g"), 
        onTap: (){ 
          setState((){ 
            if(m=='bf'){
              if(t=='protein') { _bfP=f; }
              else { _bfC=f; }
            } else if(m=='ln'){
              if(t=='protein') { _lnP=f; }
              else { _lnC=f; }
            } else {
              if(t=='protein') { _dnP=f; }
              else { _dnC=f; }
            } 
          }); 
          Navigator.pop(c); 
        }
      );
    }))));
  }

  Map<String, double> _smartCalc(double tCal, double tPro, double tCarb, Food p, Food c) {
    double pg = (tPro / p.protein) * 100;
    
    // Check if protein source "eats" too much of the carb budget
    double projectedCarbFromProtein = (pg * p.carb) / 100;
    if (tCarb > 0 && projectedCarbFromProtein > tCarb * 0.75) {
      // Cap protein source to leave 25% room for carb source
      // Re-calculate pg based on carb limit
      // But don't reduce it ridiculously low; ensure at least reasonable protein
      double maxCarbFromP = tCarb * 0.75;
      double newPg = (maxCarbFromP / p.carb) * 100;
      
      // Only apply if p.carb is actually significant
      if(p.carb > 5) {
         pg = newPg;
      }
    }

    double residualCarb = (pg * p.carb) / 100;
    double remainingCarbNeed = tCarb - residualCarb;
    if (remainingCarbNeed < 0) {
      remainingCarbNeed = 0;
    }
    double cg = (remainingCarbNeed / c.carb) * 100;

    double projectedCal = (pg * p.calories / 100) + (cg * c.calories / 100);
    double ratio = 1.0;
    if (projectedCal > tCal) {
      ratio = tCal / projectedCal; 
    }

    return {'p': pg * ratio, 'c': cg * ratio, 'cal': projectedCal * ratio};
  }

  void _replaceMeal(String mealCode) {
     // mealCode: 'Kahvaltı', 'Öğle', 'Akşam'
     // We need to replace both Protein and Carb sources for that meal
     // Logic: Add current items to disliked (simulated feedback) then re-select
     
     setState(() {
        if (mealCode == "Kahvaltı") {
           _dislikedItems.add(_bfP.name);
           _dislikedItems.add(_bfC.name);
           
           var listP = _f('protein', MealType.breakfast);
           var listC = _f('carb', MealType.breakfast);
           
           // Pick new ones if available
           if(listP.isNotEmpty) _bfP = listP[0];
           if(listC.isNotEmpty) _bfC = listC[0];
        } else if (mealCode == "Öğle") {
           _dislikedItems.add(_lnP.name);
           _dislikedItems.add(_lnC.name);
           
           var listP = _f('protein', MealType.main);
           var listC = _f('carb', MealType.main);
           
           if(listP.isNotEmpty) _lnP = listP[0];
           if(listC.isNotEmpty) _lnC = listC[0];
        } else if (mealCode == "Akşam") {
           _dislikedItems.add(_dnP.name);
           _dislikedItems.add(_dnC.name);
           
           var listP = _f('protein', MealType.main);
           var listC = _f('carb', MealType.main);
           
           // Try to pick different ones than Lunch if possible, but _f already filtered lunch items? No.
           // _f filters based on dislikedItems.
           // However, if we ate the same thing for lunch, and DISLIKED dinner (which was same), we effectively ban it.
           // So just picking the first available is fine.
           if(listP.isNotEmpty) _dnP = listP[0];
           if(listC.isNotEmpty) _dnC = listC[0];
        }
     });
  }

  double _n(double g, Food f, String t) { 
    double r=g/100; 
    return t=='p'?f.protein*r : f.carb*r; 
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dailyCalories == 0) return const Center(child: Text("Hesaplama Yapılmadı"));
    var bf=_smartCalc(widget.dailyCalories*0.25, widget.proteinGoal*0.25, widget.carbGoal*0.25, _bfP, _bfC);
    var ln=_smartCalc(widget.dailyCalories*0.40, widget.proteinGoal*0.40, widget.carbGoal*0.40, _lnP, _lnC);
    var dn=_smartCalc(widget.dailyCalories*0.35, widget.proteinGoal*0.35, widget.carbGoal*0.35, _dnP, _dnC);

    double tc = bf['cal']!+ln['cal']!+dn['cal']!;
    double tp = _n(bf['p']!,_bfP,'p')+_n(bf['c']!,_bfC,'p')+_n(ln['p']!,_lnP,'p')+_n(ln['c']!,_lnC,'p')+_n(dn['p']!,_dnP,'p')+_n(dn['c']!,_dnC,'p');
    double tk = _n(bf['p']!,_bfP,'c')+_n(bf['c']!,_bfC,'c')+_n(ln['p']!,_lnP,'c')+_n(ln['c']!,_lnC,'c')+_n(dn['p']!,_dnP,'c')+_n(dn['c']!,_dnC,'c');

    return Scaffold(
      appBar: AppBar(title: const Text("Beslenme Programın")),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _card("Kahvaltı", _row(_bfP, bf['p']!, 'bf', 'protein'), _row(_bfC, bf['c']!, 'bf', 'carb')),
        _card("Öğle", _row(_lnP, ln['p']!, 'ln', 'protein'), _row(_lnC, ln['c']!, 'ln', 'carb')),
        _card("Akşam", _row(_dnP, dn['p']!, 'dn', 'protein'), _row(_dnC, dn['c']!, 'dn', 'carb')),
        const SizedBox(height: 20),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          const Text("GÜNLÜK ÖZET", style: TextStyle(fontWeight: FontWeight.bold)), const Divider(),
          _stat("Kalori", widget.dailyCalories, tc, "kcal"), _stat("Protein", widget.proteinGoal, tp, "g"), _stat("Karbonhidrat", widget.carbGoal, tk, "g")
        ])))
      ]),
    );
  }
  Widget _card(String t, Widget w1, Widget w2) => Card(margin: const EdgeInsets.only(bottom: 15), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
      TextButton.icon(
        icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
        label: const Text("Değerlendir", style: TextStyle(fontSize: 12)), 
        onPressed: () {
          showDialog(context: context, builder: (c) => AlertDialog(
              title: Text("$t Değerlendirmesi"),
              content: const Text("Bu öğünü lezzetli ve doyurucu buldun mu?"),
              actions: [
                  TextButton(onPressed: (){ 
                      Navigator.pop(c); 
                      _replaceMeal(t); // t is "Kahvaltı" etc.
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu öğünü sevmedin. Tercihlerini güncelleyip yeni bir öneri hazırladık! 🔄"))); 
                  }, child: const Text("👎 Beğenmedim")),
                  TextButton(onPressed: (){ Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harika! Bunu sevdiğine sevindik. 👍"))); }, child: const Text("👍 Beğendim")),
              ]
          ));
        }
      )
    ]),
    const Divider(), w1, w2
  ])));
  Widget _row(Food f, double a, String m, String t) => ListTile(title: Text(f.name), subtitle: Text("${a.round()}g"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text("${(f.calories*a/100).round()} kcal", style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.swap_horiz, color: Colors.green), onPressed: () => _swap(t, m))]));
  Widget _stat(String l, double t, double a, String u) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text("Hedef: ${t.round()} / Plan: ${a.round()}$u", style: TextStyle(fontWeight: FontWeight.bold, color: (t-a).abs()<t*0.15 ? Colors.green : Colors.orange))]);
}
