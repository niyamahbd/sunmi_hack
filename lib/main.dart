import 'package:flutter/material.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunmi Print',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late final WebViewController _webController;
  // *** আপনার website URL এখানে দিন ***
  final String _websiteUrl = 'https://yourwebsite.com';

  final _shopController =
      TextEditingController(text: 'আমার দোকান');
  final _textController =
      TextEditingController(text: 'Item: পণ্যের নাম\nমূল্য: ৳ ৫০০');
  final _qrController =
      TextEditingController(text: 'https://yourwebsite.com');
  bool _printing = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initWebView();
    _bindPrinter();
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SunmiPrint',
        onMessageReceived: (msg) => _printFromWeb(msg.message),
      )
      ..loadRequest(Uri.parse(_websiteUrl));
  }

  Future<void> _bindPrinter() async {
    await SunmiPrinter.bindingPrinter();
  }

  Future<void> _printFromWeb(String message) async {
    try {
      final text = _extract(message, 'text');
      final qr = _extract(message, 'qr');
      final shop = _extract(message, 'shop');
      await _doPrint(
        shopName: shop.isEmpty ? 'My Shop' : shop,
        body: text,
        qrData: qr,
      );
    } catch (e) {
      _setStatus('Web print error: $e');
    }
  }

  String _extract(String json, String key) {
    final reg = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    return reg.firstMatch(json)?.group(1) ?? '';
  }

  Future<void> _doPrint({
    required String shopName,
    required String body,
    required String qrData,
  }) async {
    setState(() {
      _printing = true;
      _status = 'Printing...';
    });
    try {
      await SunmiPrinter.startTransactionPrint(true);

      // দোকানের নাম — center, bold, বড়
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText(
        shopName,
        style: SunmiTextStyle(bold: true, fontSize: 28),
      );
      await SunmiPrinter.line();

      // body text — left align
      await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      for (final line in body.split('\n')) {
        await SunmiPrinter.printText(line);
      }
      await SunmiPrinter.line();

      // QR Code
      if (qrData.isNotEmpty) {
        await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
        await SunmiPrinter.printQRCode(qrData, size: 8);
        await SunmiPrinter.printText(
          qrData,
          style: SunmiTextStyle(fontSize: 18),
        );
        await SunmiPrinter.line();
      }

      // Footer
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('ধন্যবাদ আপনার পরিদর্শনের জন্য');
      await SunmiPrinter.lineWrap(3);
      await SunmiPrinter.submitTransactionPrint();

      _setStatus('✅ Print সফল!');
    } catch (e) {
      _setStatus('❌ Error: $e');
    } finally {
      setState(() => _printing = false);
    }
  }

  void _setStatus(String msg) => setState(() => _status = msg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunmi Print'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.web), text: 'Website'),
            Tab(icon: Icon(Icons.print), text: 'Manual Print'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: WebView
          Column(
            children: [
              Expanded(child: WebViewWidget(controller: _webController)),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                  onPressed: () => _webController.reload(),
                ),
              ),
            ],
          ),

          // TAB 2: Manual Print
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field('🏪 দোকানের নাম', _shopController),
                _field('📝 Text / বিবরণ', _textController, lines: 4),
                _field('🔗 QR Code (URL বা text)', _qrController),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: _printing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.print),
                  label: Text(_printing ? 'Printing...' : 'Print করুন'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _printing
                      ? null
                      : () => _doPrint(
                            shopName: _shopController.text,
                            body: _textController.text,
                            qrData: _qrController.text,
                          ),
                ),
                if (_status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _status.startsWith('✅')
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _status.startsWith('✅')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Text(_status, textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(height: 24),
                const _TipCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            maxLines: lines,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shopController.dispose();
    _textController.dispose();
    _qrController.dispose();
    super.dispose();
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Website থেকে Print করতে:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('আপনার website-এর print button-এ এই JS যোগ করুন:'),
          SizedBox(height: 6),
          SelectableText(
            'SunmiPrint.postMessage(JSON.stringify({\n'
            '  shop: "আমার দোকান",\n'
            '  text: "Item: পণ্য\\nমূল্য: ৳৫০০",\n'
            '  qr: "https://yourwebsite.com"\n'
            '}));',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }
}
