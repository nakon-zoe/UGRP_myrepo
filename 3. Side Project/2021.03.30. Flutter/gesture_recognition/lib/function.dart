import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';



class TakePictureScreen extends StatefulWidget {

  TakePictureScreen({this.app, this.camera});
  final FirebaseApp app;
  final CameraDescription camera;

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}



class _TakePictureScreenState extends State<TakePictureScreen> {

  // Firebase 인스턴스 및 태그 설정
  final referenceDatabase = FirebaseDatabase.instance;
  final tag = 'photo';

  // 카메라 컨트롤러 설정
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void dispose() {
    _controller.dispose(); // 위젯의 생명주기 종료 시 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    Future<void> takepictureLoop = new Future( () async {

      // Firebase 경로 설정
      final ref = referenceDatabase.reference();

      // 카메라 설정
      final cameras = await availableCameras(); // 디바이스에서 이용 가능한 카메라 목록 가져오기
      _controller = CameraController( // 카메라의 현재 출력물을 보여주기 위해 CameraController 생성
          cameras.first, // 이용 가능한 카메라 목록에서 특정 카메라 가져오기
          ResolutionPreset.medium // 해상도 medium으로 지정
      );
      _initializeControllerFuture = _controller.initialize(); // 카메라 초기화
      await _initializeControllerFuture; // 카메라 초기화가 완료되었는지 확인

      for (var i=0; i<10; i++) {
        ref.child('project_bucket').child(tag).set(i).asStream();
        final path = join( // path 패키지를 사용하여 이미지가 저장될 경로 지정. 플러그인을 사용하여 임시 디렉토리 찾기
          (await getTemporaryDirectory()).path,
          '${DateTime.now()}.png',
        );
        await _controller.takePicture(path); // 사진 촬영을 시도하고 저장되는 경로를 로그로 남김.
        //var file = File(path);
        //storage.ref().child('photo.jpg').putFile(file);
        sleep(const Duration(seconds: 1));
      }
    });

    takepictureLoop.then((data) {}, onError: (e) {print(e);});

    return Scaffold(
      appBar: AppBar(
        title: Text('Gesture Recognition'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget> [
            Text(
              "tag를 업데이트합니다.",
              style: Theme.of(context).textTheme.headline4,
            )
          ],
        ),
      ),
    );
  }
}







// 사용자가 촬영한 사진을 보여주는 위젯
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // 이미지는 디바이스에 파일로 저장됩니다. 이미지를 보여주기 위해 주어진 경로로 'Image.file'을 생성하세요.
      body: Image.file(File(imagePath)),
    );
  }
}