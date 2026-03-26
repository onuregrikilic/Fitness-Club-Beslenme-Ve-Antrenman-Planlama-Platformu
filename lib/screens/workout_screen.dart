import 'package:flutter/material.dart';
import 'package:fitness_club_mobile/models/workout.dart';
import 'package:fitness_club_mobile/screens/active_workout_screen.dart'; // New Import

class WorkoutScreen extends StatefulWidget {
  final String goalName; final List<WorkoutDay> workoutPlan;  final bool isCreated;
  final Function(List<WorkoutDay>) onPlanCreated;
  final Function()? onWorkoutComplete; // New Callback

  const WorkoutScreen({super.key, required this.goalName, required this.workoutPlan, required this.isCreated, required this.onPlanCreated, this.onWorkoutComplete});
  @override State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _daysPerWeek = 4; 
  String _focusArea = 'Dengeli';
  String _splitType = 'Full Body'; // PPL, Upper/Lower, Split, Hybrid
  String _intensity = 'Orta (Dengeli)'; // High Volume, High Intensity, Moderate
  String _restPreference = 'Hafta Sonu Dinlenme'; // Hafta Sonu, Çarşamba/Pazar, Dengeli Dağıt
  List<bool> _manualDays = [false, false, false, false, false, true, true]; // Mon-Sun
  
  final List<String> _restOptions = ['Hafta Sonu Dinlenme', 'Çarşamba & Pazar', 'Dengeli Dağıt (Önerilen)', 'Manuel Seçim'];

  final List<String> _splits = ['Full Body', 'Push/Pull/Legs', 'Upper/Lower', 'Bölgesel (Split)', 'Hybrid'];
  final List<String> _intensities = ['High Volume (Hacim)', 'High Intensity (Şiddet)', 'Orta (Dengeli)'];

  
  void _gen() {
    List<WorkoutDay> p = [];
    List<String> schedule = _getSchedule(_daysPerWeek, _splitType);
    
    // Day names mapping
    List<String> days = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
    
    for (int i = 0; i < 7; i++) {
        String dayType = i < schedule.length ? schedule[i] : "Rest";
        // If we have fewer training days, map them effectively or just loop? 
        // Actually schedule should be length 7.
        
        bool isRest = dayType == "Rest";
        p.add(WorkoutDay(
            dayName: days[i], 
            focusArea: isRest ? "Dinlenme" : dayType,
            isRestDay: isRest,
            exercises: isRest ? [] : _getExercises(dayType)
        ));
    }
    
    widget.onPlanCreated(p);
  }

