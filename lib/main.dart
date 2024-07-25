import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qr code Genrator',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}



class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _textController = TextEditingController();
  String _qrData = "";
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('qr_history') ?? [];
    });
  }

  Future<void> _saveToHistory(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _history.add(data);
    await prefs.setStringList('qr_history', _history);
  }

  void _generateQRCode() {
    setState(() {
      _qrData = _textController.text;
      _saveToHistory(_qrData);
    });
  }

  void _shareQRCode() {
    if (_qrData.isNotEmpty) {
      Share.share(_qrData);
    }
  }

  void _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRViewExample()),
    );

    if (result != null && result is String) {
      setState(() {
        _saveToHistory(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Generator & Scanner'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen(history: _history)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter text to generate QR code',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _generateQRCode,
              child: Text('Generate QR Code'),
            ),
            SizedBox(height: 16.0),
            if (_qrData.isNotEmpty)
              Column(
                children: [
                  QrImageView(
                    data: _qrData,
                    size: 200.0,
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _shareQRCode,
                    child: Text('Share QR Code'),
                  ),
                ],
              ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _scanQRCode,
              child: Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final List<String> history;

  HistoryScreen({required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan History'),
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(history[index]),
          );
        },
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text('Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                  : Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        Navigator.pop(context, result!.code);
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
