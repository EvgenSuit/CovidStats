import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class Model {
  static String remoteUrl = 'https://covstatistics.herokuapp.com/';
  static List<CameraDescription> cameras = [];
  static String covidDataPath = '';
  static bool mainPageOpened = false;
}
