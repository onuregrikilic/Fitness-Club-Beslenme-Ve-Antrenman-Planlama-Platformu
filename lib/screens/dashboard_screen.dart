import 'package:flutter/material.dart';
import 'package:fitness_club_mobile/models/food.dart';
import 'package:fitness_club_mobile/services/recommendation_engine.dart';

class DashboardScreen extends StatefulWidget {
  final double targetCalories; final double protein; final double carb; final double fat; final String goalName;
  final BudgetLevel userBudget; final bool isLactose; final bool isGluten; final bool isDiabetes; final CuisineType cuisine;
  final Function(double, double, double, double, String, BudgetLevel, bool, bool, bool, CuisineType) onUpdate;
  final double currentWeight;
  final Function(double)? onWeightUpdate;
  
  // Gamification Inputs
  final int xp;
  final int level;
  final String rank;
  final Function()? onNextDay;

  const DashboardScreen({
      super.key, 
      required this.targetCalories, required this.protein, required this.carb, required this.fat, required this.goalName, 
      required this.userBudget, required this.isLactose, required this.isGluten, required this.isDiabetes, required this.cuisine, required this.onUpdate, 
      this.currentWeight = 0, this.onWeightUpdate,
      this.xp = 0, this.level = 1, this.rank = "Başlangıç",
      this.onNextDay
  });
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _weightC = TextEditingController();
  final _heightC = TextEditingController();
  final _ageC = TextEditingController();
  String _gender = 'Erkek'; double _act = 1.375; String _goal = 'Koru';
  BudgetLevel _budg = BudgetLevel.medium; bool _lac = false; bool _glu = false; bool _dia = false; CuisineType _cui = CuisineType.global;
  
