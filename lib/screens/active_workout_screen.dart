import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitness_club_mobile/models/workout.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutDay workoutDay;
  final Function() onComplete;

  const ActiveWorkoutScreen({super.key, required this.workoutDay, required this.onComplete});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  Timer? _timer;
  int _secondsElapsed = 0;
  
  // Rest Timer
  bool _isResting = false;
  int _restSeconds = 0;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if(!_isResting) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  void _completeSet(int totalSets) {
    if (_isResting) return; // Prevent double clicks

    if (_currentSet < totalSets) {
      _startRest();
    } else {
      // Exercise Complete
      _startRest(isExerciseComplete: true);
    }
  }

  void _startRest({bool isExerciseComplete = false}) {
    setState(() {
      _isResting = true;
      _restSeconds = 60; // 60 seconds rest standard
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_restSeconds > 0) {
          _restSeconds--;
        } else {
          _restTimer?.cancel();
          _isResting = false;
          if (isExerciseComplete) {
            _nextExercise();
          } else {
             _currentSet++;
          }
        }
      });
    });
  }
  
  int _parseSets(String s) {
      // Extract first number from string e.g. "3-4 Sets" -> 3
      RegExp regExp = RegExp(r'\d+');
      Match? match = regExp.firstMatch(s);
      if (match != null) {
          return int.tryParse(match.group(0)!) ?? 3;
      }
      return 3;
  }

  void _skipRest() {
    _restTimer?.cancel();
     setState(() {
        _isResting = false;
        int totalSets = _parseSets(widget.workoutDay.exercises[_currentExerciseIndex].sets);
        
        if (_currentSet >= totalSets) {
           _nextExercise();
        } else {
           _currentSet++;
        }
     });
  }
  
  // ... inside build ...
  // int totalSets = _parseSets(exercise.sets);

  void _nextExercise() {
    if (_currentExerciseIndex < widget.workoutDay.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
      });
    } else {
      _finishWorkout();
    }
  }

  void _finishWorkout() {
    _timer?.cancel();
    _restTimer?.cancel();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Tebrikler! 🎉"),
        content: Text("Antrenmanı ${_formatTime(_secondsElapsed)} sürede tamamladın!"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Screen
              widget.onComplete();
            },
            child: const Text("Harika!"),
          )
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentExerciseIndex >= widget.workoutDay.exercises.length) return const SizedBox.shrink();
    
    final exercise = widget.workoutDay.exercises[_currentExerciseIndex];
    int totalSets = _parseSets(exercise.sets);

    return Scaffold(
      backgroundColor: _isResting ? Colors.blueAccent : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.close, color: _isResting?Colors.white:Colors.black), onPressed: ()=>Navigator.pop(context)),
        title: Text(_formatTime(_secondsElapsed), style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 24, color: _isResting?Colors.white:Colors.black)),
        centerTitle: true,
      ),
      body: _isResting ? _buildRestUI() : _buildExerciseUI(exercise, totalSets),
    );
  }

  Widget _buildRestUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("DİNLENME", style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 5)),
          const SizedBox(height: 20),
          Text("$_restSeconds", style: const TextStyle(color: Colors.white, fontSize: 100, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text("Bir sonraki sete hazırlan...", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _skipRest,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            child: const Text("Dinlenmeyi Atla"),
          )
        ],
      ),
    );
  }

  Widget _buildExerciseUI(Exercise exercise, int totalSets) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text("Hareket ${_currentExerciseIndex+1} / ${widget.workoutDay.exercises.length}", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              Text(exercise.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text(exercise.description, textAlign: TextAlign.center, style: TextStyle(color: Colors.blue.shade800)),
              ),
            ],
          ),
          
          Column(
            children: [
               // Big Set Indicator
               Stack(
                 alignment: Alignment.center,
                 children: [
                   SizedBox(height: 200, width: 200, child: CircularProgressIndicator(value: _currentSet/totalSets, strokeWidth: 20, backgroundColor: Colors.grey.shade200, color: Colors.blueAccent)),
                   Column(
                     children: [
                       const Text("SET", style: TextStyle(fontSize: 20, color: Colors.grey)),
                       Text("$_currentSet", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
                       Text("/ $totalSets", style: const TextStyle(fontSize: 20, color: Colors.grey))
                     ],
                   )
                 ],
               ),
               const SizedBox(height: 10),
               Text("${exercise.reps} Tekrar • ${exercise.weightGuide}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ],
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _completeSet(totalSets),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text("SETİ TAMAMLA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
