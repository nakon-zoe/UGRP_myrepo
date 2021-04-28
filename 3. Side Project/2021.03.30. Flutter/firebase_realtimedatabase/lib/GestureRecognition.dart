import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GestureRecognition extends StatefulWidget {

  GestureRecognition({this.app, this.camera});
  final FirebaseApp app;
  final CameraDescription camera;

  @override
  _GestureRecognitionState createState() => _GestureRecognitionState();
}

class _GestureRecognitionState extends State<GestureRecognition> {

  final referenceDatabase = FirebaseDatabase.instance;
  final tag = 'photo';
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  num _state = 0;

  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void dispose() {
    _controller.dispose(); // 위젯의 생명주기 종료 시 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    String downpath;

    Future<void> tagUpdate = new Future( () async {
      final ref = referenceDatabase.reference();
      final cameras = await availableCameras(); // 디바이스에서 이용 가능한 카메라 목록 가져오기
      _controller = CameraController( // 카메라의 현재 출력물을 보여주기 위해 CameraController 생성
          cameras.first, // 이용 가능한 카메라 목록에서 특정 카메라 가져오기
          ResolutionPreset.medium // 해상도 medium으로 지정
      );
      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture; // 카메라 초기화가 완료되었는지 확인
      await _initialization; // Firebase App 초기화 확인

      for(var i=0; ; i++) {

        ref.child('project_bucket').child(tag).set(_state).asStream();
        final path = join( // path 패키지를 사용하여 이미지가 저장될 경로 지정. 플러그인을 사용하여 임시 디렉토리 찾기
          (await getTemporaryDirectory()).path,
          '${DateTime.now()}.png',
        );
        await _controller.takePicture(path); // 사진 촬영을 시도하고 저장되는 경로를 로그로 남김.

        var file = File(path);
        uploadPic(file);
        print(path);

        sleep(const Duration(milliseconds:2000));

        setState(() {_state++;});
      }

    });

    tagUpdate.then((data) {}, onError: (e) {print(e);});

    return Scaffold(
      appBar: AppBar(
        title: Text('Gesture Recognition'),
      ),
      body: Column(
        children: <Widget>[
          FutureBuilder(
              future: downloadPic(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData == false) {
                  return CircularProgressIndicator();
                }
                else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Error: &{snapshot.error}',
                      style: TextStyle(fontSize: 15),
                    ),
                  );
                }
                else {
                  return Image.network(snapshot.data);
                }
              }
          )
        ],
      ),
    );
  }

  uploadPic(File file) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('photo.jpg');
    UploadTask uploadTask = ref.putFile(file);
    uploadTask.whenComplete(() {}).catchError((onError) {print(onError);});
  }

  Future<String> downloadPic() async {
    FirebaseStorage storage = FirebaseStorage.instance;
    return await storage.ref().child('result.jpg').getDownloadURL();
  }
}