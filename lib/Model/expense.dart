import '../Controller/request_controller.dart';
import 'package:bitp3453lab5/Controller/sqlite_db.dart';

class Expense{
  static const String SQLiteTable = "expense";
  int? id;
  String description;
  double amount;
  String dateTime;
  Expense(this.id, this.amount, this.description, this.dateTime);

  Expense.fromJson(Map<String, dynamic> json)
      :   id = json['id'] as int,
        amount = double.parse(json['amount']),
        description = json['description'] as String,
        dateTime = json['dateTime'] as String;


  Map<String, dynamic> toJson() =>
      {'amount': amount, 'description': description, 'dateTime': dateTime.toString()};

  Map<String, dynamic> toUpdateJson() =>
      {'id': id, 'amount': amount, 'description': description, 'dateTime': dateTime.toString()};

  Map<String, dynamic> todeleteJson() =>
      {'id': id };

  Future<bool> update() async {
    if (id == null) {
      throw Exception("Cannot update expense with null ID");
    }

    // Update expense in local database
    final rowsUpdated = await SQLiteDB().update(
      SQLiteTable, 'id', toUpdateJson(),
    );

    // Update expense on server
    final req = RequestController(path: "/api/expenses.php");
    req.setBody(toUpdateJson());
    await req.put();

    return req.status() == 200;
  }

  Future<bool> delete() async {
    if (id == null) {
      throw Exception("Cannot delete expense with null ID");
    }

    // Delete expense from local database
    final rowsDeleted = await SQLiteDB().delete(
      SQLiteTable, 'id', id,
    );

    // Delete expense on server
    final req = RequestController(path: "/api/expenses.php");
    req.setBody(todeleteJson());
    await req.delete();

    return req.status() == 200;
  }


  Future<bool> save() async {

    //Save to local SQLite
    await SQLiteDB().insert(SQLiteTable, toJson());

    RequestController req = RequestController(path: "/api/expenses.php");
    req.setBody(toJson());

    try{
      await req.post();
      print(req.status());
      if (req.status() == 200){
        return true;
      }
      else{
        if(await SQLiteDB().insert(SQLiteTable, toJson())!=0){
          return true;
        }
        else{
          return false;
        }
      }
    } catch (e) {
      print("Exception during HTTP request: $e");
    }
    return false;
  }


  static Future<List<Expense>> loadAll() async{
    List<Expense> result = [];
    RequestController req = RequestController(path: "/api/expenses.php");
    await req.get();

    if(req.status() == 200 && req.result() != null){
      for (var item in req.result()){
        result.add(Expense.fromJson(item));
      }
    }
    else{
      // else it will load from local storage
      List<Map<String, dynamic>> result = await SQLiteDB().queryAll(SQLiteTable);
      List<Expense> expenses = [];
      for (var item in result){
        result.add(Expense.fromJson(item) as Map<String, dynamic>);
      }
    }
    return result;
  }
}