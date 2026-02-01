import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/exercise_config.dart';
import '../models/exercise_state.dart';

/// Angle-based pose detection for accurate pushup/pullup rep counting.
class PoseDetectorService {
  PoseDetectorService({required this.exerciseType});

  final ExerciseType exerciseType;

  ExerciseState _state = ExerciseState.init;
  int _reps = 0;

  static const double _pushupDownThreshold = 90.0;
  static const double _pushupUpThreshold = 160.0;
  static const double _pullupDownThreshold = 170.0;
  static const double _pullupUpThreshold = 90.0;

  int get reps => _reps;
  ExerciseState get state => _state;

  void reset() {
    _state = ExerciseState.init;
    _reps = 0;
  }

  /// Returns new total count if a rep was completed, else null.
  int? processPose(Pose pose) {
    switch (exerciseType) {
      case ExerciseType.pushup:
        return _processPushup(pose);
      case ExerciseType.pullup:
        return _processPullup(pose);
    }
  }

  int? _processPushup(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];

    if (shoulder == null || elbow == null || wrist == null) return null;

    final elbowAngle = _calculateAngle(
      shoulder.x,
      shoulder.y,
      elbow.x,
      elbow.y,
      wrist.x,
      wrist.y,
    );

    if (elbowAngle < _pushupDownThreshold && _state == ExerciseState.up) {
      _state = ExerciseState.down;
    } else if (elbowAngle > _pushupUpThreshold && _state == ExerciseState.down) {
      _reps++;
      _state = ExerciseState.up;
      return _reps;
    } else if (_state == ExerciseState.init && elbowAngle > _pushupUpThreshold) {
      _state = ExerciseState.up;
    }

    return null;
  }

  int? _processPullup(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    if (shoulder == null || elbow == null || wrist == null || nose == null) {
      return null;
    }

    final elbowAngle = _calculateAngle(
      shoulder.x,
      shoulder.y,
      elbow.x,
      elbow.y,
      wrist.x,
      wrist.y,
    );

    // Chin over bar: wrist/elbow above nose (lower y = higher on screen)
    final chinOverBar = wrist.y < nose.y || elbow.y < nose.y;

    if (elbowAngle > _pullupDownThreshold) {
      _state = ExerciseState.down;
    } else if (chinOverBar && elbowAngle < _pullupUpThreshold) {
      if (_state == ExerciseState.down) {
        _reps++;
        _state = ExerciseState.up;
        return _reps;
      }
      _state = ExerciseState.up;
    }

    return null;
  }

  /// Calculate angle at point (x2,y2) formed by (x1,y1)-(x2,y2)-(x3,y3).
  double _calculateAngle(double x1, double y1, double x2, double y2, double x3, double y3) {
    final angle1 = math.atan2(y2 - y1, x2 - x1);
    final angle2 = math.atan2(y3 - y2, x3 - x2);
    var angleDeg = (angle2 - angle1) * 180 / math.pi;
    if (angleDeg < 0) angleDeg += 360;
    if (angleDeg > 180) angleDeg = 360 - angleDeg;
    return angleDeg;
  }
}
