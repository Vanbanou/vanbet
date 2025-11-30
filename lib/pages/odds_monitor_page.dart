import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MonitorItem {
  String id;
  String name;
  String selector;
  String url;
  String currentValue;
  DateTime lastUpdated;

  MonitorItem({
    required this.id,
    required this.name,
    required this.selector,
    required this.url,
    this.currentValue = '...',
    required this.lastUpdated,
  });
}

class OddsMonitorPage extends StatefulWidget {
  const OddsMonitorPage({super.key});

  @override
  _OddsMonitorPageState createState() => _OddsMonitorPageState();
}

class _OddsMonitorPageState extends State<OddsMonitorPage> {
  late final WebViewController _controller;
  final List<MonitorItem> _monitoredItems = [];
  final TextEditingController _urlController = TextEditingController();

  int _currentIndex = 0; // 0: Browser, 1: Dashboard
  bool _isLoading = false;
  Timer? _monitorTimer;

  // Default URL
  String currentUrl = 'https://m.bantubet.co.ao';

  @override
  void initState() {
    super.initState();
    _urlController.text = currentUrl;
    _initializeController();
    _startMonitoring();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              currentUrl = url;
              _urlController.text = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(currentUrl));
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_monitoredItems.isEmpty) return;

      for (var item in _monitoredItems) {
        // Only monitor if we are on the same page (or we can try to inject JS anyway if the selector exists)
        // For simplicity, we try to find the element on the current page.
        try {
          final result = await _controller.runJavaScriptReturningResult(
            "document.querySelector('${item.selector}').innerText",
          );

          if (result is String) {
            // Remove quotes from JS result
            String cleanResult = result.replaceAll('"', '');
            if (cleanResult != 'null' && cleanResult.isNotEmpty) {
              setState(() {
                item.currentValue = cleanResult;
                item.lastUpdated = DateTime.now();
              });
            }
          }
        } catch (e) {
          // Element not found or other error
        }
      }
    });
  }

  void _navigate() {
    final url = _urlController.text;
    if (url.isNotEmpty) {
      _controller.loadRequest(
        Uri.parse(url.startsWith('http') ? url : 'https://$url'),
      );
      FocusScope.of(context).unfocus();
    }
  }

  void _addMonitor() {
    final nameController = TextEditingController();
    final selectorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Adicionar Monitor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Navegue até a página desejada e insira o Seletor CSS do elemento que deseja monitorar (ex: #id, .class).",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nome (ex: Vitória Time A)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: selectorController,
              decoration: const InputDecoration(
                labelText: "Seletor CSS (ex: .odd-value)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  selectorController.text.isNotEmpty) {
                setState(() {
                  _monitoredItems.add(
                    MonitorItem(
                      id: DateTime.now().toString(),
                      name: nameController.text,
                      selector: selectorController.text,
                      url: currentUrl,
                      lastUpdated: DateTime.now(),
                    ),
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Monitor adicionado com sucesso!"),
                  ),
                );
              }
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Monitor de Odds'), elevation: 0),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Index 0: Browser View
          Column(
            children: [
              // URL Bar
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: "Digite a URL",
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          prefixIcon: const Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                        onSubmitted: (_) => _navigate(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _navigate,
                    ),
                  ],
                ),
              ),
              if (_isLoading) const LinearProgressIndicator(minHeight: 2),
              Expanded(child: WebViewWidget(controller: _controller)),
            ],
          ),

          // Index 1: Dashboard View
          _monitoredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Nenhum monitor ativo",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 0),
                        child: const Text("Ir para o Navegador"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _monitoredItems.length,
                  itemBuilder: (context, index) {
                    final item = _monitoredItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _monitoredItems.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Valor Atual",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      item.currentValue,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "Última atualização",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "${item.lastUpdated.hour}:${item.lastUpdated.minute}:${item.lastUpdated.second}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Seletor: ${item.selector}",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.public), label: "Navegador"),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _addMonitor,
              child: const Icon(Icons.add_chart),
              tooltip: "Adicionar Monitor",
            )
          : null,
    );
  }
}
