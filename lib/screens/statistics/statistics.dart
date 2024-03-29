import 'package:flutter/material.dart';
import 'package:gym_buddy_app/config.dart';
import 'package:gym_buddy_app/database_helper.dart';
import 'package:gym_buddy_app/helper.dart';
import 'package:gym_buddy_app/screens/ats_ui_elements/ats_icon_button.dart';
import 'package:gym_buddy_app/screens/statistics/add_workout_session_screen.dart';
import 'package:gym_buddy_app/screens/statistics/single_workout_statistics_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StatisticsScreen extends StatefulWidget {
  StatisticsScreen({super.key});

  dynamic data;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();

    DatabaseHelper.getWeeklyStatistics().then((value) => setState(() {
          widget.data = value;
          print(widget.data);
        }));
  }

  DateTime dateTimeToDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data != null) {
      print(DateTime.now().subtract(const Duration(days: 1)) ?? 0);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('statistics'),
        leading: atsIconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          atsIconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AddWorkoutSessionScreen()));

              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('weekly statistics',
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                  'number of workouts: ${widget.data != null ? widget.data['workouts'] : 'xx'}'),
              Text(
                  'total kg lifted: ${widget.data != null ? widget.data['totalWeightLifted'] : "0.0"}'),
              Text(
                  'total time spent: ${widget.data != null ? Helper.prettyTime(widget.data['totalTimeSpent'] ?? 0) : 0}'),
              const SizedBox(height: 20),
              widget.data != null
                  ? SfCartesianChart(
                      // Initialize category axis
                      primaryXAxis: CategoryAxis(),
                      series: <LineSeries<dynamic, String>>[
                          LineSeries<dynamic, String>(
                              dataSource: <Map<DateTime, double>>[
                                {
                                  DateTime.now()
                                      .subtract(const Duration(days: 6)): widget
                                              .data['dailyTotalDuration'][
                                          dateTimeToDateOnly(DateTime.now()
                                              .subtract(
                                                  const Duration(days: 6)))] ??
                                      0
                                },
                                {
                                  DateTime.now()
                                      .subtract(const Duration(days: 5)): widget
                                              .data['dailyTotalDuration'][
                                          dateTimeToDateOnly(DateTime.now()
                                              .subtract(
                                                  const Duration(days: 5)))] ??
                                      0
                                },
                                {
                                  DateTime.now()
                                      .subtract(const Duration(days: 4)): widget
                                              .data['dailyTotalDuration'][
                                          dateTimeToDateOnly(DateTime.now()
                                              .subtract(
                                                  const Duration(days: 4)))] ??
                                      0
                                },
                                {
                                  DateTime.now()
                                      .subtract(const Duration(days: 3)): widget
                                              .data['dailyTotalDuration'][
                                          dateTimeToDateOnly(DateTime.now()
                                              .subtract(
                                                  const Duration(days: 3)))] ??
                                      0
                                },
                                {
                                  DateTime.now()
                                      .subtract(const Duration(days: 2)): widget
                                              .data['dailyTotalDuration'][
                                          dateTimeToDateOnly(DateTime.now()
                                              .subtract(
                                                  const Duration(days: 2)))] ??
                                      0
                                },
                                {
                                  DateTime.now()
                                      .subtract(const Duration(days: 1)): widget
                                              .data['dailyTotalDuration'][
                                          dateTimeToDateOnly(DateTime.now()
                                              .subtract(
                                                  const Duration(days: 1)))] ??
                                      0
                                },
                                {
                                  DateTime.now(): widget
                                              .data['dailyTotalDuration'][
                                          dateTimeToDateOnly(DateTime.now())] ??
                                      0
                                },
                              ],
                              xValueMapper: (dynamic sales, _) =>
                                  sales.keys.first.day.toString(),
                              yValueMapper: (dynamic sales, _) =>
                                  sales.values.first)
                        ])
                  : const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('history', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              FutureBuilder(
                  future: DatabaseHelper.getAllWorkoutSessions(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (!snapshot.hasData) {
                        return const Text('no workout sessions found');
                      } else {
                        if (snapshot.data.length > 0) {
                          return ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: snapshot.data.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ListTile(
                                    onTap: () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SingleWorkoutStatsisticsScreen(
                                                      workout: snapshot
                                                          .data[index])));

                                      setState(() {});
                                    },
                                    tileColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    title: Text(snapshot.data[index].name),
                                    subtitle: Text(
                                        'at ${snapshot.data[index].startTime!.hour.toString().padLeft(2, '0')}:${snapshot.data[index].startTime!.minute.toString().padLeft(2, '0')} for ${Helper.prettyTime(snapshot.data[index].duration)} - ${Helper.getWeightInCorrectUnit(snapshot.data[index].totalWeightLifted).toStringAsFixed(2)} total ${Config.getUnitAbbreviation()} lifted'),
                                  ),
                                );
                              });
                        } else {
                          return const Text('no workout sessions found');
                        }
                      }
                    } else {
                      return const CircularProgressIndicator();
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
