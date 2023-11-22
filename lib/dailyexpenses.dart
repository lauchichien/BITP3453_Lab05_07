import 'package:bitp3453lab5/Controller/request_controller.dart';
import 'package:flutter/material.dart';

import 'Model/expense.dart';

class DailyExpensesApp extends StatelessWidget {

  // Constructor parameter to accept the Username value
  final String username;
  const DailyExpensesApp({required this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // username will be passed to ExpenseList()
      home: ExpenseList(username: username),
    );
  }
}

class ExpenseList extends StatefulWidget {

  // Constructor parameter to accept the Username value
  final String username;
  ExpenseList({required this.username});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {

  /**
   * By accepting the username parameter in both
   * the DailyExpensesApp and ExpenseList constructors,
   * you enable the passing of the username value from the
   * parent screen (in this case, DailyExpensesApp) to the
   * child screen (in this case, ExpenseList).
   * This allows you to use the username value on the
   * ExpenseList screen.
   */
  final List<Expense> expenses = [];
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController txtDateController = TextEditingController();
  double total = 0.0;
  // added new parameter for Expense Constructor = DateTime text

  void _addExpense() async{
    String description = descriptionController.text.trim();
    String amount = amountController.text.trim();
    int id = 0;

    if(description.isNotEmpty && amount.isNotEmpty){
      Expense exp
      = Expense(0, double.parse(amount), description, txtDateController.text);

      if(await exp.save()){
        setState(() {
          expenses.add(exp);
          descriptionController.clear();
          amountController.clear();
          calculateTotal();
        });
      }else{
        _showMessage("Failed to save Expenses data");
      }
    }
  }

  void calculateTotal(){
    total = 0;
    for(Expense ex in expenses) {
      total += ex.amount;
    }
    totalController.text = total.toString();
  }

  void _removeExpense(int index){
    total = total - expenses[index].amount;

    setState(() {
      expenses.removeAt(index);
      totalController.text = total.toString();
    });
  }

  void _showMessage(String msg){
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg)
        ),
      );
    }
  }

  void _editExpense(int index)
  {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context)=> EditExpenseScreen(
            expense: expenses[index],
            onSave: (editedExpense){
              setState(() {
                total += editedExpense.amount - expenses[index].amount;
                expenses[index] = editedExpense;
                totalController.text = total.toString();
              });
            }
        ),
      ),
    );
  }

  // new function - Date and time picker on textfield
  _selectDate() async{
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if(pickedDate!=null && pickedTime != null){
      setState(() {
        txtDateController.text =
        "${pickedDate.year}-${pickedDate.month}-${pickedDate.day} "
            "${pickedTime.hour}:${pickedTime.minute}:00";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) async {
      _showMessage("Welcome ${widget.username}");

      totalController.clear();

      RequestController req = RequestController(
          path: "/api/timezone/Asia/Kuala_Lumpur",
          server: "http://worldtimeapi.org");
      req.get().then((value){
        dynamic res = req.result();
        txtDateController.text = res["datetime"].toString().substring(0,19).replaceAll('T', ' ');
      });

      expenses.addAll(await Expense.loadAll());

      setState(() {
        calculateTotal();
      });
    });
  }

  Future<String> _getCurrentDateTime() async {
    RequestController req = RequestController(
        path: "/api/timezone/Asia/Kuala_Lumpur",
        server: "http://worldtimeapi.org");
    await req.get();
    dynamic res = req.result();
    return res["datetime"].toString().substring(0, 19).replaceAll('T', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Daily Expenses'),

        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (RM)',
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<String>(
                future: _getCurrentDateTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    txtDateController.text = snapshot.data!;
                    return TextField(
                      keyboardType: TextInputType.datetime,
                      readOnly: true,
                      onTap: _selectDate,
                      controller: txtDateController,
                      decoration: InputDecoration(
                        labelText: 'Date',
                      ),
                    );
                  }
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: totalController,
                // enabled: false, //disable from editing text in text field
                decoration: InputDecoration(
                  labelText: 'Total Spend (RM)',
                ),
              ),
            ),

            ElevatedButton(
                onPressed: _addExpense,
                child: Text('Add Expense')
            ),

            Container(
              child: _buildListView(),
            ),
          ],
        )
    );
  }


  Widget _buildListView() {
    return Expanded(
      child: ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            return Dismissible(
              key: Key(expenses[index].id.toString()),
              background: Container(
                  color: Colors.red,
                  child: Center(
                      child: Text("Delete", style: TextStyle(
                          color: Colors.white
                      ))
                  )
              ),
              onDismissed: (direction) async{
                final success = await expenses[index].delete();
                print(success);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Item deleted'))
                );
                setState(() {
                  _removeExpense(index);
                });
              },
              child: Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(expenses[index].description),
                  subtitle: Row(
                    children: [
                      Text('Amount: ${expenses[index].amount}'),
                      const Spacer(),
                      Text('Date: ${expenses[index].dateTime}')
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async{
                      // Delete expense on press
                      final success = await expenses[index].delete();
                      if (success) {
                        // Update UI
                        _removeExpense(index);
                        setState(() {
                          expenses.removeAt(index);
                        });
                      }
                    },
                  ),
                  onLongPress: (){
                    _editExpense(index);
                  },
                ),
              ),
            );
          }
      ),
    );
  }
}

class EditExpenseScreen extends StatelessWidget {
  //const EditExpenseScreen({super.key});
  final Expense expense;
  final Function(Expense) onSave;

  EditExpenseScreen({required this.expense, required this.onSave});

  final TextEditingController descController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController txtDateController = TextEditingController();
  final TextEditingController idController = TextEditingController();

  Future<String> _getCurrentDateTime() async {
    RequestController req = RequestController(
        path: "/api/timezone/Asia/Kuala_Lumpur",
        server: "http://worldtimeapi.org");
    await req.get();
    dynamic res = req.result();
    return res["datetime"].toString().substring(0, 19).replaceAll('T', ' ');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedDate != null && pickedTime != null) {
      txtDateController.text =
      "${pickedDate.year}-${pickedDate.month}-${pickedDate.day} "
          "${pickedTime.hour}:${pickedTime.minute}:00";
    }
  }


  @override
  Widget build(BuildContext context) {

    descController.text = expense.description;
    amountController.text = expense.amount.toString();
    txtDateController.text = expense.dateTime;
    idController.text = expense.id.toString();

    return Scaffold(
        appBar: AppBar(
          title: Text('Edit Expense'),
        ),
        body:
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                  )
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount (RM)',
                  )
              ),
            ),


            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<String>(
                future: _getCurrentDateTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    txtDateController.text = snapshot.data!;
                    return TextField(
                      keyboardType: TextInputType.datetime,
                      readOnly: true,
                      controller: txtDateController,
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        labelText: 'Date',
                      ),
                    );
                  }
                },
              ),
            ),

            ElevatedButton(
                onPressed:() async{
                  // Save the edited expense details
                  expense.id = expense.id;
                  expense.description = descController.text;
                  expense.amount = double.parse(amountController.text);
                  expense.dateTime = txtDateController.text;

                  // Update expense in database and server
                  final isUpdated = await expense.update();
                  print(isUpdated);

                  // If update is successful, notify and navigate back
                  if (isUpdated) {
                    onSave(Expense(0, double.parse(amountController.text),
                        descController.text, txtDateController.text));
                    Navigator.pop(context);
                  } else {
                    print("failure");
                  }
                },
                child: Text("Save")
            ),
          ],
        )
    );
  }
}