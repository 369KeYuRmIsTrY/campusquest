import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:campusquest/theme/theme.dart';

class AttendancePieChart extends StatelessWidget {
  final double attendancePercentage;

  const AttendancePieChart({Key? key, required this.attendancePercentage})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: attendancePercentage,
                  color: AppTheme.yachtClubBlue,
                  radius: 40,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: 100 - attendancePercentage,
                  color: Colors.grey.shade200,
                  radius: 40,
                  showTitle: false,
                ),
              ],
              sectionsSpace: 0,
              centerSpaceRadius: 30,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${attendancePercentage.toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.yachtClubBlueSwatch.shade700,
                  ),
                ),
                const Text(
                  'Present',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
