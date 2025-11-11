import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder audioRecorder = AudioRecorder();

  String ? recordingPath;
  bool isRecording = false;
  int number = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _recordingButton(),
    );
  }

  Widget _recordingButton(){
    return FloatingActionButton(onPressed: () async {
      void writeCountFile(int count) async{

      }


      if (isRecording) {
        String? filePath = await audioRecorder.stop();
        if (filePath != null){
          setState(() {
            isRecording = false;
            recordingPath = filePath;
            number += 1;
            writeCountFile(number);
          });
        }
      }
      else{
        if (await audioRecorder.hasPermission()){
          final Directory appDocumentsDir =
            await getApplicationDocumentsDirectory();
          final String filePath = p.join(appDocumentsDir.path, "recording.mp3");
          await audioRecorder.start(
            const RecordConfig(),
            path: filePath,
          );

          setState((){
            isRecording = true;
            recordingPath = null;
          });
        }
      }


    },
      child: Icon(
        isRecording ? Icons.stop: Icons.mic,
      ),
    );
  }

}