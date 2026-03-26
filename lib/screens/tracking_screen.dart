import 'package:flutter/material.dart';
import 'package:fitness_club_mobile/models/workout.dart';
import 'package:fitness_club_mobile/services/recommendation_engine.dart';

class TrackingScreen extends StatefulWidget {
  final List<WorkoutDay> workoutPlan;
  final double targetCalories;
  final double proteinGoal;
  final String goalName;
  final Function(double)? onWeightUpdate;
  
  // Lifted state
  final List<double> weightHistory; // Received from parent
  final List<bool> workoutHistory;
  final List<bool> dietHistory;
  final Function(bool, bool) onCheckIn;
  
  const TrackingScreen({
      super.key, 
      required this.workoutPlan, 
      required this.targetCalories, 
      required this.proteinGoal, 
      required this.goalName,
      this.onWeightUpdate,
      required this.weightHistory,
      required this.workoutHistory,
      required this.dietHistory,
      required this.onCheckIn
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {

  
  void _addWeight() {
      TextEditingController tc = TextEditingController();
      showDialog(context: context, builder: (c) => AlertDialog(
          title: const Text("Kilo Ekle"),
          content: TextField(controller: tc, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Güncel Kilon (kg)", border: OutlineInputBorder())),
          actions: [
              TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("İptal")),
              ElevatedButton(onPressed: () {
                  if(tc.text.isNotEmpty) {
                      double w = double.parse(tc.text);
                      widget.onWeightUpdate?.call(w);
                      Navigator.pop(c);
                  }
              }, child: const Text("Kaydet"))
          ]
      ));
  }

  int get adherenceScore {
    // If it's a fresh start (all past days are false), calculate based on TODAY only.
    // Otherwise, average over the week.
    bool freshStart = !widget.workoutHistory.sublist(1).any((e)=>e) && !widget.dietHistory.sublist(1).any((e)=>e);
    
    if (freshStart) {
        int w = widget.workoutHistory[0] ? 1 : 0;
        int d = widget.dietHistory[0] ? 1 : 0;
        return ((w + d) / 2 * 100).round();
    }
    
    int w = widget.workoutHistory.where((e) => e).length;
    int d = widget.dietHistory.where((e) => e).length;
    int total = widget.workoutHistory.length + widget.dietHistory.length; // 14 items
    return ((w + d) / total * 100).round();
  }

  // _checkIn moved to parent


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text("Gelişim & Analiz"), centerTitle: false, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStreakHeader(),
            const SizedBox(height: 25),
            _buildWeeklyCalendar(),
            const SizedBox(height: 25),
            _buildTodayCard(),
            const SizedBox(height: 25),
            _buildDetailedStats(),
            const SizedBox(height: 25),
            _buildWeightTracker(), // New Feature
            const SizedBox(height: 25),
            _buildRevisionSuggestion(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHeader() {
    int streak = 0;
    // Simple streak logic: count backwards from today until false
    for(int i=0; i<widget.workoutHistory.length; i++) {
        if(widget.workoutHistory[i] && widget.dietHistory[i]) streak++;
        else break;
    }
    // Since index 0 is today, 1 is yesterday... streak logic depends on list order.
    // My previous list order 0=Today. So iterating 0..N is correct for "current streak" if today is done.
    
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blue.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Mevcut Seri", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Row(children: [
                        const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 30),
                        const SizedBox(width: 5),
                        Text("$streak Gün", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))
                    ])
                ]),
                Container(
                    height: 50, width: 50,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.emoji_events, color: Colors.white, size: 30)
                )
            ]
        )
    );
  }

  Widget _buildWeeklyCalendar() {
    // 0=Today (Tue?), 1=Mon, etc. UI needs Mon->Sun order or Last 7 days order.
    // Let's show "Last 7 Days". 6 -> 0
    List<String> days = ["Çar", "Per", "Cum", "Cmt", "Paz", "Pzt", "Sal"]; // Example fixed labels or dynamic?
    // Let's use generic names relative to Today for simplicity or just T-6...T
    
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text("Son 7 Gün", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                    // Reverse index to show Oldest -> Newest (Left -> Right)
                    int dataIdx = 6 - index;
                    bool isWorkout = widget.workoutHistory[dataIdx];
                    bool isDiet = widget.dietHistory[dataIdx];
                    bool isToday = dataIdx == 0;
                    
                    Color statusColor = (isWorkout && isDiet) ? Colors.green : ((isWorkout || isDiet) ? Colors.orange : Colors.grey.shade300);
                    if(dataIdx > 0 && !isWorkout && !isDiet) statusColor = Colors.grey.shade300; // Empty/Future days simulated? No, these are past days.
                    
                    return Column(
                        children: [
                            Container(
                                height: 40, width: 10,
                                decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(5)
                                ),
                            ),
                            const SizedBox(height: 8),
                            Text(isToday ? "Bgn" : "${index+1}", style: TextStyle(color: isToday ? Colors.blue : Colors.grey, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, fontSize: 12))
                        ]
                    );
                })
            )
        ]
    );
  }

  Widget _buildDetailedStats() {
    int w = widget.workoutHistory.where((e)=>e).length;
    int d = widget.dietHistory.where((e)=>e).length;
    
    bool freshStart = !widget.workoutHistory.sublist(1).any((e)=>e) && !widget.dietHistory.sublist(1).any((e)=>e);
    int max = freshStart ? 1 : 7;
    
    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("Detaylı Analiz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 20),
                   _statRow("Antrenmanlar", w, max, Colors.purpleAccent),
                   const SizedBox(height: 15),
                   _statRow("Beslenme Hedefi", d, max, Colors.tealAccent),
                ]
            )
        )
    );
  }
  
  Widget _statRow(String title, int val, int max, Color color) {
      double pct = val/max;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title), Text("%${(pct*100).toInt()}", style: const TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: pct, backgroundColor: color.withOpacity(0.1), color: color, minHeight: 8, borderRadius: BorderRadius.circular(4))
      ]);
  }
  
  Widget _buildWeightTracker() {
      // Use real data
      return Card(
          elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Kilo Takibi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: _addWeight, child: const Text("+ Veri Ekle"))
              ]),
              const SizedBox(height: 10),
              SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                children: widget.weightHistory.map((w) => _bar(w, active: w == widget.weightHistory.last)).toList()
              ))
          ]))
      );
  }
  
  Widget _bar(double w, {bool active=false}) {
      return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text("$w", style: TextStyle(fontSize: 10, fontWeight: active?FontWeight.bold:FontWeight.normal, color: active?Colors.blue:Colors.grey)),
          const SizedBox(height: 5),
          Container(width: 12, height: (w-70)*10, decoration: BoxDecoration(color: active?Colors.blue:Colors.blue.shade100, borderRadius: BorderRadius.circular(4)))
      ]);
  }

  Widget _buildTodayCard() {
    // Find today's workout
    String todayWorkoutTitle = "Program Bekleniyor";
    String todayWorkoutSub = "Henüz bir plan oluşturmadın.";
    bool isRest = false;
    
    if (widget.workoutPlan.isNotEmpty) {
        int weekday = DateTime.now().weekday; // 1=Mon, 7=Sun
        int index = weekday - 1; // 0..6
        if(index < widget.workoutPlan.length) {
            final day = widget.workoutPlan[index];
            if (day.isRestDay) {
                todayWorkoutTitle = "Dinlenme Günü 😴";
                todayWorkoutSub = "Kasların büyümek için dinlenmeye ihtiyacı var.";
                isRest = true;
            } else {
                todayWorkoutTitle = "Bugün: ${day.focusArea}";
                todayWorkoutSub = "${day.exercises.length} Egzersiz: ${day.exercises.map((e)=>e.name).take(2).join(', ')}...";
            }
        }
    }

    String nutritionTitle = widget.targetCalories > 0 
        ? "Hedef: ${widget.targetCalories.round()} kcal" 
        : "Beslenme Planı Oluştur";
    String nutritionSub = widget.targetCalories > 0 
        ? "Protein: ${widget.proteinGoal.round()}g (Bunu tutturman önemli!)" 
        : "Durum sekmesinden verilerini gir.";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(children: [Icon(Icons.today, color: Colors.blue), SizedBox(width: 10), Text("Bugünün Görevleri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 15),
            SwitchListTile(
              title: Text(todayWorkoutTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isRest ? Colors.grey : Colors.black)),
              subtitle: Text(todayWorkoutSub),
              value: widget.workoutHistory[0],
              onChanged: (v) => widget.onCheckIn(true, v),
              activeColor: Colors.green,
            ),
            const Divider(),
            SwitchListTile(
              title: Text(nutritionTitle, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(nutritionSub),
              value: widget.dietHistory[0],
              onChanged: (v) => widget.onCheckIn(false, v),
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  // Renamed from _buildStatsCard to remove it or merge it?
  // User asked to complexify. The stats card was simple percent. The new DetailedStats replaces it better.
  // I will skip the old stats card in the new build method.

  Widget _buildRevisionSuggestion() {
    // Logic: If user has less than 4 "good" days (workout OR diet compliant) in the last 7 days.
    int goodDays = 0;
    for(int i=0; i<widget.workoutHistory.length; i++) {
        if(widget.workoutHistory[i] || widget.dietHistory[i]) goodDays++;
    }
    
    // Only show if performance is low AND it's not a fresh start (at least 3 days into plan)
    bool isEarly = widget.workoutHistory.sublist(3).every((e)=>!e) && widget.dietHistory.sublist(3).every((e)=>!e);
    
    if (goodDays >= 4 || isEarly) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Row(children: [Icon(Icons.tips_and_updates, color: Colors.blue), SizedBox(width: 10), Text("Yapay Zeka Uyarısı", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))]),
           const SizedBox(height: 10),
           const Text("Son 7 günde istikrarın biraz düştü (4 günden az katılım). Planın sana ağır geliyor olabilir mi?", style: TextStyle(color: Colors.black87)),
           const SizedBox(height: 10),
           SizedBox(
             width: double.infinity,
             child: OutlinedButton(
               onPressed: () {
                   // Navigate to workout screen or show dialog
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Öneri: Antrenman günlerini azaltmak için Antrenman sekmesine git.")));
               },
               child: const Text("Planı Gözden Geçir"),
             ),
           )
        ],
      ),
    );
  }
}
