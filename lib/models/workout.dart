class Exercise {
  final String name;
  final String sets;
  final String reps;
  final String weightGuide;
  final String description;
  const Exercise(this.name, this.sets, this.reps, this.weightGuide, this.description);
}

class WorkoutDay {
  final String dayName;
  final String focusArea;
  final List<Exercise> exercises;
  final bool isRestDay;
  const WorkoutDay({required this.dayName, required this.focusArea, this.exercises = const [], this.isRestDay = false});
}
