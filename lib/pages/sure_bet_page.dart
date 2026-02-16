import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo simples para organizar os detalhes de cada aposta
class BetDetail {
  final double odd;
  final double stake;
  final double potentialReturn;

  BetDetail({
    required this.odd,
    required this.stake,
    required this.potentialReturn,
  });
}

class SureBetPage extends StatefulWidget {
  const SureBetPage({super.key});

  @override
  State<SureBetPage> createState() => _SureBetPageState();
}

class _SureBetPageState extends State<SureBetPage> {
  // --- ESTADO E CONTROLE ---
  final List<double> _oddList = [];
  final List<BetDetail> _calculationDetails = [];

  final TextEditingController _oddsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  double _totalAmount = 0;
  double _totalReturn = 0;
  double _profitOrLoss = 0;
  double _roi = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _oddsController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  // --- LÓGICA DE PERSISTÊNCIA ---

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? oddsString = prefs.getStringList('oddsListSure');

    if (oddsString != null) {
      setState(() {
        _oddList.addAll(oddsString.map((e) => double.tryParse(e) ?? 0.0));
      });
    }

    final double amount = prefs.getDouble('totalAmountSure') ?? 0.0;
    if (amount > 0) _amountController.text = amount.toString();

    _calculateSureBet();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'oddsListSure',
      _oddList.map((e) => e.toString()).toList(),
    );
    final double amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    await prefs.setDouble('totalAmountSure', amount);
  }

  // --- LÓGICA DE CÁLCULO ---

  void _calculateSureBet() {
    _totalAmount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    _calculationDetails.clear();

    if (_totalAmount > 0 && _oddList.isNotEmpty) {
      double inverseSum = _oddList.fold(0, (sum, odd) => sum + (1 / odd));
      _totalReturn = _totalAmount / inverseSum;
      _profitOrLoss = _totalReturn - _totalAmount;
      _roi = (_profitOrLoss / _totalAmount) * 100;

      for (var odd in _oddList) {
        double stake = (_totalAmount / odd) / inverseSum;
        _calculationDetails.add(
          BetDetail(odd: odd, stake: stake, potentialReturn: stake * odd),
        );
      }
    } else {
      _totalReturn = 0;
      _profitOrLoss = 0;
      _roi = 0;
    }
    setState(() {});
    _saveData();
  }

  // --- AÇÕES ---

  void _addOdd() {
    final double? val = double.tryParse(
      _oddsController.text.replaceAll(',', '.'),
    );
    if (val != null && val > 1) {
      setState(() {
        _oddList.add(val);
        _oddsController.clear();
        _calculateSureBet();
      });
    }
  }

  void _cleanAll() {
    setState(() {
      _oddList.clear();
      _oddsController.clear();
      _amountController.clear();
      _calculationDetails.clear();
      _totalReturn = 0;
      _profitOrLoss = 0;
      _roi = 0;
    });
    _saveData();
  }

  // --- INTERFACE (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculadora SureBet"),
        actions: [
          IconButton(
            onPressed: _cleanAll,
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: "Limpar tudo",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInputCard(),
            const SizedBox(height: 16),
            _buildOddsList(),
            const SizedBox(height: 16),
            if (_oddList.isNotEmpty) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _oddsController,
              decoration: InputDecoration(
                labelText: "Adicionar Odd",
                prefixIcon: const Icon(Icons.trending_up),
                suffixIcon: IconButton(
                  onPressed: _addOdd,
                  icon:  Icon(
                    Icons.add_circle,
                    color: Theme.of(context).primaryColor,
                    size: 30,
                  ),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onSubmitted: (_) => _addOdd(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              decoration: const InputDecoration(
                labelText: "Investimento Total (Kz)",
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => _calculateSureBet(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOddsList() {
    if (_oddList.isEmpty) {
      return const Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 64),
            SizedBox(height: 8),
            Text("Adicione pelo menos duas odds para calcular"),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _oddList.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
              child: Text(
                "${index + 1}",

                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              "Odd ${_oddList[index].toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  _oddList.removeAt(index);
                  _calculateSureBet();
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard() {
    final bool isProfitable = _profitOrLoss > 0;
    return Card(
      color: Colors.white,
elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _resultRow(
              "Possível Retorno:",
              "${_totalReturn.toStringAsFixed(2)} Kz",
            ),
            const SizedBox(height: 8),
            _resultRow(
              isProfitable ? "Lucro Garantido:" : "Prejuízo Estimado:",
              "${isProfitable ? '+' : ''}${_profitOrLoss.toStringAsFixed(2)} Kz",
              valueColor: isProfitable ? Colors.green : Colors.red,
              bold: true,
            ),
            _resultRow(
              "ROI:",
              "${_roi.toStringAsFixed(2)}%",
              valueColor: isProfitable ? Colors.green : Colors.red,
            ),
            const Divider(height: 24),
            ElevatedButton.icon(
              onPressed: _showDetailedDistribution,
              icon: const Icon(Icons.bar_chart),
              label: const Text("DISTRIBUIÇÃO DAS APOSTAS"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // --- DIÁLOGO DE DISTRIBUIÇÃO ---

  void _showDetailedDistribution() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Sugestão de Distribuição",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Divida seu capital da seguinte forma:",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _calculationDetails.length,
                      itemBuilder: (context, index) {
                        final item = _calculationDetails[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Odd: ${item.odd.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${item.stake.toStringAsFixed(2)} Kz",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "Retorno Bruto",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "${item.potentialReturn.toStringAsFixed(2)} Kz",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Custo Total: ${_totalAmount.toStringAsFixed(2)} Kz",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
