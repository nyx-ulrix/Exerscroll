/// Exercise state machine for rep counting.
enum ExerciseState {
  init,
  down,
  up,
}

extension ExerciseStateX on ExerciseState {
  String get label {
    switch (this) {
      case ExerciseState.init:
        return 'init';
      case ExerciseState.down:
        return 'down';
      case ExerciseState.up:
        return 'up';
    }
  }
}
