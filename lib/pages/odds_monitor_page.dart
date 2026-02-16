import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonitorItem {
  String id;
  String name;
  String selector;
  String url;
  String currentValue;
  String previousValue;
  DateTime lastUpdated;

  MonitorItem({
    required this.id,
    required this.name,
    required this.selector,
    required this.url,
    this.currentValue = '...',
    this.previousValue = '...',
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'selector': selector,
    'url': url,
    'currentValue': currentValue,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory MonitorItem.fromJson(Map<String, dynamic> json) => MonitorItem(
    id: json['id'],
    name: json['name'],
    selector: json['selector'],
    url: json['url'],
    currentValue: json['currentValue'] ?? '...',
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );
}

class OddsMonitorPage extends StatefulWidget {
  const OddsMonitorPage({super.key});

  @override
  State<OddsMonitorPage> createState() => _OddsMonitorPageState();
}

class _OddsMonitorPageState extends State<OddsMonitorPage> {
  late final WebViewController _controller;
  final List<MonitorItem> _monitoredItems = [];
  final TextEditingController _urlController = TextEditingController();

  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isMonitorMode = false;
  Timer? _monitorTimer;
  String currentUrl = 'https://m.bantubet.co.ao';

  @override
  void initState() {
    super.initState();
    _urlController.text = currentUrl;
    _initializeController();
    _loadMonitors();
    _startMonitoring();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..addJavaScriptChannel(
        'FlutterMonitor',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            _showAddMonitorDialog(
              selector: data['selector'],
              text: data['text'],
            );
          } catch (e) {
            debugPrint('JS Channel Error: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _urlController.text = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              currentUrl = url;
            });
            if (_isMonitorMode) _injectClickListener();
          },
        ),
      )
      ..loadRequest(Uri.parse(currentUrl));
  }

  Future<void> _loadMonitors() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('monitored_items') ?? [];
    setState(() {
      _monitoredItems.addAll(
        data.map((e) => MonitorItem.fromJson(jsonDecode(e))),
      );
    });
  }

  Future<void> _saveMonitors() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _monitoredItems.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('monitored_items', data);
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_monitoredItems.isEmpty || _currentIndex != 1) return;

      for (var item in _monitoredItems) {
        try {
          final result = await _controller.runJavaScriptReturningResult(
            "document.querySelector('${item.selector}').innerText",
          );

          String cleanResult = result.toString().replaceAll('"', '').trim();
          if (cleanResult != 'null' &&
              cleanResult.isNotEmpty &&
              cleanResult != item.currentValue) {
            setState(() {
              item.previousValue = item.currentValue;
              item.currentValue = cleanResult;
              item.lastUpdated = DateTime.now();
            });
          }
        } catch (_) {}
      }
    });
  }

  void _navigate() {
    String url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';
    _controller.loadRequest(Uri.parse(url));
    FocusScope.of(context).unfocus();
  }

  void _toggleMonitorMode() {
    setState(() => _isMonitorMode = !_isMonitorMode);
    if (_isMonitorMode) {
      _injectClickListener();
    } else {
      _removeClickListener();
    }
  }

  void _injectClickListener() {
    _controller.runJavaScript('''
      (function() {
        window.__flutterClickHandler = function(e) {
          e.preventDefault();
          e.stopPropagation();
          var el = e.target;
          var getSelector = function(el) {
            if (el.id) return '#' + el.id;
            var path = el.tagName.toLowerCase();
            if (el.className) path += '.' + el.className.trim().split(/\\s+/).join('.');
            return path;
          };
          FlutterMonitor.postMessage(JSON.stringify({
            selector: getSelector(el),
            text: el.innerText.substring(0, 30)
          }));
        };
        document.addEventListener('click', window.__flutterClickHandler, true);
        document.body.style.border = '4px solid #4CAF50';
      })();
    ''');
  }

  void _removeClickListener() {
    _controller.runJavaScript('''
      document.removeEventListener('click', window.__flutterClickHandler, true);
      document.body.style.border = 'none';
    ''');
  }

  void _showAddMonitorDialog({String? selector, String? text}) {
    final nameController = TextEditingController();
    final selController = TextEditingController(text: selector);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Novo Monitor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text != null)
              Text(
                "Valor capturado: $text",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nome"),
            ),
            TextField(
              controller: selController,
              decoration: const InputDecoration(labelText: "Seletor CSS"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Sair"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _monitoredItems.add(
                    MonitorItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      selector: selController.text,
                      url: currentUrl,
                      lastUpdated: DateTime.now(),
                    ),
                  );
                  _isMonitorMode = false;
                  _removeClickListener();
                });
                _saveMonitors();
                Navigator.pop(context);
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          final exit = await _showExitDialog();
          if (exit) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: "URL",
                prefixIcon: Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _navigate(),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.ads_click,
                color: _isMonitorMode ? Colors.green : Colors.grey,
              ),
              onPressed: _toggleMonitorMode,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  WebViewWidget(controller: _controller),
                  _buildDashboard(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.web), label: "Browser"),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights),
              label: "Dashboard",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_monitoredItems.isEmpty) {
      return const Center(child: Text("Nenhum item sendo monitorado."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _monitoredItems.length,
      itemBuilder: (context, index) {
        final item = _monitoredItems[index];
        final isUp = item.currentValue.compareTo(item.previousValue) > 0;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Atualizado: ${item.lastUpdated.hour}:${item.lastUpdated.minute}",
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.currentValue,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Icon(
                  isUp ? Icons.trending_up : Icons.trending_flat,
                  size: 16,
                  color: isUp ? Colors.green : Colors.grey,
                ),
              ],
            ),
            onLongPress: () {
              setState(() => _monitoredItems.removeAt(index));
              _saveMonitors();
            },
          ),
        );
      },
    );
  }

  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Sair"),
            content: const Text("Deseja fechar o monitor?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Não"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Sim"),
              ),
            ],
          ),
        ) ??
        false;
  }
}
