import 'package:covidstats/detect.dart';
import 'package:covidstats/models/model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_plot/flutter_plot.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ShowCovidData extends StatefulWidget {
  ShowCovidData({Key? key, this.preds, this.covidData}) : super(key: key);
  double? preds;
  List? covidData;

  @override
  State<ShowCovidData> createState() => _ShowCovidDataState();
}

class DataMapper {
  DataMapper(this.day, this.cases);
  String day;
  double cases;
}

class _ShowCovidDataState extends State<ShowCovidData> {
  List<DataMapper> newCasesPlot = [];
  List<DataMapper> totalCasesPlot = [];
  String notificationToShow = '';
  bool showNotification = false;
  List get _covidData => widget.covidData!;
  double plotAnimationDelay = 3000;

  @override
  void initState() {
    super.initState();
    if (!Model.mainPageOpened) {
      Future.delayed(Duration(milliseconds: plotAnimationDelay.toInt()), () {
        if (Model.mainPageOpened) return;
        setState(() {
          Model.mainPageOpened = true;
        });
      });
    }
    for (int i = 1; i < _covidData.length; i++) {
      String day = _covidData[i][1].split('-')[2];
      double newCases = _covidData[i][3] / 10000;
      double totalCases = _covidData[i][2] / pow(10, 6);
      newCasesPlot.add(DataMapper(day, newCases));
      totalCasesPlot.add(DataMapper(day, totalCases));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.lightBlue, Colors.black],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft)),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: screenHeight / 20,
              ),
              backButton(context),
              plots(screenHeight)
            ],
          ),
        ),
      ),
    );
  }

  Widget backButton(context) {
    return ElevatedButton(
      style: ButtonStyle(
          elevation: MaterialStateProperty.all(0),
          shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          fixedSize: MaterialStateProperty.all(const Size(70, 45)),
          backgroundColor: MaterialStateProperty.all(Colors.white24)),
      onPressed: () {
        setState(() {
          Model.mainPageOpened = true;
        });

        Navigator.of(context).pop();
      },
      child: const Icon(Icons.arrow_back_outlined),
    );
  }

  Widget plots(screenHeight) {
    return Expanded(
      child: ListView(
        clipBehavior: Clip.antiAlias,
        children: [
          SizedBox(
              height: screenHeight / 1.8,
              child: plotData(newCasesPlot, 'New Cases (thousands)', true)),
          SizedBox(
            height: screenHeight / 20,
          ),
          SizedBox(
              height: screenHeight / 1.8,
              child: plotData(totalCasesPlot, 'Total Cases (millions)', false))
        ],
      ),
    );
  }

  Widget plotData(List<DataMapper> data, String title, bool plotNewCases) {
    return SfCartesianChart(
      title: ChartTitle(
          text: title, textStyle: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black12,
      plotAreaBackgroundColor: Colors.black26,
      borderColor: Colors.black,
      primaryXAxis: const CategoryAxis(
          labelStyle: TextStyle(color: Colors.white),
          title: AxisTitle(
              text: 'Dates', textStyle: TextStyle(color: Colors.white)),
          majorTickLines: MajorTickLines(size: 8, color: Colors.red, width: 4)),
      primaryYAxis: NumericAxis(
          labelStyle: const TextStyle(color: Colors.white),
          interval: !plotNewCases ? 10 : 20),
      series: <LineSeries>[
        LineSeries<DataMapper, String>(
            animationDuration: !Model.mainPageOpened ? plotAnimationDelay : 0,
            animationDelay: !Model.mainPageOpened ? 900 : 0,
            color: Colors.white,
            dataSource: data,
            xValueMapper: (DataMapper mapper, _) => mapper.day,
            yValueMapper: (DataMapper mapper, _) => mapper.cases),
      ],
    );
  }
}
