/// Tingkat kesulitan workout yang menentukan jumlah set, repetisi/durasi, dan jeda istirahat.
enum WorkoutDifficulty {
  beginner,
  intermediate,
  advanced,
}

class WorkoutDifficultySpec {
  final WorkoutDifficulty difficulty;
  final String label;
  final String summaryLabel;
  final int sets;
  final int plankSeconds;
  final int restSeconds;

  const WorkoutDifficultySpec({
    required this.difficulty,
    required this.label,
    required this.summaryLabel,
    required this.sets,
    required this.plankSeconds,
    required this.restSeconds,
  });

  int targetRepsForExercise(String exerciseName) {
    final lower = exerciseName.toLowerCase();
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        if (lower.contains('squat') || lower.contains('sit-up') || lower.contains('situp') || lower.contains('leg')) {
          return 10;
        }
        return 8;
      case WorkoutDifficulty.intermediate:
        return 15;
      case WorkoutDifficulty.advanced:
        return 20;
    }
  }

  static const WorkoutDifficultySpec beginnerSpec = WorkoutDifficultySpec(
    difficulty: WorkoutDifficulty.beginner,
    label: 'Beginner',
    summaryLabel: '3 sets • 8–10 reps • 45s rest (Light)',
    sets: 3,
    plankSeconds: 20,
    restSeconds: 45,
  );

  static const WorkoutDifficultySpec intermediateSpec = WorkoutDifficultySpec(
    difficulty: WorkoutDifficulty.intermediate,
    label: 'Intermediate',
    summaryLabel: '3 sets • 15 reps • 30s rest (Moderate)',
    sets: 3,
    plankSeconds: 30,
    restSeconds: 30,
  );

  static const WorkoutDifficultySpec advancedSpec = WorkoutDifficultySpec(
    difficulty: WorkoutDifficulty.advanced,
    label: 'Advanced',
    summaryLabel: '4 sets • 20 reps • 20s rest (Intense)',
    sets: 4,
    plankSeconds: 45,
    restSeconds: 20,
  );

  static List<WorkoutDifficultySpec> get all => const [
        beginnerSpec,
        intermediateSpec,
        advancedSpec,
      ];

  static WorkoutDifficultySpec fromLabel(String? label) {
    final normalized = (label ?? '').trim().toLowerCase();
    if (normalized == 'beginner') return beginnerSpec;
    if (normalized == 'advanced') return advancedSpec;
    return intermediateSpec;
  }
}

/// Model representasi data program latihan harian 30 Hari (Sesuai SDD & Implementation Plan)
class WorkoutDayPlan {
  final int dayNumber;
  final bool isRestDay;
  final String category; // 'Upper & Core', 'Lower & Core', 'Full Body', 'Rest & Muscle Recovery'
  final List<String> exerciseNames;

  const WorkoutDayPlan({
    required this.dayNumber,
    required this.isRestDay,
    required this.category,
    required this.exerciseNames,
  });

  String get exerciseSummary => isRestDay
      ? 'Rest & Muscle Recovery'
      : exerciseNames.join(' • ');
}

/// Repository penyedia jadwal statis 30 hari StreakWok
/// Pola: 3 Hari Latihan + 1 Hari Istirahat (Rest Day)
/// 6 Gerakan: Push-up, Squat, Sit-up, Plank, Lunges, Leg Raises
class WorkoutPlanRepository {
  static const int currentActiveDay = 14;

