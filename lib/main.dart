import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '貸し借りめも',
      theme: ThemeData(

        primarySwatch: Colors.orange,
      ),
      home: MyListPage(),
    );
  }
}

class MyListPage extends StatefulWidget {

  @override
  _MyListPageState createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        title: Text("リスト画面"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection('kasikari-memo').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if(!snapshot.hasData) {
              return const Text('Loading...');
            }
            return ListView.builder(
              itemCount: snapshot.data.documents.length,
              padding: const EdgeInsets.only(top: 10.0),
              itemBuilder: (context, index) => _buildListItem(context, snapshot.data.documents[index]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: (){
          print("新規作成ボタンを押しました");
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: "/new"),
              builder: (BuildContext context) => InputForm(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot documentSnapshot) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.android),
            title: Text("【" + (documentSnapshot['borrowOrLend'] == "lend" ? "貸" : "借") + "】"
                + documentSnapshot['stuff']),
            subtitle: Text('期限： ' + documentSnapshot['date'].toDate().toString().substring(0,10)
                + "\n相手： " + documentSnapshot['user']),
          ),
          ButtonTheme.bar(
            child: ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: const Text("編集"),
                  onPressed: (){
                    print("編集ボタンを押しました");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InputForm extends StatefulWidget {
  @override
  _MyInputFormState createState() => _MyInputFormState();
}

class _FormData {
  String borrowOrLend = "borrow";
  String user;
  String stuff;
  DateTime date = DateTime.now();
}

class _MyInputFormState extends State<InputForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _FormData _data = _FormData();

  void _setLendOrRent(String value) {
    setState(() {
      _data.borrowOrLend = value;
    });
  }

  Future<DateTime> _selectTime(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: _data.date,
      firstDate: DateTime(_data.date.year - 2),
      lastDate:  DateTime(_data.date.year + 2),
    );
  }

  DocumentReference _mainReference = Firestore.instance
      .collection('kasikari-memo').document();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('貸し借り入力'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: (){
              print("保存ボタンを押しました");
              if(_formKey.currentState.validate()) {
                _formKey.currentState.save();
                _mainReference.setData({
                  'borrowOrLend': _data.borrowOrLend,
                  'user': _data.user,
                  'stuff': _data.stuff,
                  'date': _data.date,
                });
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: (){
              print("削除ボタンを押しました");
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: <Widget>[
              RadioListTile(
                value: "borrow",
                groupValue: _data.borrowOrLend,
                title: Text("借りた"),
                onChanged: (String value){
                  print("借りたをタッチしました");
                  _setLendOrRent(value);
                  print("貸し借りステータスを${_data.borrowOrLend}へ変更しました");
                },
              ),
              RadioListTile(
                value: "lend",
                groupValue: _data.borrowOrLend,
                title: Text("貸した"),
                onChanged: (String value){
                  print("貸したをタッチしました");
                  _setLendOrRent(value);
                  print("貸し借りステータスを${_data.borrowOrLend}へ変更しました");
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.person),
                  hintText: '相手の名前',
                  labelText: 'Name',
                ),
                onSaved: (String value){
                  _data.user = value;
                },
                validator: (value){
                  if(value.isEmpty){
                    return '名前を入力してください';
                  }
//                  return '';
                },
                initialValue: _data.user,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.business_center),
                  hintText: '借りたもの、貸したもの',
                  labelText: 'Loan',
                ),
                onSaved: (String value){
                  _data.stuff = value;
                },
                validator: (value){
                  if(value.isEmpty){
                    return '対象のものを入力してください';
                  }
//                  return '';
                },
                initialValue: _data.stuff,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("締め切り日：${_data.date.toString().substring(0,10)}"),
              ),
              RaisedButton(
                child: const Text("締め切り日変更"),
                onPressed: (){
                  print("締め切り日変更をタッチしました");
                  _selectTime(context).then((time){
                    if(time != null && time != _data.date) {
                      setState(() {
                        _data.date = time;
                      });
                      print("締め切り日を${_data.date.toString().substring(0,10)}に変更しました");
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}