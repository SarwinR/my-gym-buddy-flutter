import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gym_buddy_app/models/exercise.dart';
import 'package:gym_buddy_app/models/rep_set.dart';
import 'package:gym_buddy_app/models/workout.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  static Database? database;

  static Future<String> getDatabasePath() async {
    var databasesPath = await getDatabasesPath();
    if (kDebugMode) print(databasesPath);
    return '$databasesPath/gym_buddy.db';
  }

  static Future<String?> importDatabase(File newDatabase) async {
    if (newDatabase.path.split('.').last != 'db') {
      return "Invalid file type";
    }

    await deleteDatabase(await getDatabasePath());
    File newFile = await newDatabase.copy(await getDatabasePath());
    await newFile.rename(await getDatabasePath());
    await openLocalDatabase(reopen: true);

    return null;
  }

  static Future<void> exportDatabase() async {
    Share.shareXFiles([XFile(await getDatabasePath())],
        subject: 'Gym Buddy Database');
  }

  static Future<bool> saveExercise(Exercise exercise) async {
    if (database == null) {
      await openLocalDatabase();
    }

    var data = exercise.toJson();
    var safeData = {
      'exercise_name': data['exercise_name'],
      'exercise_video': data['exercise_video'],
    };

    database!.insert(
      'exercises',
      safeData,
    );

    return true;
  }

  static Future<bool> saveWorkoutSession(Workout workout, int duration) async {
    var rawWorkoutID = await database!.insert('workout_session', {
      'workout_template_id': workout.id,
      'duration': duration,
      'start_time': DateTime.now()
          .subtract(Duration(seconds: duration))
          .toIso8601String(),
    });

    int index = 0;
    for (final exercise in workout.exercises!) {
      var repSet = {'sets': []};

      for (final set in exercise.sets) {
        repSet['sets']!
            .add({'reps': set.reps, 'weight': set.weight, 'note': set.note});
      }

      final workoutSessionExercise = <String, dynamic>{
        "exercise_id": int.parse(exercise.id!),
        "workout_session_id": rawWorkoutID,
        "rep_set": json.encode(repSet),
        "exercise_index": index,
      };

      await database!
          .insert('workout_session_exercises', workoutSessionExercise);
      index++;
    }

    return true;
  }

  static Future<bool> updateWorkout(Workout workout) async {
    //todo: improve that :D
    await deleteWorkout(workout);
    await saveWorkout(workout);

    return true;
  }

  static Future<bool> deleteWorkout(Workout workout) async {
    await database!
        .delete('workout_templates', where: 'id = ?', whereArgs: [workout.id]);

    await database!.delete('workout_template_exercises',
        where: 'workout_template_id = ?', whereArgs: [workout.id]);

    return true;
  }

  static Future<bool> saveWorkout(Workout workout) async {
    var rawWorkoutID = await database!
        .insert('workout_templates', {'workout_name': workout.name});

    int index = 0;
    for (final exercise in workout.exercises!) {
      var repSet = {'sets': []};

      for (final set in exercise.sets) {
        repSet['sets']!
            .add({'reps': set.reps, 'weight': set.weight, 'note': set.note});
      }

      final workoutTemplateExercise = <String, dynamic>{
        "exercise_id": int.parse(exercise.id!),
        "workout_template_id": rawWorkoutID,
        "rep_set": json.encode(repSet),
        "exercise_index": index,
      };

      await database!
          .insert('workout_template_exercises', workoutTemplateExercise);
      index++;
    }

    return true;
  }

  static Future<List<Exercise>> getExercises() async {
    if (database == null) {
      await openLocalDatabase();
    }

    final records = await database!.query('exercises');

    List<Exercise> exercises = [];
    for (final record in records) {
      if (kDebugMode) print(record);
      exercises.add(Exercise.fromJson(record));

      final previousRecord = await database!.query('workout_session_exercises',
          where: 'exercise_id = ?',
          whereArgs: [record['id']],
          orderBy: 'id DESC',
          limit: 1);

      if (previousRecord.isNotEmpty) {
        exercises.last.addPreviousSetsFromJson(
            json.decode(previousRecord.first['rep_set'].toString()));
      }
    }

    return exercises;
  }

  static Future<List<Workout>> getAllWorkoutSessions() async {
    if (database == null) {
      await openLocalDatabase();
    }

    final rawWorkout =
        await database!.query('workout_session', orderBy: 'start_time DESC');

    List<Workout> workouts = [];
    for (final record in rawWorkout) {
      final workout =
          await getWorkoutGivenID(record['workout_template_id'].toString());

      workout.startTime = DateTime.parse(record['start_time'].toString());
      workout.duration = record['duration'] as int;
      workouts.add(workout);
    }

    return workouts;
  }

  static Future<Exercise> getExerciseGivenID(String id) async {
    final record =
        await database!.query('exercises', where: 'id = ?', whereArgs: [id]);

    // get the last record from session exercises
    final previousRecord = await database!.query('workout_session_exercises',
        where: 'exercise_id = ?',
        whereArgs: [id],
        orderBy: 'id DESC',
        limit: 1);

    Exercise exercise = Exercise.fromJson(record.first);
    if (previousRecord.isNotEmpty) {
      exercise.addPreviousSetsFromJson(
          json.decode(previousRecord.first['rep_set'].toString()));
    }

    return exercise;
  }

  static Future<List<Workout>> getWorkoutList() async {
    if (database == null) {
      await openLocalDatabase();
    }

    final rawWorkout = await database!.query('workout_templates');

    if (kDebugMode) print(rawWorkout);

    List<Workout> workouts = [];
    for (final record in rawWorkout) {
      Workout workout = Workout.fromJson(
        record,
      );
      workouts.add(workout);
    }

    return workouts;
  }

  static Future<Workout> getWorkoutGivenID(String id) async {
    final record = await database!
        .query('workout_templates', where: 'id = ?', whereArgs: [id]);

    if (record.isEmpty) {
      return Workout(name: 'no name', id: '-1');
    }

    final rawExercises = await database!.query('workout_template_exercises',
        where: 'workout_template_id = ?', whereArgs: [id]);

    List<Exercise> exercises = [];
    for (final exercise in rawExercises) {
      final exerciseID = exercise['exercise_id'].toString();
      final exerciseRecord = await getExerciseGivenID(exerciseID);
      final exerciseObject = Exercise.fromJson(exerciseRecord.toJson());

      // convert rep_set to list of rep_set
      final repSet = exercise['rep_set'];
      final repSetMap = json.decode(repSet.toString());

      for (final set in repSetMap['sets']) {
        exerciseObject.sets.add(RepSet.fromJson(set));
      }

      exercises.add(exerciseObject);
    }

    Workout workout = Workout.fromJson(record.first);
    workout.exercises = exercises;

    return workout;
  }

  static Future<Database> openLocalDatabase(
      {bool newDatabase = false, bool reopen = false}) async {
    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    if (newDatabase) {
      await deleteDatabase(await getDatabasePath());
      database = null;
    }

    if (database == null || reopen) {
      database =
          await openDatabase(await getDatabasePath(), onCreate: (db, version) {
        db.execute(
            "CREATE TABLE exercises (id INTEGER PRIMARY KEY, exercise_name TEXT, exercise_video TEXT)");
        db.execute(
            "CREATE TABLE workout_templates (id INTEGER PRIMARY KEY, workout_name TEXT)");
        db.execute(
            "CREATE TABLE workout_template_exercises (id INTEGER PRIMARY KEY, exercise_id INTEGER, workout_template_id INTEGER, rep_set TEXT, exercise_index INTEGER)");
        db.execute(
            "CREATE TABLE workout_session (id INTEGER PRIMARY KEY, workout_template_id INTEGER, start_time TEXT, duration INTEGER)");
        db.execute(
            "CREATE TABLE workout_session_exercises (id INTEGER PRIMARY KEY, workout_session_id INTEGER, exercise_id INTEGER, rep_set TEXT, exercise_index INTEGER)");
      }, version: 1);
      return database!;
    }

    return database!;
  }

  static void resetDatabase() async {
    await openLocalDatabase(newDatabase: true);
  }
}
