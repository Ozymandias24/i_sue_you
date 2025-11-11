import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart' as audio;
import 'package:device_info_plus/device_info_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder audioRecorder = AudioRecorder();

  String? recordingPath;
  bool isRecording = false;
  bool isUploading = false;
  int number = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isUploading)
              const CircularProgressIndicator()
            else if (recordingPath != null)
              Text('Recording saved: ${p.basename(recordingPath!)}'),
            const SizedBox(height: 20),
            Text('Recordings count: $number'),
          ],
        ),
      ),
      floatingActionButton: _recordingButton(),
    );
  }

  Widget _recordingButton() {
    return FloatingActionButton(
      onPressed: isUploading ? null : () async {
        if (isRecording) {
          String? filePath = await audioRecorder.stop();
          if (filePath != null) {
            setState(() {
              isRecording = false;
              recordingPath = filePath;
              number += 1;
            });

            // Send the recorded file to server
            await sendAudioToServer(filePath);
          }
        }
        else {
          if (await audioRecorder.hasPermission()) {

            final Directory appDocumentsDir =
            await getApplicationDocumentsDirectory();
            debugPrint("file "+appDocumentsDir.path);

            // Use unique filename with timestamp
            final String fileName = "recording_${DateTime.now().millisecondsSinceEpoch}.mp3";
            final String filePath = p.join(appDocumentsDir.path, fileName);
            debugPrint("file "+fileName+" saved at: "+filePath);

            await audioRecorder.start(
              const RecordConfig(),
              path: filePath,
            );

            setState(() {
              isRecording = true;
              recordingPath = null;
            });
          }
        }
      },
      child: Icon(
        isRecording ? Icons.stop : Icons.mic,
      ),
    );
  }

  // Function to send audio file to server
  Future<void> sendAudioToServer(String filePath) async {
    setState(() {
      isUploading = true;
    });

    try {
      // Replace with your server URL
      final uri = Uri.parse('http://192.168.1.164:8000/uploadAudio');

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add the audio file
      var audioFile = await http.MultipartFile.fromPath(
        'audio', // Field name expected by your server
        filePath,
        filename: p.basename(filePath),
      );
      request.files.add(audioFile);

      // Add additional fields if needed
      request.fields['recording_number'] = number.toString();
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      // Optional: Add authentication headers
      // request.headers['Authorization'] = 'Bearer YOUR_TOKEN';

      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        // Success
        final responseBody = await response.stream.bytesToString();
        debugPrint('Upload successful: $responseBody');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio uploaded successfully!')),
          );
        }
      } else {
        // Error
        debugPrint('Upload failed: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    audioRecorder.dispose();
    super.dispose();
  }
}