  List<String> _getSchedule(int days, String split) {
    List<String> s = List.filled(7, "Rest");
    
    // Calculate total rest days needed
    int totalRest = 7 - days;
    
    // Helper to distribute workouts evenly
    List<int> workoutIndices = [];
    if (days == 1) workoutIndices = [0]; // Mon
    if (days == 2) workoutIndices = [0, 3]; // Mon, Thu
    if (days == 3) workoutIndices = [0, 2, 4]; // Mon, Wed, Fri
    if (days == 4) workoutIndices = [0, 1, 3, 4]; // Mon, Tue, Thu, Fri (Wed/Sat/Sun Rest)
    if (days == 5) workoutIndices = [0, 1, 2, 3, 4]; // Mon-Fri
    if (days == 6) workoutIndices = [0, 1, 2, 3, 4, 5]; // Mon-Sat
    if (days == 7) workoutIndices = [0, 1, 2, 3, 4, 5, 6];
    
    // Adjust based on Rest Preference
    if (_restPreference == 'Manuel Seçim') {
        // Use user selected days (true = rest, false = workout?)
        // Let's assume _manualDays: true means WORKOUT to be intuitive? No the name is rest selection.
        // Let's say _manualDays: true->Selected as Rest Day.
        // We need to pick workout indices where _manualDays is false.
        
        workoutIndices = [];
        for(int k=0; k<7; k++) {
            if(!_manualDays[k]) workoutIndices.add(k); // If not rest, it's workout
        }
        
        // Safety: If workoutIndices doesn't match 'days', we should probably adjust 'days' or just use what we have?
        // Better to respect the manual selection as the source of truth for 'days' count if in manual mode?
        // But the signature demands 'days'. We will just fill as many as we can.
    }
    else if (_restPreference.contains("Hafta Sonu") && days <= 5) {
       // Force weekends off if possible, pack workouts Mon-Fri
       workoutIndices = [];
       for(int k=0;k<days;k++) workoutIndices.add(k);
    } 

    else if (_restPreference.contains("Çarşamba")) {
       // Avoid Wed (2) and Sun (6) if possible
       List<int> preferred = [0, 1, 3, 4, 5]; // Mon, Tue, Thu, Fri, Sat
       workoutIndices = [];
       
       // Fill from preferred first
       for(int k=0; k<days && k<preferred.length; k++) {
           workoutIndices.add(preferred[k]);
       }
       
       // If we need more days (e.g. 6 or 7 days), we force add Wed then Sun
       if (days > 5) workoutIndices.add(2); // Add Wed
       if (days > 6) workoutIndices.add(6); // Add Sun
       
       workoutIndices.sort();
    }
    else if (_restPreference.contains("Dengeli")) {
        // Enforce specific balanced patterns
        if (days == 3) workoutIndices = [0, 2, 4]; // M, W, F
        if (days == 4) workoutIndices = [0, 2, 4, 6]; // M, W, F, S (Spread out) OR [0, 1, 3, 4] (Upper/Lower style)
        // Let's stick to M, T, Th, F for 4 days as it fits Upper/Lower better
        if (days == 4) workoutIndices = [0, 1, 3, 4]; 
        
        if (days == 5) workoutIndices = [0, 1, 2, 4, 5]; // M, T, W, F, S (Rest Thu, Sun) - better distribution than 5 straight
    }
    
    // Fill schedule array based on split logic at specific indices
    List<String> workoutQueue = [];
    
    // Generate the queue of workouts first (e.g., A, B, A, B)
    if (split.contains("Full Body")) {
        for(int k=0; k<days; k++) {
            if(days==1) workoutQueue.add("Full Body");
            else if(days<4) workoutQueue.add(k%2==0?"Full Body A":"Full Body B"); // A B A
            else workoutQueue.add(k%2==0?"Full Body A":"Full Body B");
        }
    } 
    else if (split.contains("Push/Pull/Legs")) {
        List<String> ppl = ["Push", "Pull", "Legs"];
        for(int k=0; k<days; k++) workoutQueue.add(ppl[k%3]);
    } 
    else if (split.contains("Upper/Lower")) {
        List<String> ul = ["Upper", "Lower"];
        for(int k=0; k<days; k++) workoutQueue.add(ul[k%2]);
    }
    else {
        // Bro Split
        List<String> bro = ["Chest & Triceps", "Back & Biceps", "Legs & Shoulders", "Arms & Abs", "Weak Point"];
        if(days>=5) bro = ["Chest", "Back", "Legs", "Shoulders", "Arms"];
        for(int k=0; k<days; k++) workoutQueue.add(bro[k%bro.length]);
    }
    
    // Place workouts into schedule at indices
    for(int i=0; i<days && i<workoutQueue.length; i++) {
        if(i < workoutIndices.length) {
            s[workoutIndices[i]] = workoutQueue[i];
        }
    }
    
    return s;
  }

