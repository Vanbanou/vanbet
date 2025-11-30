import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimulatePage extends StatefulWidget {
  const SimulatePage({super.key});

  @override
  State<SimulatePage> createState() => _SimulatePageState();
}

class _SimulatePageState extends State<SimulatePage> {
  // Lista das odds
  List<double> _oddList = [];
  double _totalOdds = 1.0;
  double _totalReturn = 0.0;
  double _totalProfit = 0.0;

  final TextEditingController _oddsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final FocusNode _focusNodeAmountTextfield = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _oddsController.dispose();
    _amountController.dispose();
    _focusNodeAmountTextfield.dispose();
    super.dispose();
  }

  // Carrega os dados salvos no SharedPreferences
  Future<void> _loadSavedData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _oddList =
          prefs
              .getStringList('oddListSimulate')
              ?.map((e) => double.parse(e))
              .toList() ??
          [];
      _amountController.text = prefs.getString('amountSimulate') ?? '';
      _calculateOdd();
      _calculateBet();
    });
  }

  // Salva os dados no SharedPreferences
  Future<void> _saveData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'oddListSimulate',
      _oddList.map((e) => e.toString()).toList(),
    );
    await prefs.setString('amountSimulate', _amountController.text);
  }

  // Calcula as odds totais
  void _calculateOdd() {
    _totalOdds = _oddList.fold(
      1.0,
      (previousValue, element) => previousValue * element,
    );
  }

  void _cleanAll() {
    setState(() {
      // Lista das odds
      _oddList = [];
      _totalOdds = 1.0;
      _totalReturn = 0.0;
      _totalProfit = 0.0;
      _amountController.clear();
      _oddsController.clear();
    });
    _saveData(); // Salva os dados sempre que há um cálculo
  }

  // Calcula retorno e lucro
  void _calculateBet() {
    double? amount = double.tryParse(_amountController.text);
    if (amount != null && amount > 0) {
      setState(() {
        _totalReturn = _totalOdds * amount;
        _totalProfit = _totalReturn - amount;
      });
    } else {
      setState(() {
        _totalReturn = 0.0;
        _totalProfit = 0.0;
      });
    }
    _saveData(); // Salva os dados sempre que há um cálculo
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simular Aposta"),
        actions: [
          IconButton(
            onPressed: _cleanAll,
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: "Limpar tudo",
          ),
          SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Adicione odds para simular uma aposta múltipla.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildInputSection(theme),
              const SizedBox(height: 4),
              _oddList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          "Nenhuma odd adicionada",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _oddList.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.primaryColor.withOpacity(
                                0.1,
                              ),
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              "Odd ${index + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _oddList[index].toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _oddList.removeAt(index);
                                      _calculateOdd();
                                      _calculateBet();
                                    });
                                    _saveData();
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 4),
              _buildSummaryCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _oddsController,
                    decoration: InputDecoration(
                      labelText: "Adicionar Odd",
                      prefixIcon: const Icon(Icons.show_chart_sharp),
                      suffixIcon: IconButton(
                        onPressed: () {
                          double? newOddValue = double.tryParse(
                            _oddsController.text,
                          );
                          if (newOddValue != null && newOddValue >= 1) {
                            setState(() {
                              _oddList.add(newOddValue);
                              _calculateOdd();
                              _oddsController.clear();
                            });
                            _calculateBet();
                          }
                        },
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onSubmitted: (value) {
                      _focusNodeAmountTextfield.requestFocus();
                    },
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              focusNode: _focusNodeAmountTextfield,
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Montante Total (Kz)",
                prefixIcon: Icon(Icons.attach_money),
              ),
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                _calculateBet();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Odd Total",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _totalOdds.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Retorno Potencial",
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  "${_totalReturn.toStringAsFixed(2)} Kz",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Lucro Estimado",
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  "${_totalProfit.toStringAsFixed(2)} Kz",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
