import 'dart:async';
import 'models/model.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'show_covid_data.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart';

class Detect extends StatefulWidget {
  Detect({Key? key, required this.cameras, this.interpreter}) : super(key: key);
  List<CameraDescription> cameras;
  Interpreter? interpreter;

  @override
  State<Detect> createState() => _DetectState();
}

class _DetectState extends State<Detect> {
  Interpreter get _interpreter => widget.interpreter!;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool pressed = false;
  List data = [];
  int imgSize = 224;
  List<CameraDescription> get cameras => widget.cameras;
  bool cameraSetupChanged = false;
  double buttonIconsSize = 35;
  String snackBarMessage = 'Make sure to wear your mask';

  void initCameraController(CameraDescription camera) {
    setState(() {
      _controller = CameraController(camera, ResolutionPreset.ultraHigh,
          enableAudio: false);
      _initializeControllerFuture = _controller.initialize();
    });
  }

  @override
  void initState() {
    super.initState();
    initCameraController(cameras[1]);

    String filePath = Model.covidDataPath;
    if (File(filePath).existsSync()) {
      final file = File(filePath);
      try {
        setState(() {
          data = json.decode(file.readAsStringSync());
        });
      } catch (e) {
        print(e);
        setState(() {
          snackBarMessage = 'Check your internet connection';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              cameraView(screenHeight),
              Positioned(
                child: bottomButtons(screenWidth),
                bottom: 10,
              ),
            ],
          )
        ],
      ),
    );
  }

  cameraView(screenHeight) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return SizedBox(
            height: screenHeight,
            child: CameraPreview(_controller),
          );
        } else {
          return Center(
            child: Container(
              height: screenHeight,
              color: Colors.black,
            ),
          );
        }
      },
    );
  }

  Widget bottomButtons(screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
            style: buttonStyle(),
            onPressed: () {
              if (!cameraSetupChanged) {
                initCameraController(cameras[0]);
                setState(() {
                  cameraSetupChanged = true;
                });
              } else {
                initCameraController(cameras[1]);
                setState(() {
                  cameraSetupChanged = false;
                });
              }
            },
            child: cameraSetupChanged
                ? Icon(
                    Icons.camera_rear_rounded,
                    color: Colors.blue,
                    size: buttonIconsSize,
                  )
                : Icon(
                    Icons.camera_front_outlined,
                    color: Colors.white,
                    size: buttonIconsSize,
                  )),
        SizedBox(
          width: screenWidth / 2,
        ),
        ElevatedButton(
            style: buttonStyle(),
            onPressed: makePrediction,
            child: Icon(
              Icons.arrow_right_alt_sharp,
              size: buttonIconsSize,
            )),
      ],
    );
  }

  ButtonStyle buttonStyle() {
    return ButtonStyle(
        elevation: MaterialStateProperty.all(0),
        fixedSize: MaterialStateProperty.all(const Size(100, 70)),
        backgroundColor: MaterialStateProperty.all(Colors.transparent));
  }

  void makePrediction() async {
    if (pressed) return;
    setState(() {
      pressed = true;
    });
    await _initializeControllerFuture;
    XFile imageFile = await _controller.takePicture();

    final imageData = File(imageFile.path).readAsBytesSync();
    final dataResized =
        copyResize(decodeImage(imageData)!, width: imgSize, height: imgSize);
    Uint8List imgAsList = dataResized.getBytes().buffer.asUint8List();
    Float32List resultBytes =
        Float32List.fromList(List.filled(imgSize * imgSize * 3, 0));

    for (int i = 0; i < imgAsList.length; i += 1) {
      resultBytes[i] = imgAsList[i].toDouble();
    }
    var input = resultBytes.reshape([1, imgSize, imgSize, 3]);
    final output = List<double>.filled(1, 0).reshape([1, 1]);
    _interpreter.run(input, output);

    double preds = output[0][0];

    if (preds > 0.45) {
      final snackBar = SnackBar(
        content: Text(snackBarMessage),
        duration: Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    setState(() {
      pressed = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowCovidData(
          preds: preds,
          covidData: data,
        ),
      ),
    );
  }
}