  List<Exercise> _getExercises(String type) {
    // Intensity Logic
    String repH = "12-15", repM = "10-12", repL = "5-8";
    String setH = "4 Set", setM = "3 Set", setL = "3 Set"; // High Volume has more sets usually? Or lighter weight?
    // User definition: High Intensity = Heavy, Low Rep. High Volume = Pump, High Rep.
    
    bool isHI = _intensity.contains("Intensity");
    bool isHV = _intensity.contains("Volume");
    
    // Helper to create Ex
    Exercise e(String n, String r, String w, String d) {
        String sets = isHV ? "4-5 Set" : (isHI ? "3 Set" : "3-4 Set");
        String reps = isHI ? (r=="Low"?"5-6":"8-10") : (isHV ? (r=="Low"?"10-12":"15-20") : (r=="Low"?"8-10":"12-15"));
        if(n.contains("Abs") || n.contains("Calf") || n.contains("Lateral")) reps = isHI ? "12-15" : "15-25"; // Some muscles need high reps anyway
        
        String weight = isHI ? "Ağır" : (isHV ? "Orta-Hafif" : "Orta");
        /* Exceptions */
        if (isHI && r=="Low") weight = "Çok Ağır (RPE 9)";
        
        return Exercise(n, sets, reps, weight, d);
    }
    
    List<Exercise> list = [];
    
    if (type.contains("Full")) {
        list.add(e("Squat", "Low", "Bacak", "Temel bileşik hareket"));
        list.add(e("Bench Press", "Low", "Göğüs", "Temel itiş"));
        list.add(e("Bent Over Row", "Low", "Sırt", "Temel çekiş"));
        list.add(e("Overhead Press", "Med", "Omuz", "Omuz pres"));
        list.add(e("Lunge", "High", "Bacak", "Tek bacak"));
    }
    else if (type.contains("Push") || type == "Chest & Triceps" || type == "Chest") {
        list.add(e("Bench Press", "Low", "Göğüs", "Ana göğüs hareketi"));
        list.add(e("Incline Dumbbell Press", "Med", "Üst Göğüs", "Üst göğüs odaklı"));
        list.add(e("Lateral Raise", "High", "Omuz", "Yan omuz açış"));
        list.add(e("Triceps Pushdown", "High", "Arka Kol", "İzole arka kol"));
        if(type.contains("Triceps")) list.add(e("Skullcrusher", "Med", "Arka Kol", "Kütle hareketi"));
    }
    else if (type.contains("Pull") || type == "Back & Biceps" || type == "Back") {
        list.add(e("Deadlift", "Low", "Sırt/Bel", "Tüm vücut güç"));
        list.add(e("Pull Up / Lat Pulldown", "Med", "Sırt", "Kanat genişliği"));
        list.add(e("Seated Cable Row", "Med", "Sırt", "Sırt kalınlığı"));
        list.add(e("Face Pull", "High", "Arka Omuz", "Postür ve sağlık"));
        list.add(e("Barbell Curl", "Med", "Pazu", "Temel pazu"));
    }
    else if (type.contains("Legs") || type.contains("Lower")) {
        list.add(e("Squat", "Low", "Bacak", "Kral hareket"));
        list.add(e("Romanian Deadlift", "Med", "Arka Bacak", "Esnetme odaklı"));
        list.add(e("Leg Press", "Med", "Bacak", "Hacim"));
        list.add(e("Leg Extension", "High", "Ön Bacak", "İzole bitiriş"));
        list.add(e("Calf Raise", "High", "Kalf", "Kalf kasları"));
    }
    else if (type.contains("Upper")) {
        list.add(e("Bench Press", "Low", "Göğüs", ""));
        list.add(e("Barbell Row", "Low", "Sırt", ""));
        list.add(e("Overhead Press", "Med", "Omuz", ""));
        list.add(e("Lat Pulldown", "Med", "Sırt", ""));
        list.add(e("Dumbbell Curl", "High", "Kol", ""));
    }
    else if (type.contains("Shoulder")) {
        list.add(e("Overhead Press", "Low", "Omuz", ""));
        list.add(e("Arnold Press", "Med", "Omuz", ""));
        list.add(e("Lateral Raise", "High", "Yan Omuz", ""));
        list.add(e("Front Raise", "High", "Ön Omuz", ""));
    }
    else if (type.contains("Arms")) {
        list.add(e("Close Grip Bench Press", "Med", "Arka Kol", ""));
        list.add(e("Barbell Curl", "Med", "Pazu", ""));
        list.add(e("Triceps Extension", "High", "Arka Kol", ""));
        list.add(e("Hammer Curl", "High", "Pazu", ""));
    }
    
    // Focus Area Injector
    if (_focusArea != "Dengeli") {
        if (_focusArea.contains("Göğüs") && (type.contains("Push") || type.contains("Chest") || type.contains("Upper"))) {
            list.insert(2, e("Cable Crossover", "High", "Göğüs", "Odak: Göğüs sıkıştırma"));
        }
        if (_focusArea.contains("Kol") && (type.contains("Pull") || type.contains("Arm"))) {
            list.add(e("Preacher Curl", "High", "Pazu", "Odak: İzole Bicep"));
        }
    }
    
    return list;
  }

