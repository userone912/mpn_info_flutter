import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:data_table_2/data_table_2.dart';
import '../core/constants/app_constants.dart';
// Import any other dependencies needed for chart logic

class MonthlySetorChart extends StatefulWidget {
  final int chartRefreshKey;
  final String chartTypeMonthlySetor;
  final List<String> chartTypes;
  final String selectedDataset;
  final String selectedDatasetLabel;
  final List<Map<String, dynamic>> dashboardData;
  final List<Map<String, dynamic>> monthlyRenpenData;
  final String? selectedBusinessOwner;
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
    required this.selectedBusinessOwner,
    required this.onChartTypeChanged,
  }) : super(key: key);

  @override
  State<MonthlySetorChart> createState() => _MonthlySetorChartState();
}

class _MonthlySetorChartState extends State<MonthlySetorChart> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _horizontalHeaderController = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizontalBodyController.addListener(() {
      if (_horizontalHeaderController.hasClients &&
          _horizontalHeaderController.offset !=
              _horizontalBodyController.offset) {
        _horizontalHeaderController.jumpTo(_horizontalBodyController.offset);
      }
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalHeaderController.dispose();
    _horizontalBodyController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Use dashboardData and selectedDataset to determine chart data
    List<Map<String, dynamic>> data = widget.dashboardData;
    if (widget.selectedBusinessOwner != null &&
        widget.selectedBusinessOwner!.isNotEmpty) {
      data = data
          .where((row) => row['FLAG_BO'] == widget.selectedBusinessOwner)
          .toList();
    }
    List<Map<String, dynamic>> renpenData = widget.monthlyRenpenData;
    String flagKey;
    if (widget.selectedDataset == 'PKPM') {
      flagKey = 'FLAG_PKPM';
    } else if (widget.selectedDataset == 'VOLUNTARY') {
      flagKey = 'VOLUNTARY';
    } else {
      flagKey = '';
    }
    Widget chartWidget;
    // Safe checks for empty or mismatched data
    if (data.isEmpty && renpenData.isEmpty) {
      chartWidget = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (widget.chartTypeMonthlySetor == 'Bar') {
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
          },
      ];
      String formatCurrency(num val) {
        String s = val.toStringAsFixed(0);
        final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
        s = s.replaceAllMapped(
          reg,
          (Match m) => '${m[1]}${AppConstants.thousandSeparator}',
        );
        return '${AppConstants.currencySymbol} $s';
      }

      chartWidget = SfCartesianChart(
        key: ValueKey(widget.chartRefreshKey),
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
              formatted =
                  '${AppConstants.currencySymbol} ${(value / 1000000000).toStringAsFixed(1).replaceAll('.', AppConstants.decimalSeparator)}M';
            } else if (value >= 1000000) {
              formatted =
                  '${AppConstants.currencySymbol} ${(value / 1000000).toStringAsFixed(1).replaceAll('.', AppConstants.decimalSeparator)}Jt';
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
                name: (() {
                  String label = flagList[j];
                  if (widget.selectedDataset == 'VOLUNTARY') {
                    // Use AppConstants.voluntaryFlagLabels for legend
                    if (label == 'W')
                      label = AppConstants.voluntaryFlagLabels[0];
                    else if (label == 'N')
                      label = AppConstants.voluntaryFlagLabels[1];
                    else if (label == 'Y')
                      label = AppConstants.voluntaryFlagLabels[2];
                  }
                  return label;
                })(),
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
          builder:
              (
                dynamic data,
                dynamic point,
                dynamic series,
                int pointIndex,
                int seriesIndex,
              ) {
                final month = data['month'];
                String flag = '';
                double value = 0.00;
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
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$month',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        flag.isNotEmpty
                            ? '$flag: ${formatCurrency(value)}'
                            : '',
                      ),
                      Text(
                        flag.isNotEmpty
                            ? '(${percent.toStringAsFixed(4)}% dari total)'
                            : '',
                      ),
                    ],
                  ),
                );
              },
        ),
      );
      // Add a DataTable below the chart for tabulated data
      chartWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- Bagian Chart ---
          chartWidget,
          const SizedBox(height: 16),

          // --- Bagian Tabel dengan scroll tersendiri ---
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 1000, // agar bisa scroll horizontal otomatis
              fixedTopRows: 1, // header sticky
              headingRowColor: MaterialStateProperty.resolveWith(
                (states) => Colors.grey.shade100,
              ),
              dataRowColor: MaterialStateProperty.resolveWith<Color?>((states) {
                if (states.contains(MaterialState.hovered))
                  return Colors.blue.shade100; // highlight hover
                // Zebra pattern: genap putih, ganjil biru muda
                int index = chartData.indexWhere(
                  (row) => chartData.indexOf(row) == chartData.indexOf(row),
                );
                return index.isEven ? Colors.white : Colors.blue.shade50;
              }),

              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.grey.shade300, width: 1),
                outside: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              columns: [
                const DataColumn2(label: Text('Bulan'), size: ColumnSize.S),
                ...flagList.map((flag) {
                  String label = flag;
                  if (widget.selectedDataset == 'VOLUNTARY') {
                    if (flag == 'W')
                      label = AppConstants.voluntaryFlagLabels[0];
                    else if (flag == 'N')
                      label = AppConstants.voluntaryFlagLabels[1];
                    else if (flag == 'Y')
                      label = AppConstants.voluntaryFlagLabels[2];
                  }
                  return DataColumn2(
                    label: Text(label),
                    size: ColumnSize.M,
                    numeric: true,
                  );
                }),
                const DataColumn2(
                  label: Text('Renpen'),
                  size: ColumnSize.M,
                  numeric: true,
                ),
                const DataColumn2(
                  label: Text('% dari Renpen'),
                  size: ColumnSize.M,
                  numeric: true,
                ),
              ],
              rows: [
                // --- Data utama ---
                ...chartData.map((row) {
                  final renpen = (row['REN'] is num ? row['REN'] : 0.0) as num;
                  final sumOther = flagList.fold<num>(
                    0.0,
                    (sum, flag) =>
                        sum + ((row[flag] is num ? row[flag] : 0.0) as num),
                  );
                  final percent = renpen > 0 ? (sumOther / renpen * 100) : 0.0;

                  TextStyle rightAlign = const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  );

                  return DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(MaterialState.hovered))
                        return Colors.blue.shade100; // hover
                      int index = chartData.indexOf(
                        row,
                      ); // hitung indeks untuk zebra
                      return index.isEven
                          ? Colors.white
                          : Colors.blue.shade50; // zebra putih & biru muda
                    }),
                    cells: [
                      DataCell(
                        Text(
                          (row['month'] ?? '').toString(),
                          style: rightAlign,
                        ),
                      ),
                      ...flagList.map(
                        (flag) => DataCell(
                          Text(
                            formatCurrency(
                              (row[flag] is num ? row[flag] : 0.0) as num,
                            ),
                            style: rightAlign,
                          ),
                        ),
                      ),
                      DataCell(Text(formatCurrency(renpen), style: rightAlign)),
                      DataCell(
                        Text(
                          '${percent.toStringAsFixed(4)}%',
                          style: rightAlign,
                        ),
                      ),
                    ],
                  );
                }),

                // --- Baris Grand Total ---
                (() {
                  TextStyle boldRight = const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  );
                  final totalFlagValues = {
                    for (final flag in flagList)
                      flag: chartData.fold<num>(
                        0.0,
                        (sum, row) =>
                            sum + ((row[flag] is num ? row[flag] : 0.0) as num),
                      ),
                  };
                  final totalRenpen = chartData.fold<num>(
                    0.0,
                    (sum, row) =>
                        sum + ((row['REN'] is num ? row['REN'] : 0.0) as num),
                  );
                  final totalOther = flagList.fold<num>(
                    0.0,
                    (sum, flag) => sum + totalFlagValues[flag]!,
                  );
                  final percentTotal = totalRenpen > 0
                      ? (totalOther / totalRenpen * 100)
                      : 0.0;

                  return DataRow(
                    color: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.hovered))
                        return Colors.blue.shade100;
                      return Colors.grey.shade200; // warna default Grand Total
                    }),
                    cells: [
                      DataCell(Text('Grand Total', style: boldRight)),
                      ...flagList.map(
                        (flag) => DataCell(
                          Text(
                            formatCurrency(totalFlagValues[flag]!),
                            style: boldRight,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(formatCurrency(totalRenpen), style: boldRight),
                      ),
                      DataCell(
                        Text(
                          '${percentTotal.toStringAsFixed(3)}%',
                          style: boldRight,
                        ),
                      ),
                    ],
                  );
                })(),
              ],
            ),
          ),
        ],
      );
    } else if (widget.chartTypeMonthlySetor == 'Line') {
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
          String legendLabel = flag;
          if (widget.selectedDataset == 'VOLUNTARY') {
            if (flag == 'W')
              legendLabel = AppConstants.voluntaryFlagLabels[0];
            else if (flag == 'N')
              legendLabel = AppConstants.voluntaryFlagLabels[1];
            else if (flag == 'Y')
              legendLabel = AppConstants.voluntaryFlagLabels[2];
          }
          series.add(
            LineSeries<dynamic, String>(
              dataSource: chartData,
              xValueMapper: (d, _) => d['month'],
              yValueMapper: (d, _) => d['value'],
              name: legendLabel,
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
          {'month': monthNames[i], 'value': renpenMonthly[blnList[i]] ?? 0.0},
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
        key: ValueKey(widget.chartRefreshKey),
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
              s = s.replaceAllMapped(
                reg,
                (Match m) => '${m[1]}${AppConstants.thousandSeparator}',
              );
              return '${AppConstants.currencySymbol} $s';
            }

            if (value >= 1000000000) {
              formatted =
                  '${AppConstants.currencySymbol} ${(value / 1000000000).toStringAsFixed(1).replaceAll('.', AppConstants.decimalSeparator)}M';
            } else if (value >= 1000000) {
              formatted =
                  '${AppConstants.currencySymbol} ${(value / 1000000).toStringAsFixed(1).replaceAll('.', AppConstants.decimalSeparator)}Jt';
            } else {
              formatted = formatCurrency(value);
            }
            return ChartAxisLabel(formatted, const TextStyle(fontSize: 10));
          },
        ),
        series: series,
        tooltipBehavior: TooltipBehavior(enable: true),
      );
    } else if (widget.chartTypeMonthlySetor == 'Pie') {
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
            'flag': (() {
              String legendLabel = flagList[i];
              if (widget.selectedDataset == 'VOLUNTARY') {
                if (legendLabel == 'W')
                  legendLabel = AppConstants.voluntaryFlagLabels[0];
                else if (legendLabel == 'N')
                  legendLabel = AppConstants.voluntaryFlagLabels[1];
                else if (legendLabel == 'Y')
                  legendLabel = AppConstants.voluntaryFlagLabels[2];
              }
              return legendLabel;
            })(),
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
                '${d['flag']}\n${d['percent'].toStringAsFixed(4)}%',
            pointColorMapper: (d, i) =>
                Colors.primaries[i % Colors.primaries.length],
            radius: '60%',
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              // Dynamic color: white if label is inside, black if outside
              labelPosition: ChartDataLabelPosition.inside,
              // Use builder for dynamic color
              builder:
                  (
                    dynamic data,
                    dynamic point,
                    dynamic series,
                    int pointIndex,
                    int seriesIndex,
                  ) {
                    final percent = data['percent'] ?? 0.0;
                    // If percent > 10, assume label is inside, else outside (tweak as needed)
                    final isInside = percent > 10.0;
                    final textColor = isInside ? Colors.white : Colors.black;
                    return Text(
                      '${data['flag']}\n${percent.toStringAsFixed(4)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
            ),
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: null,
          builder:
              (
                dynamic data,
                dynamic point,
                dynamic series,
                int pointIndex,
                int seriesIndex,
              ) {
                String flag = data['flag'] ?? '';
                if (widget.selectedDataset == 'VOLUNTARY') {
                  if (flag == 'W')
                    flag = AppConstants.voluntaryFlagLabels[0];
                  else if (flag == 'N')
                    flag = AppConstants.voluntaryFlagLabels[1];
                  else if (flag == 'Y')
                    flag = AppConstants.voluntaryFlagLabels[2];
                }
                double value = data['value'] ?? 0.0;
                double percent = data['percent'] ?? 0.0;
                String formatCurrency(num val) {
                  String s = val.toStringAsFixed(0);
                  final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
                  s = s.replaceAllMapped(
                    reg,
                    (Match m) => '${m[1]}${AppConstants.thousandSeparator}',
                  );
                  return '${AppConstants.currencySymbol} $s';
                }

                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flag,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Nilai: ${formatCurrency(value)}'),
                      Text('(${percent.toStringAsFixed(4)}% dari total)'),
                    ],
                  ),
                );
              },
        ),
      );
    } else {
      chartWidget = const Center(child: Text('Unknown Chart Type'));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth,
                child: ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          key: const ValueKey('chartTypeSwitchMonthlySetor'),
                          onTap: () {
                            final idx = widget.chartTypes.indexOf(
                              widget.chartTypeMonthlySetor,
                            );
                            widget.onChartTypeChanged(
                              widget.chartTypes[(idx + 1) %
                                  widget.chartTypes.length],
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.chartTypeMonthlySetor == 'Bar'
                                      ? Icons.bar_chart
                                      : widget.chartTypeMonthlySetor == 'Line'
                                      ? Icons.show_chart
                                      : Icons.pie_chart,
                                  color: Colors.blue.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.chartTypeMonthlySetor,
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Show selected dataset label in chart header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.selectedDatasetLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    chartWidget,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
