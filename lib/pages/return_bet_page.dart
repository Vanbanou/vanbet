import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReturnBetPage extends StatefulWidget {
  const ReturnBetPage({super.key});

  @override
  State<ReturnBetPage> createState() => _ReturnBetPageState();
}

class _ReturnBetPageState extends State<ReturnBetPage> {
  final TextEditingController _initialOddController = TextEditingController();
  final TextEditingController _initialAmountController =
      TextEditingController();
  final TextEditingController _newOddController = TextEditingController();
  final TextEditingController _desiredAmountController =
      TextEditingController();

  final FocusNode _initialAmountFocusNode = FocusNode();
  final FocusNode _newOddFocusNode = FocusNode();
  final FocusNode _desiredAmoutFocusNode = FocusNode();

  // State variables
  double _initialOdd = 0.0;
  double _initialAmount = 0.0;
  double _totalReturn = 0.0;
  double _profit = 0.0;

  // Calculation results
  double _newOdd = 0.0;
  double _requiredAmount = 0.0;
  double _minOdd = 0.0;
  String _statusMessage = "";
  bool _isProfitable = false;

  // 0 = Recuperar por Nova Odd, 1 = Recuperar por Valor Desejado
  int _selectedMode = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _initialOddController.dispose();
    _initialAmountController.dispose();
    _newOddController.dispose();
    _desiredAmountController.dispose();
    _initialAmountFocusNode.dispose();
    _newOddFocusNode.dispose();
    _desiredAmoutFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _initialOdd =
          double.tryParse(prefs.getString('initialOdd') ?? '0.0') ?? 0.0;
      _initialAmount =
          double.tryParse(prefs.getString('initialAmount') ?? '0.0') ?? 0.0;
      _newOdd = double.tryParse(prefs.getString('newOdd') ?? '0.0') ?? 0.0;
      double desiredAmount =
          double.tryParse(prefs.getString('requiredAmount') ?? '0.0') ?? 0.0;

      if (_initialOdd > 0) _initialOddController.text = _initialOdd.toString();
      if (_initialAmount > 0)
        _initialAmountController.text = _initialAmount.toString();
      if (_newOdd > 0) _newOddController.text = _newOdd.toString();
      if (desiredAmount > 0)
        _desiredAmountController.text = desiredAmount.toString();

