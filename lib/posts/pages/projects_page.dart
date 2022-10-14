import 'package:flutter/material.dart';
import 'package:sylvest_flutter/posts/pages/post_detail_page.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/image_service.dart';



class MostFundedData {
  final String title;
  final String? authorImage;
  final double currentFund;
  final int id;

  const MostFundedData(
      {required this.title,
      required this.id,
      required this.authorImage,
      required this.currentFund});

  factory MostFundedData.fromJson(Map json) {
    return MostFundedData(
        title: json['title'],
        id: json['id'],
        authorImage: json["author_details"]['image'],
        currentFund: json['project_fields']["total_funded"]);
  }
}

class MostFundedProjects extends StatelessWidget {
  final List<MostFundedData> mostFunded;
  final double max;

  final _barGradient = const LinearGradient(
    colors: [Color.fromARGB(255, 187, 170, 224), Colors.white],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  const MostFundedProjects(
      {Key? key, required this.mostFunded, required this.max})
      : super(key: key);

  String _titleShortner(String title) {
    if (title.length <= 12) return title;
    return title.substring(0, 10) + "...";
  }

  Widget _topFundedChart(context) {
    return BarChart(
      BarChartData(
          barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.transparent,
                tooltipPadding: const EdgeInsets.all(0),
                tooltipMargin: 8,
                getTooltipItem: (
                  BarChartGroupData group,
                  int groupIndex,
                  BarChartRodData rod,
                  int rodIndex,
                ) {
                  return BarTooltipItem(
                    rod.toY.round().toString(),
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              )),
          titlesData: FlTitlesData(
              show: true,
              topTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return SizedBox();
                      })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 70,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        return SideTitleWidget(
                          child: InkWell(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PostDetailPage(
                                          mostFunded[index].id))),
                              child: Column(
                                children: [
                                  SylvestImageProvider(
                                    url: mostFunded[index].authorImage,),
                                  Text(
                                    _titleShortner(mostFunded[index].title),
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 10),
                                  )
                                ],
                              )),
                          axisSide: meta.axisSide,
                          space: 4.0,
                        );
                      }))),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(mostFunded.length, (index) {
            return BarChartGroupData(x: index, showingTooltipIndicators: [
              0
            ], barRods: [
              BarChartRodData(
                  toY: mostFunded[index].currentFund, gradient: _barGradient)
            ]);
          }),
          gridData: FlGridData(show: false),
          alignment: BarChartAlignment.spaceAround,
          maxY: max),
    );
  }

  @override
  Widget build(context) {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)
          ],
          color: const Color(0xFF733CE6),
          gradient: LinearGradient(colors: [
            const Color(0xFF733CE6),
            Color.fromARGB(255, 163, 138, 218)
          ]),
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: AspectRatio(
        aspectRatio: 2,
        child: _topFundedChart(context),
      ),
    );
  }
}