  void _det(Exercise e) => showDialog(context: context, builder: (c)=>AlertDialog(title: Text(e.name), content: Text("${e.description}\n\nAğırlık: ${e.weightGuide}\nHedef: ${e.sets} x ${e.reps}"), actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Tamam"))]));

  void _adjustIntensity(int direction) {
      if (direction == 1) {
          // Increase Difficulty
          if (_intensity.contains("Orta")) {
             _intensity = 'High Intensity (Şiddet)';
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Programın şiddeti artırıldı!")));
          }
      } else if (direction == -1) {
          // Decrease Difficulty
          if (!_intensity.contains("Orta")) {
             _intensity = 'Orta (Dengeli)';
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Programın şiddeti düşürüldü. Dengeli devam ediyoruz.")));
          }
      }
      _gen(); // Regenerate plan with new settings
  }

  void _finishWorkout() {
      if(widget.onWorkoutComplete != null) widget.onWorkoutComplete!();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Antrenman Tamamlandı! Geri bildirimin işlendi.")));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.goalName == "Hedef Bekleniyor") return const Center(child: Text("Lütfen hedeflerini belirle."));
    if (!widget.isCreated) {
      return Scaffold(appBar: AppBar(title: const Text("Antrenman Koçu")), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.fitness_center, size: 80, color: Colors.grey), const SizedBox(height: 20), const Text("Programın yok.", style: TextStyle(fontSize: 18)), const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c)=>_setup()), icon: const Icon(Icons.edit_note), label: const Text("YAPILANDIR"))
      ])));
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Haftalık Programın"), actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c)=>_setup()))
      ]), 
      body: Column(
        children: [
            Expanded(
              child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: widget.workoutPlan.length + 1, itemBuilder: (c, i) {
                if (i == widget.workoutPlan.length) return _configSection();
                final d = widget.workoutPlan[i];
                return Card(margin: const EdgeInsets.only(bottom: 15), child: ExpansionTile(leading: CircleAvatar(backgroundColor: d.isRestDay?Colors.grey.shade200:Colors.blue.shade100, child: Icon(d.isRestDay?Icons.hotel:Icons.fitness_center, color: d.isRestDay?Colors.grey:Colors.blue)), title: Text(d.dayName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(d.focusArea), children: d.exercises.map((e) => ListTile(title: Text(e.name), subtitle: Text("${e.sets} x ${e.reps}"), trailing: IconButton(icon: const Icon(Icons.info_outline, color: Colors.blue), onPressed: () => _det(e)))).toList()));
              }),
            ),
        ],
      ),
      floatingActionButton: (widget.isCreated && widget.workoutPlan.isNotEmpty) 
       ? FloatingActionButton.extended(
          onPressed: () {
            // Determine today's workout
             int weekday = DateTime.now().weekday; 
             int index = weekday - 1;
             if(index < widget.workoutPlan.length && !widget.workoutPlan[index].isRestDay) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(
                  workoutDay: widget.workoutPlan[index], 
                  onComplete: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Antrenman Nasıldı?"),
                        content: const Text("Gelecek programını sana göre şekillendirmemiz için geri bildirimin önemli."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _adjustIntensity(1); // Harder
                              _finishWorkout();
                            },
                            child: const Text("Çok Hafif"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _finishWorkout(); // Good
                            },
                            child: const Text("Tam Kararında"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _adjustIntensity(-1); // Easier
                              _finishWorkout();
                            },
                            child: const Text("Çok Ağır"),
                          ),
                        ],
                      ),
                    );
                  }
                )));
             } else {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bugün dinlenme günü veya programın yok!")));
             }
          },
          label: const Text("ANTRENMANA BAŞLA"),
          icon: const Icon(Icons.play_arrow),
          backgroundColor: Colors.blueAccent,
       )
       : null,
    );
  }
  
  Widget _configSection() {
    return Card(
        color: Colors.blue.shade50,
        child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            const Text("Program Ayarlarını Değiştir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text("Mevcut: $_daysPerWeek Gün | $_splitType | $_intensity"),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c)=>_setup()), child: const Text("DÜZENLE"))
        ]))
    );
  }
  
  Widget _setup() {
    return StatefulBuilder(builder: (c, s) => Container(
      padding: const EdgeInsets.all(20),
      height: 600, // Fixed height for scrollable content
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Program Ayarları", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 20),
          
          const Text("Haftalık Antrenman Sayısı", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: _daysPerWeek.toDouble(), min: 1, max: 7, divisions: 6, label: "$_daysPerWeek Gün", onChanged: (v) => s(() => _daysPerWeek = v.toInt())),
          
          const SizedBox(height: 15),
          const Text("Dinlenme Düzeni", style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(
            value: _restPreference, 
            isExpanded: true,
            items: _restOptions.map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(), 
            onChanged: (v) => s(() {
                 _restPreference = v!;
            })
          ),
          if (_restPreference == 'Manuel Seçim') ...[
              const SizedBox(height: 10),
              const Text("Dinlenme Günlerini Seç:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Wrap(spacing: 5, children: List.generate(7, (index) {
                  List<String> d = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
                  return FilterChip(
                      label: Text(d[index]), 
                      selected: _manualDays[index], 
                      onSelected: (val) {
                          s(() {
                             _manualDays[index] = val;
                             // Auto update training days count?
                             int restCount = _manualDays.where((e)=>e).length;
                             _daysPerWeek = 7 - restCount;
                             if(_daysPerWeek < 1) { _daysPerWeek=1; _manualDays[index]=false; } // Prevent 0 training days
                          });
                      }
                  );
              }))
          ],
          
          const SizedBox(height: 15),
          const Text("Antrenman Stili (Split)", style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(
            value: _splitType, 
            isExpanded: true,
            items: _splits.map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(), 
            onChanged: (v) => s(() => _splitType = v!)
          ),
          
          const SizedBox(height: 15),
          const Text("Odak Bölgesi", style: TextStyle(fontWeight: FontWeight.bold)), 
          DropdownButtonFormField<String>(
            value: _focusArea, 
            isExpanded: true,
            items: const [DropdownMenuItem(value: "Dengeli", child: Text("Dengeli")), DropdownMenuItem(value: "Göğüs", child: Text("Göğüs Odaklı")), DropdownMenuItem(value: "Sırt", child: Text("Sırt Odaklı")), DropdownMenuItem(value: "Bacak", child: Text("Bacak Odaklı")), DropdownMenuItem(value: "Kol", child: Text("Kol Odaklı"))], 
            onChanged: (v) => s(() => _focusArea = v!)
          ),
          
          const SizedBox(height: 15),
          const Text("Yoğunluk Tipi", style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("High Volume: Çok set/tekrar, pump odaklı.\nHigh Intensity: Ağır kilo, az tekrar, tükeniş.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          DropdownButtonFormField<String>(
            value: _intensity, 
            isExpanded: true,
            items: _intensities.map((e)=>DropdownMenuItem(value: e, child: Text(e))).toList(), 
            onChanged: (v) => s(() => _intensity = v!)
          ),

          const SizedBox(height: 25), 
          SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), onPressed: () { _gen(); Navigator.pop(context); }, child: const Text("PROGRAMI OLUŞTUR")))
        ]),
      )
    ));
  }
}
