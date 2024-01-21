import 'dart:io';
import 'models/model.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart';
import 'detect.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'loading_screen.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  final cameras = await availableCameras();
  Model.cameras = cameras;
  String workingDir = (await getApplicationDocumentsDirectory()).path;
  Model.covidDataPath = '$workingDir/covid_data.txt';
  await AndroidAlarmManager.periodic(
      const Duration(days: 1), 0, () => downloadData(workingDir),
      allowWhileIdle: true, exact: true, startAt: DateTime.now());
  Interpreter interpreter = await Interpreter.fromAsset('assets/model.tflite');

  runApp(MyApp(
    cameras: cameras,
    interpreter: interpreter,
  ));
}

void downloadData(String workingDir) async {
  var uri = Uri.parse(Model.remoteUrl);
  var request = MultipartRequest('GET', uri);
  var response = await request.send();
  String data = await response.stream.bytesToString();
  writeDataToFile(data, workingDir);
}

void writeDataToFile(String data, String directory) {
  final file = File(Model.covidDataPath);
  file.writeAsStringSync(data);
}

class MyApp extends StatelessWidget {
  MyApp({Key? key, this.cameras, this.interpreter}) : super(key: key);
  List<CameraDescription>? cameras;
  Interpreter? interpreter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        routes: {
          'detect': (context) => Detect(
                cameras: cameras!,
                interpreter: interpreter,
              )
        },
        home: LoadPage(
          interpreter: interpreter,
        ));
  }
}
