import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:praso/home_screen.dart';
import 'package:praso/web_view_redirect.dart';
ConnectivityResult? connectivityResult;
ConnectionState? connectionState;
void main() {
  runApp( const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
    title: 'Praso App',
  ));
}
 class MyApp extends StatefulWidget {
   const MyApp({Key? key}) : super(key: key);

   @override
   _MyAppState createState() => _MyAppState();
 }

 class _MyAppState extends State<MyApp> {

   @override
   Widget build(BuildContext context) {
     Future.delayed(const Duration(seconds: 1), () async{
       connectivityResult = await Connectivity().checkConnectivity();
         switch (connectivityResult!) {
           case ConnectivityResult.mobile:
           case ConnectivityResult.wifi:
             {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (context) => const WebViewPage(),));
               break;
             }
           case ConnectivityResult.none:
             {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (context) => const ErrorScreen(),));
               break;
             }
           case ConnectivityResult.ethernet:
             break;
       }
     });
     return Scaffold(
       body: Center(
         child: Container(
           height: 160,
           width: 160,
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(25),
             image: const DecorationImage(
               image: AssetImage('assets/images/parso_icon.jpg'),
             )
           ),
         ),
       ),
     );
   }
 }

