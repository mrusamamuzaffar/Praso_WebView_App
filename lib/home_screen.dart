import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:praso/main.dart';
import 'package:praso/web_view_redirect.dart';

class ErrorScreen extends StatefulWidget {
  const ErrorScreen({Key? key}) : super(key: key);

  @override
  _ErrorScreenState createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  double height = 0.0, width = 0.0;
  bool visibility = false;

  void _showDialog(context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Sem conexão com a Internet'),
              content: const Text('Você está offline, verifique sua conexão com a Internet.'),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'))
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Visibility(
              visible: visibility,
              maintainAnimation: true,
              maintainState: true,
              maintainSize: true,
              child: const CircularProgressIndicator()),
          Image(
            image: const AssetImage(
              'assets/images/no_internet_connection.png',
            ),
            height: width * 0.8,
            width: width * 0.8,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Você está offline',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'Você está desconectado da Internet, verifique sua conexão com a Internet e tente novamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF5F6368,)),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async{
              setState(() {
                visibility = true;
              });
              connectivityResult = await Connectivity().checkConnectivity();
              setState(() {
                visibility = false;
              });
              switch (connectivityResult!) {
                case ConnectivityResult.mobile:
                case ConnectivityResult.wifi:
                  {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WebViewPage(),
                        ));
                    break;
                  }
                case ConnectivityResult.none:
                  {
                    setState(() {
                      visibility = false;
                    });
                    _showDialog(context);
                    break;
                  }
                case ConnectivityResult.ethernet:
                  // TODO: Handle this case.
                  break;
              }
            },
            child: Container(
              height: 50,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(15)
              ),
              alignment: Alignment.center,
              child: const Text('recarregar', style: TextStyle(color: Colors.white, fontSize: 18,),),
            ),
          ),
        ],
      ),
    );
  }
}
