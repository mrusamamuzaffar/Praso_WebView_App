import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:praso/home_screen.dart';
import 'package:praso/web_view_redirect.dart';
import 'package:provider/provider.dart';

Future<void> messageHandler(RemoteMessage message) async {

}

ConnectivityResult? connectivityResult;
ConnectionState? connectionState;
double screenWidth = 0.0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(messageHandler);

  runApp( MultiProvider(
    providers: [
      ChangeNotifierProvider<PrasoNotifyProvider>(create: (context) => PrasoNotifyProvider(),)
    ],
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
      title: 'Praso App',
    ),
  ));
}
 class MyApp extends StatefulWidget {
   const MyApp({Key? key}) : super(key: key);

   @override
   _MyAppState createState() => _MyAppState();
 }

 class _MyAppState extends State<MyApp> {
   late FirebaseMessaging messaging;

  Future<void> initializeMyFirebaseApp() async {
    await Firebase.initializeApp();
    print('......................................praso firebase initialized');
  }

  @override
  void initState() {
    messaging = FirebaseMessaging.instance;
    super.initState();
  }

   @override
   Widget build(BuildContext context) {

     SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
         statusBarColor: Color(0xFF487CEA),
     ));
     screenWidth = MediaQuery.of(context).size.width;

     Future.delayed(const Duration(seconds: 1), () async {
       connectivityResult = await Connectivity().checkConnectivity();
         switch (connectivityResult!) {
           case ConnectivityResult.mobile:
           case ConnectivityResult.wifi:
             {

               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WebViewPage(),));
               break;
             }
           case ConnectivityResult.none:
             {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const ErrorScreen(),));
               break;
             }
           case ConnectivityResult.ethernet:
             break;
       }
     });
     return Scaffold(
       backgroundColor: const Color(0xFF487CEA),
       body: Center(
         child: Container(
           height: 200,
           width: screenWidth * 0.80,
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(25),
             image: const DecorationImage(
               image: AssetImage('assets/images/praso_splash_icon.png'),
             )
           ),
         ),
       ),
     );
   }
 }