  static const List<WorkoutDayPlan> plan30Days = [
    // SIKLUS 1 (Hari 1 - 4)
    WorkoutDayPlan(
      dayNumber: 1,
      isRestDay: false,
      category: 'Upper & Core',
      exerciseNames: ['Push-up', 'Sit-up', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 2,
      isRestDay: false,
      category: 'Lower & Core',
      exerciseNames: ['Squat', 'Lunges', 'Leg Raises'],
    ),
    WorkoutDayPlan(
      dayNumber: 3,
      isRestDay: false,
      category: 'Full Body',
      exerciseNames: ['Push-up', 'Squat', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 4,
      isRestDay: true,
      category: 'Rest & Muscle Recovery',
      exerciseNames: [],
    ),

    // SIKLUS 2 (Hari 5 - 8)
    WorkoutDayPlan(
      dayNumber: 5,
      isRestDay: false,
      category: 'Upper & Core',
      exerciseNames: ['Push-up', 'Sit-up', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 6,
      isRestDay: false,
      category: 'Lower & Core',
      exerciseNames: ['Squat', 'Lunges', 'Leg Raises'],
    ),
    WorkoutDayPlan(
      dayNumber: 7,
      isRestDay: false,
      category: 'Full Body',
      exerciseNames: ['Push-up', 'Squat', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 8,
      isRestDay: true,
      category: 'Rest & Muscle Recovery',
      exerciseNames: [],
    ),

    // SIKLUS 3 (Hari 9 - 12)
    WorkoutDayPlan(
      dayNumber: 9,
      isRestDay: false,
      category: 'Upper & Core',
      exerciseNames: ['Push-up', 'Sit-up', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 10,
      isRestDay: false,
      category: 'Lower & Core',
      exerciseNames: ['Squat', 'Lunges', 'Leg Raises'],
    ),
    WorkoutDayPlan(
      dayNumber: 11,
      isRestDay: false,
      category: 'Full Body',
      exerciseNames: ['Push-up', 'Squat', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 12,
      isRestDay: true,
      category: 'Rest & Muscle Recovery',
      exerciseNames: [],
    ),

    // SIKLUS 4 (Hari 13 - 16)
    WorkoutDayPlan(
      dayNumber: 13,
      isRestDay: false,
      category: 'Upper & Core',
      exerciseNames: ['Push-up', 'Sit-up', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 14,
      isRestDay: false,
      category: 'Lower & Core',
      exerciseNames: ['Squat', 'Lunges', 'Leg Raises'],
    ),
    WorkoutDayPlan(
      dayNumber: 15,
      isRestDay: false,
      category: 'Full Body',
      exerciseNames: ['Push-up', 'Squat', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 16,
      isRestDay: true,
      category: 'Rest & Muscle Recovery',
      exerciseNames: [],
    ),

    // SIKLUS 5 (Hari 17 - 20)
    WorkoutDayPlan(
      dayNumber: 17,
      isRestDay: false,
      category: 'Upper & Core',
      exerciseNames: ['Push-up', 'Sit-up', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 18,
      isRestDay: false,
      category: 'Lower & Core',
      exerciseNames: ['Squat', 'Lunges', 'Leg Raises'],
    ),
    WorkoutDayPlan(
      dayNumber: 19,
      isRestDay: false,
      category: 'Full Body',
      exerciseNames: ['Push-up', 'Squat', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 20,
      isRestDay: true,
      category: 'Rest & Muscle Recovery',
      exerciseNames: [],
    ),

    // SIKLUS 6 (Hari 21 - 24)
    WorkoutDayPlan(
      dayNumber: 21,
      isRestDay: false,
      category: 'Upper & Core',
      exerciseNames: ['Push-up', 'Sit-up', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 22,
      isRestDay: false,
      category: 'Lower & Core',
      exerciseNames: ['Squat', 'Lunges', 'Leg Raises'],
    ),
    WorkoutDayPlan(
      dayNumber: 23,
      isRestDay: false,
      category: 'Full Body',
      exerciseNames: ['Push-up', 'Squat', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 24,
      isRestDay: true,
      category: 'Rest & Muscle Recovery',
      exerciseNames: [],
    ),

    // SIKLUS 7 (Hari 25 - 28)
    WorkoutDayPlan(
      dayNumber: 25,
      isRestDay: false,
      category: 'Upper & Core',
      exerciseNames: ['Push-up', 'Sit-up', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 26,
      isRestDay: false,
      category: 'Lower & Core',
      exerciseNames: ['Squat', 'Lunges', 'Leg Raises'],
    ),
    WorkoutDayPlan(
      dayNumber: 27,
      isRestDay: false,
      category: 'Full Body',
      exerciseNames: ['Push-up', 'Squat', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 28,
      isRestDay: true,
      category: 'Rest & Muscle Recovery',
      exerciseNames: [],
    ),

    // SIKLUS PENUTUP (Hari 29 - 30)
    WorkoutDayPlan(
      dayNumber: 29,
      isRestDay: false,
      category: 'Upper & Core',
      exerciseNames: ['Push-up', 'Sit-up', 'Plank'],
    ),
    WorkoutDayPlan(
      dayNumber: 30,
      isRestDay: false,
      category: 'Full Body Challenge',
      exerciseNames: ['Push-up', 'Squat', 'Plank'],
    ),
  ];
}
