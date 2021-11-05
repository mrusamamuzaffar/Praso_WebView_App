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

  Widget bottomNavigationBarItems({required String imagePath, required String iconText, required Color color}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
         Image(
          height: 30,
            width: 30,
            image: AssetImage(imagePath)),
         Padding(
          padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
          child: Text(iconText, style: TextStyle(color: color),),
        ),
      ],
    );
  }

  @override
  void initState() {
    prasoNotifyProvider = Provider.of(context,listen: false);
    WebView.platform = SurfaceAndroidWebView();
    super.initState();
  }

  @override
  void dispose() {
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
                //webView
                WebView(
                  initialUrl: 'https://praso.com.br/',
                  javascriptMode: JavascriptMode.unrestricted,
                  key: key,
                  onWebViewCreated: (WebViewController webViewController) {
                    _controllerCompleter.future.then((value) => _webViewController = value);
                    _controllerCompleter.complete(webViewController);
                  },
                  onPageStarted: (url) {
                    prasoNotifyProvider!.url = url;
                  },
                  /*navigationDelegate: (navigation) async {
                    print('......naviation url......${navigation.url}');
                    if(!(navigation.url.contains(prasoNotifyProvider!.url))) {
                      print('downloading start.........!!');
                      final taskId = await FlutterDownloader.enqueue(
                        url: navigation.url,
                        savedDir: '/storage/emulated/0/praso/',
                        showNotification: true, // show download progress in status bar (for Android)
                        openFileFromNotification: true, // click on notification to open downloaded file (for Android)
                      );
                      print('.....task Id......$taskId');
                    }
                    return Future.value(NavigationDecision.navigate);

                  },*/
                  gestureNavigationEnabled: true,
                ),

                //bottom navigation bar
                Positioned(
                  right: 0,
                  bottom: 0,
                  left: 0,
                  child: Card(
                    elevation: 20,
                    child: Container(
                      height: 90,
                      color: Colors.white,
                      child: Selector<PrasoNotifyProvider, String>(
                        selector: (context, prasoNotifyProvider) => prasoNotifyProvider.url,
                        builder: (context, value, child) =>  Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            //home icon
                            GestureDetector(
                              onTap: () async{
                                while(await _webViewController!.canGoBack()) {
                                  _webViewController!.goBack();
                                  prasoNotifyProvider!.homeIcon = Colors.blue;
                                  prasoNotifyProvider!.categoryIcon = Colors.black;
                                  prasoNotifyProvider!.accountIcon = Colors.black;
                                }
                              },
                                child: Selector<PrasoNotifyProvider, Color>(
                                  selector: (context, prasoNotifyProvider) => prasoNotifyProvider.homeIcon,
                                    builder: (context, value, child) => bottomNavigationBarItems(imagePath: 'assets/images/home_icon.jpg', iconText: 'inicio', color: prasoNotifyProvider!.homeIcon))),

                            //category icon
                            GestureDetector(
                              onTap: () {
                                prasoNotifyProvider!.homeIcon = Colors.black;
                                prasoNotifyProvider!.categoryIcon = Colors.blue;
                                prasoNotifyProvider!.accountIcon = Colors.black;
                                // _webViewController!.loadUrl('https://www.google.com/');
                              },
                                child: Selector<PrasoNotifyProvider, Color>(
                                    selector: (context, prasoNotifyProvider) => prasoNotifyProvider.categoryIcon,
                                    builder: (context, value, child) => bottomNavigationBarItems(imagePath: 'assets/images/categories_icon.png', iconText: 'categorias', color: prasoNotifyProvider!.categoryIcon))),

                            //account icon
                            GestureDetector(
                              onTap: () {
                                prasoNotifyProvider!.homeIcon = Colors.black;
                                prasoNotifyProvider!.categoryIcon = Colors.black;
                                prasoNotifyProvider!.accountIcon = Colors.blue;
                                _webViewController!.loadUrl('https://praso.com.br/account/login?return_url=%2Faccount');
                              },
                                child: Selector<PrasoNotifyProvider, Color>(
                                    selector: (context, prasoNotifyProvider) => prasoNotifyProvider.accountIcon,
                                    builder: (context, value, child) => bottomNavigationBarItems(imagePath: 'assets/images/contact_Icon.png', iconText: 'conta', color: prasoNotifyProvider!.accountIcon))),

                            Visibility(
                                visible: prasoNotifyProvider!.url.contains('praso.com.br'),
                                child: GestureDetector(
                                  onTap: ()  {
                                    openWhatsApp();
                                  },
                                    child: bottomNavigationBarItems(imagePath: 'assets/images/whats_app_icon.png', iconText: 'Whats app', color: Colors.black)),
                              ),
                          ],
                        ),
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
  Color _homeIcon = Colors.blue, _categoryIcon = Colors.black, _accountIcon = Colors.black;

  String get url => _url;

  set url(String value) {
    _url = value;
    notifyListeners();
  }

  get accountIcon => _accountIcon;

  set accountIcon(value) {
    _accountIcon = value;
    notifyListeners();
  }

  get categoryIcon => _categoryIcon;

  set categoryIcon(value) {
    _categoryIcon = value;
    notifyListeners();
  }

  Color get homeIcon => _homeIcon;

  set homeIcon(Color value) {
    _homeIcon = value;
    notifyListeners();
  }
}