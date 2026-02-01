import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../core/models/exercise_config.dart';

/// Counts reps for pushups and pull-ups based on BlazePose landmarks.
class RepCounter {
  RepCounter({required this.exerciseType});

  final ExerciseType exerciseType;

  bool _wasInBottomPosition = false;
  bool _wasInTopPosition = true;
  int _count = 0;

  /// Returns new total count if a rep was completed, else null.
  int? tick(Pose pose) {
    switch (exerciseType) {
      case ExerciseType.pushup:
        return _tickPushup(pose);
      case ExerciseType.pullup:
        return _tickPullup(pose);
    }
  }

  int? _tickPushup(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        leftWrist == null ||
        rightWrist == null) {
      return null;
    }

    final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final elbowY = (leftElbow.y + rightElbow.y) / 2;
    final wristY = (leftWrist.y + rightWrist.y) / 2;

    final armBent = elbowY > shoulderY && elbowY > wristY;
    final armExtended = elbowY < shoulderY && elbowY < wristY;

    if (armBent && !_wasInBottomPosition) {
      _wasInBottomPosition = true;
      _wasInTopPosition = false;
    } else if (armExtended && _wasInBottomPosition) {
      _wasInTopPosition = true;
      _wasInBottomPosition = false;
      _count++;
      return _count;
    }

    return null;
  }

  int? _tickPullup(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftElbow == null ||
        rightElbow == null ||
        nose == null) {
      return null;
    }

    final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final elbowY = (leftElbow.y + rightElbow.y) / 2;
    final chinOverBar = nose.y < shoulderY;

    if (chinOverBar && !_wasInTopPosition) {
      _wasInTopPosition = true;
      _wasInBottomPosition = false;
      _count++;
      return _count;
    }

    if (elbowY > shoulderY) {
      _wasInBottomPosition = true;
      _wasInTopPosition = false;
    }

    return null;
  }
}
