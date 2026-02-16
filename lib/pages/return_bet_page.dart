import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReturnBetPage extends StatefulWidget {
  const ReturnBetPage({super.key});

  @override
  State<ReturnBetPage> createState() => _ReturnBetPageState();
}

class _ReturnBetPageState extends State<ReturnBetPage> {
  final TextEditingController _odd1Controller = TextEditingController();
  final TextEditingController _stake1Controller = TextEditingController();
  final TextEditingController _odd2Controller = TextEditingController();
  final TextEditingController _manualStakeController = TextEditingController();

  final FocusNode _stake1Focus = FocusNode();
  final FocusNode _odd2Focus = FocusNode();
  final FocusNode _manualStakeFocus = FocusNode();

  double _finalStake2 = 0.0;
  double _netCenario1 = 0.0;
  double _netCenario2 = 0.0;

  // Novos campos para análise da Aposta 1
  double _gross1 = 0.0;
  double _net1 = 0.0;

  double _neededOddRecuperar = 0.0;
  double _neededOddDividir = 0.0;

  int _strategyIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _odd1Controller.dispose();
    _stake1Controller.dispose();
    _odd2Controller.dispose();
    _manualStakeController.dispose();
    _stake1Focus.dispose();
    _odd2Focus.dispose();
    _manualStakeFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _odd1Controller.text = prefs.getString('rb_odd1') ?? '';
      _stake1Controller.text = prefs.getString('rb_stake1') ?? '';
      _odd2Controller.text = prefs.getString('rb_odd2') ?? '';
      _manualStakeController.text = prefs.getString('rb_manual_stake') ?? '';
      _strategyIndex = prefs.getInt('rb_strategy') ?? 0;
      _calculate();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rb_odd1', _odd1Controller.text);
    await prefs.setString('rb_stake1', _stake1Controller.text);
    await prefs.setString('rb_odd2', _odd2Controller.text);
    await prefs.setString('rb_manual_stake', _manualStakeController.text);
    await prefs.setInt('rb_strategy', _strategyIndex);
  }

  void _cleanAll() {
    setState(() {
      _odd1Controller.clear();
      _stake1Controller.clear();
      _odd2Controller.clear();
      _manualStakeController.clear();
      _finalStake2 = 0;
      _netCenario1 = 0;
      _netCenario2 = 0;
      _gross1 = 0;
      _net1 = 0;
    });
    _saveData();
  }

  void _calculate() {
    double o1 = double.tryParse(_odd1Controller.text.replaceAll(',', '.')) ?? 0;
    double s1 =
        double.tryParse(_stake1Controller.text.replaceAll(',', '.')) ?? 0;
    double o2 = double.tryParse(_odd2Controller.text.replaceAll(',', '.')) ?? 0;
    double sManual =
        double.tryParse(_manualStakeController.text.replaceAll(',', '.')) ?? 0;

    setState(() {
      // Cálculo básico da Aposta 1 (Sempre visível)
      if (o1 > 0 && s1 > 0) {
        _gross1 = s1 * o1;
        _net1 = _gross1 - s1;
      } else {
        _gross1 = 0;
        _net1 = 0;
      }

      if (o1 <= 1 || s1 <= 0) {
        _finalStake2 = 0;
        _netCenario1 = 0;
        _netCenario2 = 0;
        return;
      }

      if (_strategyIndex == 3) {
        _finalStake2 = sManual;
        if (sManual > 0) {
          _neededOddRecuperar = (s1 + sManual) / sManual;
          _neededOddDividir = (s1 * o1) / sManual;
        }
      } else {
        if (o2 > 1) {
          if (_strategyIndex == 0)
            _finalStake2 = s1 / (o2 - 1);
          else if (_strategyIndex == 1)
            _finalStake2 = (s1 * o1) / o2;
          else
            _finalStake2 = (s1 * o1) - s1;
        } else {
          _finalStake2 = 0;
        }
      }

      if (_finalStake2 > 0 && o2 > 1) {
        _netCenario1 = (s1 * o1) - (s1 + _finalStake2);
        _netCenario2 = (_finalStake2 * o2) - (s1 + _finalStake2);
      } else if (_finalStake2 > 0 && _strategyIndex == 3) {
        // No modo manual, se ainda não houver O2, calculamos o cenário 1 parcial
        _netCenario1 = (s1 * o1) - (s1 + _finalStake2);
        _netCenario2 = 0;
      } else {
        _netCenario1 = 0;
        _netCenario2 = 0;
      }
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recuperar Aposta"),
        actions: [
          IconButton(
            onPressed: _cleanAll,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputSection(theme),
            const SizedBox(height: 16),
            _buildStrategySelector(theme),
            const SizedBox(height: 16),
            if (_gross1 > 0) _buildResultsCard(theme),
            if (_strategyIndex == 3 && _finalStake2 > 0)
              _buildManualAnalysis(theme),
          ],
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
                    controller: _odd1Controller,
                    decoration: const InputDecoration(
                      labelText: "Odd Aposta 1",
                      prefixIcon: Icon(Icons.looks_one_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stake1Controller,
                    focusNode: _stake1Focus,
                    decoration: const InputDecoration(
                      labelText: "Valor (Kz)",
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_strategyIndex != 3)
              TextField(
                controller: _odd2Controller,
                focusNode: _odd2Focus,
                decoration: const InputDecoration(
                  labelText: "Odd da Aposta 2 (Cobertura)",
                  prefixIcon: Icon(Icons.trending_up),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _calculate(),
              )
            else
              TextField(
                controller: _manualStakeController,
                focusNode: _manualStakeFocus,
                decoration: const InputDecoration(
                  labelText: "Quanto vais apostar na 2? (Kz)",
                  prefixIcon: Icon(Icons.edit_document),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _calculate(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySelector(ThemeData theme) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            _strategyTab("Recuperar", 0, theme),
            _strategyTab("Dividir", 1, theme),
            _strategyTab("Lucrar na 2", 2, theme),
            _strategyTab("Manual", 3, theme),
          ],
        ),
      ),
    );
  }

  Widget _strategyTab(String label, int index, ThemeData theme) {
    bool isSelected = _strategyIndex == index;
    return Expanded(
      child: InkWell(
        borderRadius: (index == 0 || index == 3)
            ? BorderRadius.only(
                topLeft: index == 0 ? Radius.circular(20) : Radius.zero,
                bottomLeft: index == 0 ? Radius.circular(20) : Radius.zero,
                topRight: index == 3 ? Radius.circular(20) : Radius.zero,
                bottomRight: index == 3 ? Radius.circular(20) : Radius.zero,
              )
            : BorderRadius.zero,
        onTap: () {
          setState(() {
            _strategyIndex = index;
            _calculate();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? theme.primaryColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? theme.primaryColor : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SEÇÃO NOVA: Análise da Aposta 1
            const Text(
              "POTENCIAL DA APOSTA 1",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniResult("Bruto", _gross1, Colors.blue),
                _miniResult("Líquido", _net1, Colors.green),
              ],
            ),
            const Divider(height: 32),

            // SEÇÃO DE COBERTURA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _strategyIndex == 3
                      ? "Valor da Cobertura"
                      : "Aposta Sugerida",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Kz ${_finalStake2.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _resultRow("Se Aposta 1 vencer (Net Total)", _netCenario1),
            const SizedBox(height: 8),
            _resultRow("Se Aposta 2 vencer (Net Total)", _netCenario2),
          ],
        ),
      ),
    );
  }

  Widget _miniResult(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          "${value.toStringAsFixed(2)} Kz",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildManualAnalysis(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Odd Necessária na Aposta 2:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _oddNeededRow("Para não perder nada", _neededOddRecuperar),
            _oddNeededRow("Para dividir o lucro da 1", _neededOddDividir),
            const SizedBox(height: 8),
            const Text(
              "Dica: Se a odd do mercado for maior que estas, você terá lucro.",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        Text(
          "${value.toStringAsFixed(2)} Kz",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: value > 0
                ? Colors.green
                : (value < 0 ? Colors.red : Colors.orange),
          ),
        ),
      ],
    );
  }

  Widget _oddNeededRow(String label, double odd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              odd.toStringAsFixed(2),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
