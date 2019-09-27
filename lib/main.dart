import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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