  // New States
  int _waterGlasses = 0;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    if (widget.targetCalories > 0) {
      _goal = widget.goalName.contains("Cut") ? 'Ver' : (widget.goalName.contains("Bulk") ? 'Al' : 'Koru');
      _budg = widget.userBudget; _lac = widget.isLactose; _glu = widget.isGluten; _dia = widget.isDiabetes; _cui = widget.cuisine;
    }
    if(widget.currentWeight > 0) _weightC.text = widget.currentWeight.toString();
  }
  
  @override
  void didUpdateWidget(DashboardScreen old) {
      super.didUpdateWidget(old);
      if(widget.currentWeight > 0 && widget.currentWeight != old.currentWeight) {
          // Update only if text is different to avoid cursor jumping if we were typing (though we only update from other screen usually)
          if(double.tryParse(_weightC.text) != widget.currentWeight) {
             _weightC.text = widget.currentWeight.toString();
          }
      }
  }

  void _calc() {
    double w = double.tryParse(_weightC.text) ?? 0;
    double h = double.tryParse(_heightC.text) ?? 0;
    int a = int.tryParse(_ageC.text) ?? 0;
    
    if (w > 0) widget.onWeightUpdate?.call(w);
    
    if (w > 0 && h > 0 && a > 0) {
      List<String> conditions = [];
      if (_lac) conditions.add('Laktoz');
      if (_glu) conditions.add('Gluten');
      if (_dia) conditions.add('Diyabet');

      final targets = RecommendationEngine.calculateTargets(
        weight: w,
        height: h,
        age: a,
        gender: _gender,
        activityLevel: _act,
        goal: _goal,
        medicalConditions: conditions,
      );

      String title = _goal == 'Ver' ? "Yağ Yakımı (Cut)" : (_goal == 'Al' ? "Kas Kazanımı (Bulk)" : "Form Koruma");

      setState(() => _showSettings = false); // Close settings after update
      widget.onUpdate(
        targets['calories']!, 
        targets['protein']!, 
        targets['carb']!, 
        targets['fat']!, 
        title, _budg, _lac, _glu, _dia, _cui
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasData = widget.targetCalories > 0;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
          title: const Text("Durum Merkezi"), 
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
              IconButton(
                  icon: Icon(_showSettings ? Icons.close : Icons.tune, color: Colors.black87), 
                  onPressed: () => setState(() => _showSettings = !_showSettings)
              )
          ]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_showSettings || !hasData) ...[
                Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(padding: const EdgeInsets.all(20), child: _buildInputForm())
                ),
                const SizedBox(height: 20),
            ],
            
            if (hasData && !_showSettings) ...[
              _buildLevelCard(),
              const SizedBox(height: 20),
              _buildModernSummary(),
              const SizedBox(height: 20),
              _buildBMIStatus(),
              const SizedBox(height: 20),
              _buildWaterTracker(),
            ] else if (!hasData) ...[
               const Text("Hadi Başlayalım! 🚀", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
               const SizedBox(height: 10),
               const Text("Sana özel planı oluşturmak için bilgilerin gerekli.", style: TextStyle(color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    int nextLvl = widget.level * 500;
    double progress = widget.xp / nextLvl;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0,5))]),
      child: Column(
        children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("SEVİYE ${widget.level}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
                    Text(widget.rank, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle), child: const Icon(Icons.stars, color: Colors.amber, size: 30))
            ]),
            const SizedBox(height: 15),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.grey.shade100, color: Colors.blueAccent)),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("${widget.xp} XP", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text("$nextLvl XP", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])
        ],
      )
    );
  }

  Widget _buildModernSummary() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blueAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 10))]
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Günlük Hedef", style: TextStyle(color: Colors.white70)),
                  Text(widget.goalName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.fitness_center, color: Colors.white))
          ]),
          const SizedBox(height: 30),
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                 _bigVal("${widget.targetCalories.round()}", "kcal", Icons.local_fire_department),
                 Container(width: 1, height: 40, color: Colors.white24),
                 _bigVal("${widget.protein.round()}g", "Protein", Icons.egg_alt),
                 Container(width: 1, height: 40, color: Colors.white24),
                 _bigVal("${widget.carb.round()}g", "Karb", Icons.rice_bowl),
             ]
          )
        ],
      )
    );
  }
  
  Widget _bigVal(String val, String lbl, IconData icon) {
      return Column(children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 5),
          Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(lbl, style: const TextStyle(fontSize: 12, color: Colors.white70))
      ]);
  }
  
  Widget _buildBMIStatus() {
     // Calculate BMI if weight/height are present in controller, otherwise mock or hide?
     // We can try to get them from controllers if filled, but controllers might be empty if app restarted and persistence not strictly implemented.
     // For now, let's assume if targetCalories > 0, the controllers MIGHT be empty if not persisted.
     // Let's rely on user entering them. If empty, show default gauge.
     
     double w = double.tryParse(_weightC.text) ?? 0;
     double h = double.tryParse(_heightC.text) ?? 0;
     double bmi = 0;
     if(w>0 && h>0) {
         bmi = w / ((h/100)*(h/100));
     }
     
     if (bmi == 0) return const SizedBox.shrink(); // Don't show if no data
     
     String status = "Normal";
     Color col = Colors.green;
     double pct = 0.5;
     
     if(bmi < 18.5) { status="Zayıf"; col=Colors.blue; pct=0.2; }
     else if(bmi >= 25 && bmi < 30) { status="Fazla Kilo"; col=Colors.orange; pct=0.8; }
     else if(bmi >= 30) { status="Obez"; col=Colors.red; pct=0.95; }
     
     return Card(
         elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                 const Text("Vücut Kitle İndeksi (BMI)", style: TextStyle(fontWeight: FontWeight.bold)),
                 Chip(label: Text(bmi.toStringAsFixed(1)), backgroundColor: col.withOpacity(0.2), labelStyle: TextStyle(color: col, fontWeight: FontWeight.bold))
             ]),
             const SizedBox(height: 15),
             Stack(children: [
                 Container(height: 10, decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), gradient: const LinearGradient(colors: [Colors.blue, Colors.green, Colors.orange, Colors.red]))),
                 Align(alignment: Alignment( (pct * 2) - 1, 0), child: Container(height: 20, width: 20, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 2), shape: BoxShape.circle)))
             ]),
             const SizedBox(height: 5),
             Align(alignment: Alignment( (pct * 2) - 1, 0), child: Text(status, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12)))
         ]))
     );
  }
  
  Widget _buildWaterTracker() {
      return Card(
          elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Su Tüketimi (Günlük)", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("$_waterGlasses / 10 Bardak", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))
              ]),
              const SizedBox(height: 20),
              Wrap(spacing: 15, runSpacing: 10, children: List.generate(10, (i) {
                  bool active = i < _waterGlasses;
                  return GestureDetector(
                      onTap: () => setState(() => _waterGlasses = i + 1 == _waterGlasses ? i : i + 1), // Toggle logic or fill up to?
                      child: Column(children: [
                          Icon(Icons.local_drink, color: active ? Colors.blueAccent : Colors.grey.shade200, size: 30),
                      ])
                  );
              })),
              if(_waterGlasses >= 8) ...[const SizedBox(height: 10), const Text("Harika, hidrasyon hedefini tutturdun! 💧", style: TextStyle(color: Colors.green, fontSize: 12))]
          ]))
      );
  }

  Widget _buildInputForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text("Profilini Güncelle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      Row(children: [Expanded(child: _txt(_weightC, "Kilo")), const SizedBox(width: 10), Expanded(child: _txt(_heightC, "Boy")), const SizedBox(width: 10), Expanded(child: _txt(_ageC, "Yaş"))]),
      const SizedBox(height: 15), 
      Row(children: [Expanded(child: _drop<String>(['Erkek','Kadın'], _gender, (v)=>setState(()=>_gender=v!)))]),
      const SizedBox(height: 15),
      _drop<double>([1.2,1.375,1.55,1.725], _act, (v)=>setState(()=>_act=v!), lbl: ["Hareketsiz (Ofis/Ev, minimal hareket)", "Hafif Hareketli (Ayakta iş, yürüyüş)", "Hareketli (Fiziksel iş, aktif yaşam)", "Çok Hareketli (Ağır iş, sporcu)"]),
      const SizedBox(height: 15), const Text("Bütçe & Mutfak", style: TextStyle(fontWeight: FontWeight.bold)),
      _drop<BudgetLevel>(BudgetLevel.values, _budg, (v)=>setState(()=>_budg=v!), lbl: ["Ekonomik","Orta","Lüks"]),
      _drop<CuisineType>(CuisineType.values, _cui, (v)=>setState(()=>_cui=v!), lbl: ["Türk Mutfağı","Dünya Mutfağı"]),
      const SizedBox(height: 10), 
      CheckboxListTile(title: const Text("Laktozsuz"), value: _lac, onChanged: (v)=>setState(()=>_lac=v!), dense: true, contentPadding: EdgeInsets.zero), 
      CheckboxListTile(title: const Text("Glutensiz"), value: _glu, onChanged: (v)=>setState(()=>_glu=v!), dense: true, contentPadding: EdgeInsets.zero),
      CheckboxListTile(title: const Text("Diyabet (Şeker Hastalığı)"), subtitle: const Text("Düşük karbonhidrat ve düşük GL indeksi önerilir."), value: _dia, onChanged: (v)=>setState(()=>_dia=v!), dense: true, contentPadding: EdgeInsets.zero),
      const SizedBox(height: 15), const Text("Hedefin?", style: TextStyle(fontWeight: FontWeight.bold)),
      SegmentedButton<String>(segments: const [ButtonSegment(value:'Ver',label:Text('Yağ Yak')), ButtonSegment(value:'Koru',label:Text('Koru')), ButtonSegment(value:'Al',label:Text('Bulk'))], selected: {_goal}, onSelectionChanged: (s)=>setState(()=>_goal=s.first)),
      const SizedBox(height: 20), ElevatedButton(onPressed: _calc, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)), child: const Text("HESAPLA & GÜNCELLE")),
      
      const SizedBox(height: 20),
      const Divider(),
      const Text("Geliştirici Araçları (Simülasyon)", style: TextStyle(color: Colors.grey, fontSize: 12)),
      TextButton.icon(
        icon: const Icon(Icons.fast_forward, color: Colors.orange),
        label: const Text("Günü Bitir & Yarına Geç", style: TextStyle(color: Colors.orange)),
        onPressed: () {
            setState(() => _waterGlasses = 0); // Reset water for new day
            widget.onNextDay?.call();
        }
      )
    ]);
  }

  Widget _txt(TextEditingController c, String l) => TextField(controller: c, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder(), isDense: true));
  Widget _drop<T>(List<T> items, T val, Function(T?) chg, {List<String>? lbl}) => DropdownButtonFormField<T>(
    value: val,
    isExpanded: true,
    items: List.generate(items.length, (i) => DropdownMenuItem(value: items[i], child: Text(lbl != null ? lbl[i] : items[i].toString(), overflow: TextOverflow.ellipsis))),
    onChanged: chg,
    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8))
  );
}
