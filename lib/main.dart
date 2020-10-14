import 'dart:convert';
import 'dart:io';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp();
  runApp(WhichPhotoApp());
}


class WhichPhotoApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhichPhoto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WhichPhotoHomePage(title: 'WhichPhoto'),
    );
  }
}

class WhichPhotoHomePage extends StatefulWidget {
  WhichPhotoHomePage({Key key, this.title}) : super(key: key);


  final String title;

  @override
  _WhichPhotoHomePageState createState() => _WhichPhotoHomePageState();
}

class _WhichPhotoHomePageState extends State<WhichPhotoHomePage> {

  int _state = 0;
  File _image1;
  File _image2;

  String img1Response = "";
  String img2Response = "";

  bool firstBetter = false;

  int percentBetter = 0;

  final picker = ImagePicker();

  final String CLIENT_ID = "N3bGCse4SMQS9yv5MUrWTvBk";
  final String CLIENT_SECRET = "JmjoZmThkhA4JRrxrgxFwTd7L8R0Z9Hg8Mru7PAhn4Ltyai0";

  static const MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    testDevices: null,
    keywords: <String>['photo', 'filter', 'film', 'Instagram'],
    childDirected: true,
    nonPersonalizedAds: true,
  );

  Future getImage1() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image1 = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future getImage2() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image2 = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _buttonPressed() async {

    if (_image1 != null && _image2 != null) {
      if (_state == 0) {
        setState(() {
          _state = 1;
        });


        var postUri = Uri.parse("https://api.everypixel.com/v1/quality_ugc");
        var request = new http.MultipartRequest("POST", postUri);

        var authn = 'Basic ' +
            base64Encode(utf8.encode('$CLIENT_ID:$CLIENT_SECRET'));

        Map<String, String> headers = { 'Authorization': authn};

        request.headers.addAll(headers);
        request.files.add(
            await http.MultipartFile.fromPath('data', _image1.path));

        print(request.files);

        request.send().then((response) async {
          print(response.statusCode);


          response.stream.transform(utf8.decoder).listen((value) {
            img1Response = value;
            print(value);
          });

          var postUri = Uri.parse("https://api.everypixel.com/v1/quality_ugc");
          var request = new http.MultipartRequest("POST", postUri);

          var authn = 'Basic ' +
              base64Encode(utf8.encode('$CLIENT_ID:$CLIENT_SECRET'));

          Map<String, String> headers = { 'Authorization': authn};

          request.headers.addAll(headers);
          request.files.add(
              await http.MultipartFile.fromPath('data', _image2.path));

          print(request.files);

          request.send().then((response) {
            print(response.statusCode);

            response.stream.transform(utf8.decoder).listen((value) {
              img2Response = value;
              print(value);

              firstBetter =
                  double.parse(img1Response.split('score":')[1].split("}")[0]) >
                      double.parse(
                          img2Response.split('score":')[1].split("}")[0]);

              percentBetter =
                  (double.parse(
                      img1Response.split('score":')[1].split("}")[0]) *
                      100
                      - double.parse(
                          img2Response.split('score":')[1].split("}")[0]) * 100)
                      .abs()
                      .floor();

              setState(() {
                _state = 2;
                _interstitialAd.show();
              });
            });
          });
        });
      }
      else if (_state == 2) {
        setState(() {
          _image1 = null;
          _image2 = null;
          img1Response = "";
          img2Response = "";
          _state = 0;
        });
      }
    }
  }

  var spinkit = SpinKitFadingCircle(
    color: Colors.white,
    size: 20.0,
  );

  InterstitialAd createInterstitialAd() {
    return InterstitialAd(
      adUnitId: "ca-app-pub-4663509279582633/8983594105",
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        print("InterstitialAd event $event");
      },
    );
  }

  InterstitialAd _interstitialAd;

  @override
  void initState() {
    super.initState();
    FirebaseAdMob.instance.initialize(appId: "ca-app-pub-4663509279582633~6551520814");
    _interstitialAd = createInterstitialAd()
      ..load();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(

      body: SafeArea(
        child: Center(

        child: _state == 2 ? Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              SizedBox(height: 30,),

            Text(
            firstBetter ? "1st Photo" : "2nd Photo",
                textAlign: TextAlign.center, style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 40,

            )),

            SizedBox(height: 10,),

              Container(
                  color: Colors.black12,
                  width: MediaQuery.of(context).size.height / 3,
                  height:  MediaQuery.of(context).size.height / 3,
                  child:
                  Image.file(firstBetter ? _image1 : _image2, height: MediaQuery.of(context).size.height / 3, width: MediaQuery.of(context).size.height / 3,)
              ),

            SizedBox(height: 10,),

            Container(
              width: MediaQuery.of(context).size.height / 3,
              child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.favorite, color: Color(0xffFF8B8B),size: 40,),
              ],
            )),

            SizedBox(height: 50,),

            Text(
                "This photo is " + percentBetter.toString() +  "% more aesthetic than the other photo.",
                textAlign: TextAlign.center,
                style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xff707070)
            )),


            SizedBox(height: 20,),


            Text(
                "According to AI trained on \n 347,000 Instagram posts.",
                textAlign: TextAlign.center,
                style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 20,
                color: Color(0xff707070)
            )),

            ]
        )) :
        Column(

          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 30,),
            Text(
              'Tap to choose photos to compare.', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18
            ),
            ),
            SizedBox(height: 30,),
            GestureDetector(
              onTap: () {
                getImage1();
              },
              child: Container(
                color: Colors.black12,
                width: MediaQuery.of(context).size.height / 3,
                height:  MediaQuery.of(context).size.height / 3,
                child: _image1 == null ?
                Icon(Icons.add_circle_outline, color: Colors.grey, size: 80,) :
                    Image.file(_image1, height: MediaQuery.of(context).size.height / 3, width: MediaQuery.of(context).size.height / 3,)
              ),
            ),

            SizedBox(height: 30,),

            GestureDetector(
              onTap: () {
                getImage2();
              },
              child: Container(
                  color: Colors.black12,
                  width: MediaQuery.of(context).size.height / 3,
                  height:  MediaQuery.of(context).size.height / 3,
                  child: _image2 == null ?
                  Icon(Icons.add_circle_outline, color: Colors.grey, size: 80,) :
                  Image.file(_image2, height: MediaQuery.of(context).size.height / 3, width: MediaQuery.of(context).size.height / 3,)
              ),
            ),
          ],
        ),
      ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _buttonPressed,
        tooltip: 'Compare Photos',
        icon: _state == 1 ? spinkit : Icon(_state == 2 ? Icons.arrow_back_ios : Icons.compare),
        label: Text(_state == 1 ? " LOADING " : _state == 2 ? "USE AGAIN"  : "COMPARE", style: TextStyle(fontWeight: FontWeight.w400),)
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
