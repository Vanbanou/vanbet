import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/signature_service.dart';

class SignaturePage extends StatefulWidget {
  const SignaturePage({super.key});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final TextEditingController _keyController = TextEditingController();
  final SignatureService _signatureService = SignatureService();

  String _deviceId = "Carregando...";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  void _loadDeviceId() async {
    String id = await _signatureService.getDeviceId();
    setState(() => _deviceId = id);
  }

  // Função para abrir o WhatsApp configurada com seus dados
  void _sendToSupport() async {
    final String message =
        "Olá! Fiz o pagamento de 300 Kz (2 meses).\nID do Dispositivo: $_deviceId\n(Estou a anexar o comprovativo...)";
    // Substitua pelo seu número de WhatsApp com código do país (ex: 244...)
    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/244900000000?text=${Uri.encodeComponent(message)}",
    );

    if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Instale o WhatsApp para contactar o suporte."),
        ),
      );
    }
  }

  void _processActivation() async {
    if (_keyController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    bool success = await _signatureService.activateKey(
      _keyController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Acesso Premium Ativado!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Chave inválida. Contacte o suporte."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              "Assinatura Premium",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Use todas as ferramentas por 2 meses",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // --- BOX DE PAGAMENTO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    "DADOS PARA PAGAMENTO",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  _paymentRow("Entidade", "10116"),
                  _paymentRow("Referência", "945494991"),
                  _paymentRow("Valor", "300,00 Kz"),
                  const SizedBox(height: 16),
                  const Text(
                    "Após pagar, clique abaixo para enviar o comprovativo e o seu ID.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- BOTÃO SUPORTE ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendToSupport,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  "ENVIAR PARA SUPORTE",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const Text("Já tem a chave de ativação?"),
            const SizedBox(height: 12),

            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                hintText: "Insira a chave enviada pelo suporte",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processActivation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "VALIDAR ACESSO",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          SelectableText(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
