import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';


final key = UniqueKey();
class WebViewPage extends StatefulWidget {
  const WebViewPage({Key? key}) : super(key: key);

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewController? _webViewController;

  final Completer<WebViewController> _controllerCompleter = Completer<WebViewController>();

  bool isExit = false;

  openWhatsApp() async {
    String whatsapp = '+55 81 96974-371';
    String message = 'Olá, Pedro! Tudo bem? Tenho uma dúvida sobre a Praso, você poderia me ajudar?';
    String whatsappURlAndroid =
        "whatsapp://send?phone=" + whatsapp + "&text=$message";
    String whatsappURLIos =
        "https://wa.me/$whatsapp?text=${Uri.parse(message)}";
    if (Platform.isIOS) {
      // for iOS phone only
      if (await canLaunch(whatsappURLIos)) {
        await launch(whatsappURLIos, forceSafariVC: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Whatsapp não está instalado.")));
      }
    } else {
      // android , web
      if (await canLaunch(whatsappURlAndroid)) {
        await launch(whatsappURlAndroid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Whatsapp não está instalado")));
      }
    }
  }

  @override
  void initState() {
    WebView.platform = SurfaceAndroidWebView();
    super.initState();
  }

  Widget webView() {
    return WebView(
      initialUrl: 'https://praso.com.br/',
      javascriptMode: JavascriptMode.unrestricted,
      key: key,
      onWebViewCreated: (WebViewController webViewController) {
        _controllerCompleter.future.then((value) => _webViewController = value);
        _controllerCompleter.complete(webViewController);
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (await _webViewController!.canGoBack()) {
          _webViewController!.goBack();
          return Future.value(false);
          } else {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirmar saída?'),
                  content: const Text('Tem certeza que deseja sair?'),
                  actions: [
                    TextButton(onPressed: () {
                      isExit = false;
                      Navigator.pop(context);
                    }, child: const Text('Cancelar')),

                    TextButton(onPressed: () {
                      isExit = true;
                      SystemNavigator.pop();
                    }, child: const Text('Saída')),
                  ],
                );
              },
            );
           return Future.value(isExit);
          }
        },
        child: Scaffold(
          body: webView(),
          floatingActionButton: GestureDetector(
            onTap: () {
              openWhatsApp();
            },
            child: Container(
              height: 70,
              width: 70,
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                  image: DecorationImage(image: NetworkImage('data:image/png;base64,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'))
              ),
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: () async{
                while(await _webViewController!.canGoBack()) {
                  _webViewController!.goBack();
                }
              }, icon: const Icon(Icons.home, color: Colors.blue,size: 30,),),
              const Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Text('Home Page', style: TextStyle(color: Color(0xFF737373)),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

