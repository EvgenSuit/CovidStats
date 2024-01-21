import 'dart:async';
import 'dart:io';
import 'package:covidstats/detect.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'models/model.dart';

class LoadPage extends StatefulWidget {
  LoadPage({Key? key, this.interpreter}) : super(key: key);
  Interpreter? interpreter;
  @override
  State<LoadPage> createState() => _LoadPageState();
}

class _LoadPageState extends State<LoadPage> {
  Interpreter get interpreter => widget.interpreter!;
  String appTitle = 'CovidStats';
  bool alreadyRunning = false;
  bool dataReady = false;
  String messageToPrint = '';
  bool dataExists = false;

  Future<void> downloadData() async {
    var uri = Uri.parse(Model.remoteUrl);
    var request = MultipartRequest('GET', uri);
    setState(() {
      messageToPrint = 'Fetching the data';
    });
    var response = await request.send();
    String data = await response.stream.bytesToString();
    setState(() {
      messageToPrint = 'Writing the data';
    });
    writeDataToFile(data, Model.covidDataPath);
    setState(() {
      messageToPrint = 'Data written';
    });
  }

  void writeDataToFile(String data, String path) {
    final file = File(path);
    file.writeAsStringSync(data);
    setState(() {
      dataReady = true;
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      dataExists = File(Model.covidDataPath).existsSync();
    });
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!dataExists && !alreadyRunning) {
        setState(() {
          alreadyRunning = true;
        });
        await downloadData();
      }
      if (dataReady || dataExists) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (c, a1, a2) => Detect(
              cameras: Model.cameras,
              interpreter: interpreter,
            ),
            transitionsBuilder: (c, anim, a2, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple, Colors.red],
                stops: [0.4, 0.7])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: screenHeight / 8,
              ),
              Text(appTitle,
                  style: Theme.of(context).textTheme.headline3!.merge(
                      const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white))),
              SizedBox(
                height: screenHeight / 2,
              ),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              SizedBox(
                height: screenHeight / 8,
              ),
              Text(messageToPrint,
                  style: const TextStyle(
                    color: Colors.white70,
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