      _calculate();
    });
  }

  Future<void> _saveData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('initialOdd', _initialOdd.toString());
    await prefs.setString('initialAmount', _initialAmount.toString());
    await prefs.setString('newOdd', _newOddController.text);
    await prefs.setString('requiredAmount', _desiredAmountController.text);
  }

  void _cleanAll() {
    setState(() {
      _initialOddController.clear();
      _initialAmountController.clear();
      _newOddController.clear();
      _desiredAmountController.clear();
      _initialOdd = 0.0;
      _initialAmount = 0.0;
      _totalReturn = 0.0;
      _profit = 0.0;
      _requiredAmount = 0.0;
      _minOdd = 0.0;
      _statusMessage = "";
      _isProfitable = false;
    });
    _saveData();
  }

  void _calculate() {
    setState(() {
      _initialOdd = double.tryParse(_initialOddController.text) ?? 0.0;
      _initialAmount = double.tryParse(_initialAmountController.text) ?? 0.0;

      if (_initialOdd <= 1 || _initialAmount <= 0) {
        _totalReturn = 0.0;
        _profit = 0.0;
        _statusMessage = "Insira uma odd inicial válida (> 1) e um montante.";
        _isProfitable = false;
        return;
      }

      _totalReturn = _initialOdd * _initialAmount;
      _profit = _totalReturn - _initialAmount;

      if (_selectedMode == 0) {
        // Recuperar por Nova Odd
        double newOdd = double.tryParse(_newOddController.text) ?? 0.0;
        if (newOdd > 1) {
          _requiredAmount = _initialAmount / (newOdd - 1);
          if (_requiredAmount <= _profit) {
            _statusMessage =
                "Aposte Kz ${_requiredAmount.toStringAsFixed(2)} para recuperar.";
            _isProfitable = true;
          } else {
            _statusMessage =
                "Impossível recuperar com esta odd (Lucro insuficiente).";
            _isProfitable = false;
          }
        } else {
          _requiredAmount = 0.0;
          _statusMessage = "Insira uma nova odd válida (> 1).";
          _isProfitable = false;
        }
      } else {
        // Recuperar por Valor Desejado
        double desiredAmount =
            double.tryParse(_desiredAmountController.text) ?? 0.0;
        if (desiredAmount > 0) {
          if (desiredAmount <= _profit) {
            _minOdd = (_initialAmount + desiredAmount) / desiredAmount;
            _statusMessage =
                "Odd mínima necessária: ${_minOdd.toStringAsFixed(2)}";
            _isProfitable = true;
          } else {
            _statusMessage = "Valor desejado excede o lucro possível.";
            _isProfitable = false;
          }
        } else {
          _minOdd = 0.0;
          _statusMessage = "Insira um valor a apostar válido.";
          _isProfitable = false;
        }
      }
      _saveData();
    });
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
            tooltip: "Limpar tudo",
          ),
          SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 20),
            _buildModeSelector(theme),
            const SizedBox(height: 20),
            _buildInputSection(theme),
            const SizedBox(height: 20),
            if (_initialOdd > 1 && _initialAmount > 0) _buildResultsCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Text(
      "Calcule como recuperar sua aposta perdida ou garantir lucro.",
      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(child: _buildModeButton(theme, "Por Odd", 0)),
          Expanded(child: _buildModeButton(theme, "Por Valor", 1)),
        ],
      ),
    );
  }

  Widget _buildModeButton(ThemeData theme, String label, int index) {
    final isSelected = _selectedMode == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = index;
          _calculate();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
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
                    controller: _initialOddController,
                    decoration: const InputDecoration(
                      labelText: "Odd Inicial",
                      prefixIcon: Icon(Icons.sports_score),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _calculate(),
                    onSubmitted: (_) => _initialAmountFocusNode.requestFocus(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _initialAmountController,
                    focusNode: _initialAmountFocusNode,
                    decoration: const InputDecoration(
                      labelText: "Aposta (Kz)",
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _calculate(),
                    onSubmitted: (_) {
                      if (_selectedMode == 0) {
                        _newOddFocusNode.requestFocus();
                      } else {
                        _desiredAmoutFocusNode.requestFocus();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedMode == 0)
              TextField(
                controller: _newOddController,
                focusNode: _newOddFocusNode,
                decoration: const InputDecoration(
                  labelText: "Nova Odd (para recuperar)",
                  prefixIcon: Icon(Icons.trending_up),
                  helperText: "Odd da aposta de recuperação",
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculate(),
              )
            else
              TextField(
                controller: _desiredAmountController,
                focusNode: _desiredAmoutFocusNode,
                decoration: const InputDecoration(
                  labelText: "Valor a Apostar (Kz)",
                  prefixIcon: Icon(Icons.money),
                  helperText: "Quanto você quer apostar agora?",
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculate(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Resumo da Aposta Inicial",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildResultRow(
              "Retorno Potencial",
              "${_totalReturn.toStringAsFixed(2)} Kz",
            ),
            _buildResultRow(
              "Lucro Potencial",
              "${_profit.toStringAsFixed(2)} Kz",
              valueColor: Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              "Estratégia de Recuperação",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            if (_selectedMode == 0) ...[
              _buildResultRow(
                "Aposta Necessária",
                "${_requiredAmount.toStringAsFixed(2)} Kz",
                valueColor: _isProfitable
                    ? theme.primaryColor
                    : theme.colorScheme.error,
                isBold: true,
              ),
            ] else ...[
              _buildResultRow(
                "Odd Mínima",
                "${_minOdd.toStringAsFixed(2)}",
                valueColor: _isProfitable
                    ? theme.primaryColor
                    : theme.colorScheme.error,
                isBold: true,
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isProfitable
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isProfitable ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isProfitable ? Icons.check_circle : Icons.error,
                    color: _isProfitable ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isProfitable
                            ? Colors.green[800]
                            : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
