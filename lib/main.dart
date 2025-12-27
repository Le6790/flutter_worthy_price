import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/saved_item.dart';
import 'services/saved_items_service.dart';
import 'pages/saved_items_page.dart';

void main() {
  runApp(const WorthyPriceApp());
}

class WorthyPriceApp extends StatelessWidget {
  const WorthyPriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worthy Price',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const WorthyPriceCalculator(),
    );
  }
}

class WorthyPriceCalculator extends StatefulWidget {
  const WorthyPriceCalculator({super.key});

  @override
  State<WorthyPriceCalculator> createState() => _WorthyPriceCalculatorState();
}

class _WorthyPriceCalculatorState extends State<WorthyPriceCalculator> {
  final TextEditingController _wageController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final SavedItemsService _savedItemsService = SavedItemsService();

  bool _isAnnualSalary = true;
  double? _hourlyWage;
  double? _itemPrice;
  String? _itemName;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAnnualSalary = prefs.getBool('isAnnualSalary') ?? true;
      final savedWage = prefs.getDouble('wageAmount');
      if (savedWage != null) {
        _wageController.text = savedWage.toStringAsFixed(2);
        _calculateHourlyWage(savedWage);
      }
    });
  }

  Future<void> _saveWageData(double wage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAnnualSalary', _isAnnualSalary);
    await prefs.setDouble('wageAmount', wage);
  }

  void _calculateHourlyWage(double inputWage) {
    if (_isAnnualSalary) {
      // Assume 2080 working hours per year (40 hours/week * 52 weeks)
      _hourlyWage = inputWage / 2080;
    } else {
      _hourlyWage = inputWage;
    }
    _saveWageData(inputWage);
  }

  void _onWageChanged(String value) {
    final wage = double.tryParse(value);
    if (wage != null && wage > 0) {
      setState(() {
        _calculateHourlyWage(wage);
      });
    } else {
      setState(() {
        _hourlyWage = null;
      });
    }
  }

  void _onItemPriceChanged(String value) {
    setState(() {
      _itemPrice = double.tryParse(value);
    });
  }
  void _onItemNameChanged(String value) {
    setState(() {
      _itemName = value;
    });
  }

  void _toggleWageType() {
    setState(() {
      _isAnnualSalary = !_isAnnualSalary;
      final currentValue = double.tryParse(_wageController.text);
      if (currentValue != null) {
        _calculateHourlyWage(currentValue);
      }
    });
  }

  Map<String, dynamic>? _calculateWorkTime() {
    if (_hourlyWage == null || _itemPrice == null || _hourlyWage! <= 0) {
      return null;
    }

    final hoursNeeded = _itemPrice! / _hourlyWage!;
    final hours = hoursNeeded.floor();
    final minutes = ((hoursNeeded - hours) * 60).round();

    return {
      'hours': hours,
      'minutes': minutes,
      'totalHours': hoursNeeded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final workTime = _calculateWorkTime();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worthy Price App'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Saved Items',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedItemsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Introduction text
            Text(
              'Calculate how long you need to work to afford an item.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Wage input section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Income',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle for Annual/Hourly
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: true,
                                label: Text('Annual Salary'),
                                icon: Icon(Icons.calendar_today),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text('Hourly Wage'),
                                icon: Icon(Icons.access_time),
                              ),
                            ],
                            selected: {_isAnnualSalary},
                            onSelectionChanged: (Set<bool> selection) {
                              _toggleWageType();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Wage input field
                    TextField(
                      controller: _wageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: _isAnnualSalary ? 'Annual Salary' : 'Hourly Wage',
                        prefixText: '\$ ',
                        suffixText: _isAnnualSalary ? '/year' : '/hour',
                        border: const OutlineInputBorder(),
                        filled: true,
                      ),
                      onChanged: _onWageChanged,
                    ),

                    // Show calculated hourly wage if annual salary
                    if (_isAnnualSalary && _hourlyWage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha:0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hourly: \$${_hourlyWage!.toStringAsFixed(2)}/hour',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Show calculated annual salary if hourly wage
                    if (!_isAnnualSalary && _hourlyWage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha:0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Annual Salary: \$${(_hourlyWage!*2080).toStringAsFixed(2)}/year',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Item name input section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item Name',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _itemNameController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                        filled: true,
                        hintText: 'Enter the name of the item',
                      ),
                      onChanged: _onItemNameChanged,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Item price input section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item Price',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _itemPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Item Price',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        filled: true,
                        hintText: 'Enter the price of the item',
                      ),
                      onChanged: _onItemPriceChanged,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Results section
            if (workTime != null) ...[
              Card(
                elevation: 4,
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Time to Work for ${_itemName ?? "Item"}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatWorkTime(workTime),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getMotivationalMessage(workTime['totalHours']),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ElevatedButton( // Save Item Button
              onPressed: (_itemName != null &&
                         _itemName!.isNotEmpty &&
                         _itemPrice != null &&
                         _itemPrice! > 0 &&
                         _hourlyWage != null &&
                         _hourlyWage! > 0)
                  ? () async {
                      final workTime = _calculateWorkTime();
                      if (workTime == null) return;

                      final savedItem = SavedItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        itemName: _itemName!,
                        itemPrice: _itemPrice!,
                        hourlyWage: _hourlyWage!,
                        workTimeHours: workTime['totalHours'] as double,
                        savedAt: DateTime.now(),
                      );

                      final success = await _savedItemsService.saveItem(savedItem);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Item saved successfully!'
                                  : 'Failed to save item. Please try again.',
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        if (success) {
                          setState(() {
                            _itemNameController.clear();
                            _itemPriceController.clear();
                            _itemName = null;
                            _itemPrice = null;
                          });
                        }
                      }
                    }
                  : null,
              child: const Text('Save Item'),
            ),
            ] else if (_hourlyWage != null && _itemPrice == null) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha:0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter an item price to see how long you need to work',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_hourlyWage == null) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha:0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter your income to get started',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatWorkTime(Map<String, dynamic> workTime) {
    final hours = workTime['hours'] as int;
    final minutes = workTime['minutes'] as int;

    if (hours == 0) {
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    } else if (minutes == 0) {
      return '$hours hour${hours != 1 ? 's' : ''}';
    } else {
      return '$hours hour${hours != 1 ? 's' : ''} $minutes minute${minutes != 1 ? 's' : ''}';
    }
  }

  String _getMotivationalMessage(double totalHours) {
    if (totalHours < 1) {
      return 'Less than an hour of work - that\'s quite affordable!';
    } else if (totalHours < 8) {
      return 'Less than a day\'s work - seems reasonable!';
    } else if (totalHours < 40) {
      return 'About ${(totalHours / 8).toStringAsFixed(1)} work days - is it worth it?';
    } else if (totalHours < 160) {
      return 'About ${(totalHours / 40).toStringAsFixed(1)} work weeks - that\'s significant!';
    } else {
      return 'About ${(totalHours / 160).toStringAsFixed(1)} work months - think carefully!';
    }
  }

  @override
  void dispose() {
    _wageController.dispose();
    _itemPriceController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }
}
