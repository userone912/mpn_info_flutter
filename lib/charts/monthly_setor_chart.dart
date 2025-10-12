import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../core/constants/app_constants.dart';
// Import any other dependencies needed for chart logic

class MonthlySetorChart extends StatelessWidget {
  final int chartRefreshKey;
  final String chartTypeMonthlySetor;
  final List<String> chartTypes;
  final String selectedDataset;
  final String selectedDatasetLabel;
  final List<Map<String, dynamic>> dashboardData;
  final List<Map<String, dynamic>> monthlyRenpenData;
  final Function(String) onChartTypeChanged;

  const MonthlySetorChart({
    Key? key,
    required this.chartRefreshKey,
    required this.chartTypeMonthlySetor,
    required this.chartTypes,
    required this.selectedDataset,
    required this.selectedDatasetLabel,
    required this.dashboardData,
    required this.monthlyRenpenData,
    required this.onChartTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use dashboardData and selectedDataset to determine chart data
    List<Map<String, dynamic>> data = dashboardData;
    List<Map<String, dynamic>> renpenData = monthlyRenpenData;
    String flagKey;
    if (selectedDataset == 'PKPM') {
      flagKey = 'FLAG_PKPM';
    } else if (selectedDataset == 'BO') {
      flagKey = 'FLAG_BO';
    } else if (selectedDataset == 'VOLUNTARY') {
      flagKey = 'VOLUNTARY';
    } else {
      flagKey = '';
    }
    Widget chartWidget;
    // Safe checks for empty or mismatched data
    if (data.isEmpty && renpenData.isEmpty) {
      chartWidget = const Center(child: CircularProgressIndicator());
    } else if (chartTypeMonthlySetor == 'Bar') {
      final Map<String, Map<String, double>> grouped = {};
      final Map<String, double> flagTotals = {};
      for (var row in data) {
        final bln = row['BLN_SETOR']?.toString() ?? '';
        final flag = row[flagKey]?.toString() ?? '';
        final total = (row['total_setor'] ?? 0).toDouble();
        grouped[bln] ??= {};
        grouped[bln]![flag] = total;
        flagTotals[flag] = (flagTotals[flag] ?? 0) + total;
      }
      // Prepare Renpen monthly map: {bln: total_target}
      final Map<String, double> renpenMonthly = {};
      for (var row in renpenData) {
        final bln = row['BLN_SETOR']?.toString() ?? '';
        final total = (row['total_target'] ?? 0).toDouble();
        renpenMonthly[bln] = total;
      }
      final flagList = flagTotals.keys.where((e) => e.isNotEmpty).toList()
        ..sort((a, b) => flagTotals[a]!.compareTo(flagTotals[b]!));
      final monthNames = AppConstants.indonesianMonthsShort;
      final blnList = List.generate(12, (i) => (i + 1).toString());
      final chartData = [
        for (int i = 0; i < blnList.length && i < monthNames.length; i++)
          {
            'month': monthNames[i],
            for (final flag in flagList)
              flag: grouped[blnList[i]]?[flag] ?? 0.0,
            'REN': renpenMonthly[blnList[i]] ?? 0.0,
          }
      ];
      String formatCurrency(num val) {
        String s = val.toStringAsFixed(0);
        final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
        s = s.replaceAllMapped(reg, (Match m) => '${m[1]}${AppConstants.thousandSeparator}');
        return '${AppConstants.currencySymbol} $s';
      }
      chartWidget = SfCartesianChart(
        key: ValueKey(chartRefreshKey),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        zoomPanBehavior: ZoomPanBehavior(
          enablePinching: true,
          enablePanning: true,
          zoomMode: ZoomMode.xy,
        ),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
          labelStyle: const TextStyle(fontSize: 10),
          axisLabelFormatter: (AxisLabelRenderDetails details) {
            final value = details.value;
            String formatted;
            if (value >= 1000000000) {
              formatted = '${AppConstants.currencySymbol} ${(value / 1000000000).toStringAsFixed(1).replaceAll('.', AppConstants.decimalSeparator)}M';
            } else if (value >= 1000000) {
              formatted = '${AppConstants.currencySymbol} ${(value / 1000000).toStringAsFixed(1).replaceAll('.', AppConstants.decimalSeparator)}Jt';
            } else {
              formatted = formatCurrency(value);
            }
            return ChartAxisLabel(formatted, const TextStyle(fontSize: 10));
          },
        ),
        series: [
          for (int j = 0; j < flagList.length; j++)
            if (j >= 0 && j < flagList.length)
              StackedColumnSeries<dynamic, String>(
                dataSource: chartData,
                xValueMapper: (d, _) => d['month'],
                yValueMapper: (d, _) => d[flagList[j]],
                name: flagList[j],
                color: Colors.primaries[j % Colors.primaries.length],
                dataLabelSettings: const DataLabelSettings(isVisible: false),
              ),
          // Renpen series (always last, distinct color)
          ColumnSeries<dynamic, String>(
            dataSource: chartData,
            xValueMapper: (d, _) => d['month'],
            yValueMapper: (d, _) => d['REN'],
            name: 'Renpen',
            color: Colors.deepPurple,
            dataLabelSettings: const DataLabelSettings(isVisible: false),
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: null,
          builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
            final month = data['month'];
            String flag = '';
            double value = 0.0;
            if (seriesIndex < flagList.length) {
              flag = flagList[seriesIndex];
              value = flag.isNotEmpty ? (data[flag] ?? 0.0) : 0.0;
            } else if (seriesIndex == flagList.length) {
              flag = 'Renpen';
              value = data['REN'] ?? 0.0;
            }
            double totalBar = 0.0;
            for (final f in flagList) {
              totalBar += data[f] ?? 0.0;
            }
            totalBar += data['REN'] ?? 0.0;
            final percent = totalBar > 0 ? (value / totalBar * 100) : 0.0;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$month', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(flag.isNotEmpty ? '$flag: ${formatCurrency(value)}' : ''),
                  Text(flag.isNotEmpty ? '(${percent.toStringAsFixed(1)}% dari total)' : ''),
                ],
              ),
            );
          },
        ),
      );
    } else if (chartTypeMonthlySetor == 'Line') {
      final Map<String, Map<String, double>> grouped = {};
      final Set<String> flagSet = {};
      for (var row in data) {
        final bln = row['BLN_SETOR']?.toString() ?? '';
        final flag = row[flagKey]?.toString() ?? '';
        final total = (row['total_setor'] ?? 0).toDouble();
        if (flag.isNotEmpty) flagSet.add(flag);
        grouped[flag] ??= {};
        grouped[flag]![bln] = total;
      }
      // Prepare Renpen monthly map: {bln: total_target}
      final Map<String, double> renpenMonthly = {};
      for (var row in renpenData) {
        final bln = row['BLN_SETOR']?.toString() ?? '';
        final total = (row['total_target'] ?? 0).toDouble();
        renpenMonthly[bln] = total;
      }
      final flagList = flagSet.toList()..sort();
      final monthNames = AppConstants.indonesianMonthsShort;
      final blnList = List.generate(12, (i) => (i + 1).toString());
      List<CartesianSeries<dynamic, String>> series = [];
      for (int f = 0; f < flagList.length; f++) {
        if (f >= 0 && f < flagList.length) {
          final flag = flagList[f];
          final color = Colors.primaries[f % Colors.primaries.length];
          final chartData = [
            for (int i = 0; i < blnList.length && i < monthNames.length; i++)
              {
                'month': monthNames[i],
                'value': grouped[flag]?[blnList[i]] ?? 0.0,
              },
          ];
          series.add(
            LineSeries<dynamic, String>(
              dataSource: chartData,
              xValueMapper: (d, _) => d['month'],
              yValueMapper: (d, _) => d['value'],
              name: flag,
              color: color,
              dataLabelSettings: const DataLabelSettings(isVisible: false),
              markerSettings: const MarkerSettings(isVisible: false),
            ),
          );
        }
      }
      // Renpen line series
      final renpenChartData = [
        for (int i = 0; i < blnList.length && i < monthNames.length; i++)
          {
            'month': monthNames[i],
            'value': renpenMonthly[blnList[i]] ?? 0.0,
          },
      ];
      series.add(
        LineSeries<dynamic, String>(
          dataSource: renpenChartData,
          xValueMapper: (d, _) => d['month'],
          yValueMapper: (d, _) => d['value'],
          name: 'Renpen',
          color: Colors.deepPurple,
          dataLabelSettings: const DataLabelSettings(isVisible: false),
          markerSettings: const MarkerSettings(isVisible: false),
        ),
      );
      chartWidget = SfCartesianChart(
        key: ValueKey(chartRefreshKey),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
          labelStyle: const TextStyle(fontSize: 10),
          axisLabelFormatter: (AxisLabelRenderDetails details) {
            final value = details.value;
            String formatted;
            String formatCurrency(num val) {
              String s = val.toStringAsFixed(0);
              final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
              s = s.replaceAllMapped(reg, (Match m) => '${m[1]}${AppConstants.thousandSeparator}');
              return '${AppConstants.currencySymbol} $s';
            }
            if (value >= 1000000000) {
              formatted = '${AppConstants.currencySymbol} ${(value / 1000000000).toStringAsFixed(1).replaceAll('.', AppConstants.decimalSeparator)}M';
            } else if (value >= 1000000) {
              formatted = '${AppConstants.currencySymbol} ${(value / 1000000).toStringAsFixed(1).replaceAll('.', AppConstants.decimalSeparator)}Jt';
            } else {
              formatted = formatCurrency(value);
            }
            return ChartAxisLabel(formatted, const TextStyle(fontSize: 10));
          },
        ),
        series: series,
        tooltipBehavior: TooltipBehavior(enable: true),
      );
    } else if (chartTypeMonthlySetor == 'Pie') {
      final Map<String, double> flagTotals = {};
      for (var row in data) {
        final flag = row[flagKey]?.toString() ?? '';
        final total = (row['total_setor'] ?? 0).toDouble();
        if (flag.isNotEmpty) flagTotals[flag] = (flagTotals[flag] ?? 0) + total;
      }
      final flagList = flagTotals.keys.toList()..sort();
      double totalAll = flagTotals.values.fold(0, (a, b) => a + b);
      final chartData = [
        for (int i = 0; i < flagList.length; i++)
          {
            'flag': flagList[i],
            'value': flagTotals[flagList[i]] ?? 0.0,
            'percent': totalAll > 0
                ? (flagTotals[flagList[i]]! / totalAll * 100)
                : 0.0,
          },
      ];
      chartWidget = SfCircularChart(
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        series: [
          PieSeries<dynamic, String>(
            dataSource: chartData,
            xValueMapper: (d, _) => d['flag'],
            yValueMapper: (d, _) => d['value'],
            dataLabelMapper: (d, _) =>
                '${d['flag']}\n${d['percent'].toStringAsFixed(1)}%',
            pointColorMapper: (d, i) =>
                Colors.primaries[i % Colors.primaries.length],
            radius: '60%',
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
        tooltipBehavior: TooltipBehavior(enable: true),
      );
    } else {
      chartWidget = const Center(child: Text('Unknown Chart Type'));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  key: const ValueKey('chartTypeSwitchMonthlySetor'),
                  onTap: () {
                    final idx = chartTypes.indexOf(chartTypeMonthlySetor);
                    onChartTypeChanged(chartTypes[(idx + 1) % chartTypes.length]);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          chartTypeMonthlySetor == 'Bar' ? Icons.bar_chart :
                          chartTypeMonthlySetor == 'Line' ? Icons.show_chart :
                          Icons.pie_chart,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(chartTypeMonthlySetor, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Show selected dataset label in chart header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedDatasetLabel,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: ClipRect(
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  boundaryMargin: const EdgeInsets.all(50),
                  child: chartWidget,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
