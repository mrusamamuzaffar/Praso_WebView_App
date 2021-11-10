import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
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
  ReceivePort _port = ReceivePort();
  Timer? timer;
  PrasoNotifyProvider? prasoNotifyProvider;

  final Completer<WebViewController> _controllerCompleter =
      Completer<WebViewController>();

  bool isExit = false;

  openWhatsApp() async {
    String whatsapp = '+55 81 96974-371';
    String message =
        'Olá, Pedro! Tudo bem? Tenho uma dúvida sobre a Praso, você poderia me ajudar?';
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
            const SnackBar(content: Text("WhatsApp não está instalado.")));
      }
    } else {
      // android , web
      if (await canLaunch(whatsappURlAndroid)) {
        await launch(whatsappURlAndroid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("WhatsApp não está instalado")));
      }
    }
  }

  Widget bottomNavigationBarItems(
      {required String imagePath,
      required String iconText,
      required Color color}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image(height: 30, width: 30, image: AssetImage(imagePath)),
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
          child: Text(
            iconText,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }

  void downloadFile({required String url}) async{

    final taskId = await FlutterDownloader.enqueue(
      saveInPublicStorage: true,
      fileName: 'prasoInvoice_${DateTime.now().toString().replaceAll(' ', '').replaceAll(':', '').replaceAll('-', '').replaceAll('.', '')}.pdf',
      url: url,
      savedDir: '/storage/emulated/0/',
      showNotification: true, // show download progress in status bar (for Android)
      openFileFromNotification: true, // click on notification to open downloaded file (for Android)
    );
    final tasks = await FlutterDownloader.loadTasks();

  }

  @override
  void initState() {
    super.initState();
    prasoNotifyProvider = Provider.of(context, listen: false);
    WebView.platform = SurfaceAndroidWebView();

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      setState((){

      });
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
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
                    TextButton(
                        onPressed: () {
                          isExit = false;
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () {
                          isExit = true;
                          SystemNavigator.pop();
                        },
                        child: const Text('Saída')),
                  ],
                );
              },
            );
            return Future.value(isExit);
          }
        },
        child: Scaffold(
          body: Stack(children: [
            //webView
            WebView(
              initialUrl: 'https://praso.com.br/',
              javascriptMode: JavascriptMode.unrestricted,
              key: key,
              onWebViewCreated: (WebViewController webViewController) {
                _controllerCompleter.future
                    .then((value) => _webViewController = value);
                _controllerCompleter.complete(webViewController);
              },
              onPageStarted: (url) {
                prasoNotifyProvider!.url = url;
              },
              navigationDelegate: (navigation) async {
                String pdfCheck = navigation.url.substring((navigation.url.length-3), navigation.url.length);
                if(navigation.url.contains('https://api.pagar.me') && pdfCheck.contains('pdf')) {
                  downloadFile(url: navigation.url);
                  return Future.value(NavigationDecision.prevent);
                }
                return Future.value(NavigationDecision.navigate);
                },
              gestureNavigationEnabled: true,
            ),

            //bottom navigation bar
            Selector<PrasoNotifyProvider, String>(
              selector: (context, prasoNotifyProvider) => prasoNotifyProvider.url,
              builder: (context, value, child) => Visibility(
                visible: prasoNotifyProvider!.url.contains('https://praso.com.br/'),
                child: Positioned(
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
                              //home icon
                              GestureDetector(
                                  onTap: () async {
                                    while (await _webViewController!.canGoBack()) {
                                      _webViewController!.goBack();
                                      prasoNotifyProvider!.homeIcon = Colors.blue;
                                      prasoNotifyProvider!.categoryIcon =
                                          Colors.black;
                                      prasoNotifyProvider!.accountIcon =
                                          Colors.black;
                                    }
                                  },
                                  child: Selector<PrasoNotifyProvider, Color>(
                                      selector: (context, prasoNotifyProvider) =>
                                          prasoNotifyProvider.homeIcon,
                                      builder: (context, value, child) =>
                                          bottomNavigationBarItems(
                                              imagePath: prasoNotifyProvider!.url.length == 'https://praso.com.br/'.length ? 'assets/images/home_select.png':'assets/images/home_icon.png',
                                              iconText: 'início',
                                              color: prasoNotifyProvider!.homeIcon))),

                              //category icon
                              GestureDetector(
                                  onTap: () {
                                    prasoNotifyProvider!.homeIcon = Colors.black;
                                    prasoNotifyProvider!.categoryIcon = Colors.blue;
                                    prasoNotifyProvider!.accountIcon = Colors.black;
                                    _webViewController!.loadUrl('https://praso.com.br/collections/acucares');
                                  },
                                  child: Selector<PrasoNotifyProvider, Color>(
                                      selector: (context, prasoNotifyProvider) =>
                                          prasoNotifyProvider.categoryIcon,
                                      builder: (context, value, child) =>
                                          bottomNavigationBarItems(imagePath: prasoNotifyProvider!.url.length == 'https://praso.com.br/collections/acucares'.length ? 'assets/images/catagories_select.png': 'assets/images/categories_icon.png',
                                              iconText: 'categorias',
                                              color: prasoNotifyProvider!
                                                  .categoryIcon))),

                              //account icon
                              GestureDetector(
                                  onTap: () {
                                    prasoNotifyProvider!.homeIcon = Colors.black;
                                    prasoNotifyProvider!.categoryIcon =
                                        Colors.black;
                                    prasoNotifyProvider!.accountIcon = Colors.blue;
                                    _webViewController!.loadUrl('https://praso.com.br/account/login?return_url=%2Faccount');
                                  },
                                  child: Selector<PrasoNotifyProvider, Color>(
                                      selector: (context, prasoNotifyProvider) =>
                                          prasoNotifyProvider.accountIcon,
                                      builder: (context, value, child) =>
                                          bottomNavigationBarItems(
                                              imagePath: prasoNotifyProvider!.url.length == 'https://praso.com.br/account/login?return_url=%2Faccount'.length ? 'assets/images/contact_select.png' :'assets/images/contact_icon.png',
                                              iconText: 'conta',
                                              color: prasoNotifyProvider!
                                                  .accountIcon))),
                              GestureDetector(
                                  onTap: () {
                                    openWhatsApp();
                                  },
                                  child: bottomNavigationBarItems(
                                      imagePath: 'assets/images/whats_app_icon.png',
                                      iconText: 'WhatsApp',
                                      color: Colors.black)),
                            ],
                          ),),
                  ),
                ),
              ),
            )
          ]),
          bottomNavigationBar: Selector<PrasoNotifyProvider, String>(
            selector: (context, prasoNotifyProvider) => prasoNotifyProvider.url,
            builder: (context, value, child) => Visibility(
              visible: !(prasoNotifyProvider!.url.contains('https://praso.com.br/')),
              child: Card(
                elevation: 20,
                child: Container(
                    height: 90,
                    color: Colors.white,
                    child: Selector<PrasoNotifyProvider, String>(
                      selector: (context, prasoNotifyProvider) => prasoNotifyProvider.url,
                      builder: (context, value, child) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          //home icon
                          GestureDetector(
                              onTap: () async {
                                while (await _webViewController!.canGoBack()) {
                                  _webViewController!.goBack();
                                  prasoNotifyProvider!.homeIcon = Colors.blue;
                                  prasoNotifyProvider!.categoryIcon =
                                      Colors.black;
                                  prasoNotifyProvider!.accountIcon =
                                      Colors.black;
                                }
                              },
                              child: Selector<PrasoNotifyProvider, Color>(
                                  selector: (context, prasoNotifyProvider) =>
                                  prasoNotifyProvider.homeIcon,
                                  builder: (context, value, child) =>
                                      bottomNavigationBarItems(
                                          imagePath: prasoNotifyProvider!.url.length == 'https://praso.com.br/'.length ? 'assets/images/home_select.png':'assets/images/home_icon.png',
                                          iconText: 'início',
                                          color: prasoNotifyProvider!.homeIcon))),

                          //category icon
                          GestureDetector(
                              onTap: () {
                                prasoNotifyProvider!.homeIcon = Colors.black;
                                prasoNotifyProvider!.categoryIcon = Colors.blue;
                                prasoNotifyProvider!.accountIcon = Colors.black;
                                _webViewController!.loadUrl('https://praso.com.br/collections/acucares');
                              },
                              child: Selector<PrasoNotifyProvider, Color>(
                                  selector: (context, prasoNotifyProvider) =>
                                  prasoNotifyProvider.categoryIcon,
                                  builder: (context, value, child) =>
                                      bottomNavigationBarItems(imagePath: prasoNotifyProvider!.url.length == 'https://praso.com.br/collections/acucares'.length ? 'assets/images/catagories_select.png': 'assets/images/categories_icon.png',
                                          iconText: 'categorias',
                                          color: prasoNotifyProvider!
                                              .categoryIcon))),

                          //account icon
                          GestureDetector(
                              onTap: () {
                                prasoNotifyProvider!.homeIcon = Colors.black;
                                prasoNotifyProvider!.categoryIcon =
                                    Colors.black;
                                prasoNotifyProvider!.accountIcon = Colors.blue;
                                _webViewController!.loadUrl('https://praso.com.br/account/login?return_url=%2Faccount');
                              },
                              child: Selector<PrasoNotifyProvider, Color>(
                                  selector: (context, prasoNotifyProvider) =>
                                  prasoNotifyProvider.accountIcon,
                                  builder: (context, value, child) =>
                                      bottomNavigationBarItems(
                                          imagePath: prasoNotifyProvider!.url.length == 'https://praso.com.br/account/login?return_url=%2Faccount'.length ? 'assets/images/contact_select.png' :'assets/images/contact_icon.png',
                                          iconText: 'conta',
                                          color: prasoNotifyProvider!
                                              .accountIcon))),
                          GestureDetector(
                              onTap: () {
                                openWhatsApp();
                              },
                              child: bottomNavigationBarItems(
                                  imagePath: 'assets/images/whats_app_icon.png',
                                  iconText: 'WhatsApp',
                                  color: Colors.black)),
                        ],
                      ),
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrasoNotifyProvider with ChangeNotifier {
  String _url = '';
  Color _homeIcon = Colors.blue,
      _categoryIcon = Colors.black,
      _accountIcon = Colors.black;

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
