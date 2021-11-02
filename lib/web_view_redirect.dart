import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  String? currentWebUrl;
  bool whatsAppVisibility = true;
  Timer? timer;
  PrasoNotifyProvider? prasoNotifyProvider;

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

  Widget bottomNavigationBarItems({required String imagePath, required String iconText}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
         Image(
          height: 30,
            width: 30,
            image: AssetImage(imagePath)),
         Padding(
          padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
          child: Text(iconText, style: const TextStyle(color: Color(0xFF737373)),),
        ),
      ],
    );
  }

  @override
  void initState() {
    prasoNotifyProvider = Provider.of(context,listen: false);
    WebView.platform = SurfaceAndroidWebView();
    timer = Timer.periodic(const Duration(seconds: 2), (timer) async{
      currentWebUrl = await _webViewController!.currentUrl();
      print('url.........$currentWebUrl');
      prasoNotifyProvider!.url = currentWebUrl!;
    });
    super.initState();
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    print('build invoked');
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
          body: Stack(
              children: [
                WebView(
                  initialUrl: 'https://praso.com.br/',
                  javascriptMode: JavascriptMode.unrestricted,
                  key: key,
                  onWebViewCreated: (WebViewController webViewController) {
                    _controllerCompleter.future.then((value) => _webViewController = value);
                    _controllerCompleter.complete(webViewController);
                    webViewController.currentUrl().then((value) => currentWebUrl = value!);
                  },
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  left: 0,
                  child: Card(
                    elevation: 20,
                    child: Container(
                      height: 90,
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () async{
                              while(await _webViewController!.canGoBack()) {
                                _webViewController!.goBack();
                              }
                            },
                              child: bottomNavigationBarItems(imagePath: 'assets/images/home_icon.jpg', iconText: 'inicio')),

                          GestureDetector(
                            onTap: () {

                            },
                              child: bottomNavigationBarItems(imagePath: 'assets/images/categories_icon.png', iconText: 'categorias')),

                          GestureDetector(
                            onTap: () {
                              _webViewController!.loadUrl('https://praso.com.br/account/login?return_url=%2Faccount');
                            },
                              child: bottomNavigationBarItems(imagePath: 'assets/images/contact_Icon.png', iconText: 'conta')),

                          Selector<PrasoNotifyProvider, String>(
                            selector: (context, prasoNotifyProvider) => prasoNotifyProvider.url,
                            builder: (context, value, child) {
                              print('builderrrrrr');
                              return Visibility(
                              visible: currentWebUrl != null ? currentWebUrl!.contains('praso.com.br') : true,
                              child: GestureDetector(
                                onTap: ()  {
                                  openWhatsApp();
                                },
                                  child: bottomNavigationBarItems(imagePath: 'assets/images/whats_app_icon.png', iconText: 'Whats app')),
                            );
                            },
                          ),
                        ],
                      )
                    ),
                  ),)
              ]
          ),
        ),
      ),
    );
  }
}

class PrasoNotifyProvider with ChangeNotifier {
  String _url = '';

  String get url => _url;

  set url(String value) {
    _url = value;
    notifyListeners();
  }
}

