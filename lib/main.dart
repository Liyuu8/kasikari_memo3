import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share/share.dart';
import 'generated/i18n.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      localeResolutionCallback: S.delegate.resolution(fallback: new Locale("en","")),
//      title: S.of(context).title,
      title: "貸し借りメモ",
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      routes: <String, WidgetBuilder> {
        '/': (_) => Splash(),
        '/list': (_) => MyListPage(),
      },
    );
  }
}

FirebaseUser firebaseUser;
final FirebaseAuth _auth = FirebaseAuth.instance;

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _getUser(context);
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: FractionallySizedBox(
          child: Image.asset('res/image/note.png'),
          heightFactor: 0.4,
          widthFactor: 0.4,
        )
      ),
    );
  }
}

void _getUser(BuildContext context) async {
  try {
    firebaseUser = await _auth.currentUser();
    if(firebaseUser == null) {
      // 匿名アカウントを発行
      await _auth.signInAnonymously();
      firebaseUser = await _auth.currentUser();
    }
    Navigator.pushReplacementNamed(context, '/list');
  } catch(e) {
    Fluttertoast.showToast(msg: "Firebaseとの接続に失敗しました。");
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
        actions: <Widget>[
          // action button
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              print("Login.");
              showBasicDialog(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection('users')
              .document(firebaseUser.uid).collection('transaction').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if(!snapshot.hasData) {
              return const Text('Loading...');
            }
            return ListView.builder(
              itemCount: snapshot.data.documents.length,
              padding: const EdgeInsets.only(top: 10.0),
              itemBuilder: (context, index) =>
                  _buildListItem(context, snapshot.data.documents[index]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          print("新規作成ボタンを押しました");
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: "/new"),
              builder: (BuildContext context) => InputForm(null),
            ),
          );
        },
      ),
    );
  }

  void showBasicDialog(BuildContext context) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String email, password;
    if(firebaseUser.isAnonymous) {
      showDialog(
        context: context,
        builder: (BuildContext context) =>
            AlertDialog(
              title: Text("ログイン／登録ダイアログ"),
              content: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: const Icon(Icons.email),
                        labelText: 'Email',
                      ),
                      onSaved: (String value) {
                        email = value;
                      },
                      validator: (value) {
                        if(value.isEmpty) {
                          return 'Emailを入力してください';
                        }
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: const Icon(Icons.vpn_key),
                        labelText: 'Password',
                      ),
                      onSaved: (String value) {
                        password = value;
                      },
                      validator: (value) {
                        if(value.isEmpty) {
                          return 'Passwordを入力してください';
                        }
                        if(value.length < 6) {
                          return 'Passwordは6桁以上で入力してください';
                        }
                      },
                    ),
                  ],
                ),
              ),
              // ボタンの配置
              actions: <Widget>[
                FlatButton(
                  child: const Text('キャンセル'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  child: const Text('登録'),
                  onPressed: () {
                    if(_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      _createUser(context, email, password);
                    }
                  },
                ),
                FlatButton(
                  child: const Text('ログイン'),
                  onPressed: () {
                    if(_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      _signIn(context, email, password);
                    }
                  },
                ),
              ],
            ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) =>
            AlertDialog(
              title: const Text("確認ダイアログ"),
              content: Text(firebaseUser.email + "でログインしています。"),
              actions: <Widget>[
                FlatButton(
                  child: const Text('キャンセル'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  child: const Text('ログアウト'),
                  onPressed: () {
                    _auth.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                  },
                ),
              ],
            )
      );
    }
  }

  void _signIn(BuildContext context, String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch(e) {
      Fluttertoast.showToast(msg: "Firebaseのログインに失敗しました。");
    }
  }

  void _createUser(BuildContext context, String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch(e) {
      Fluttertoast.showToast(msg: "Firebaseの登録に失敗しました。");
    }
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
                  onPressed: () {
                    print("編集ボタンを押しました");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: "/edit"),
                        builder: (BuildContext context) => InputForm(documentSnapshot),
                      )
                    );
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
  final DocumentSnapshot documentSnapshot;
  InputForm(this.documentSnapshot);

  @override
  _MyInputFormState createState() => _MyInputFormState();
}

// エントリーデータの一時的な格納先
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
      .collection('users').document(firebaseUser.uid)
      .collection('transaction').document();

  void _confirmDeletionAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("削除の確認"),
        content: Text("本当に削除しますか？"),
        actions: <Widget>[
          FlatButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop<String>(context, 'Cancel'),
          ),
          FlatButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop<String>(context, 'OK'),
          )
        ],
      ),
    ).then<void>((value) => _resultDeletionAlert(value));
  }

  void _resultDeletionAlert(String value) {
    if(value == 'OK') {
      _mainReference.delete();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool deleteFlg = false;

    if(widget.documentSnapshot != null) {
      if(_data.user == null && _data.stuff == null) {
        _data.borrowOrLend = widget.documentSnapshot['borrowOrLend'];
        _data.user = widget.documentSnapshot['user'];
        _data.stuff = widget.documentSnapshot['stuff'];
        _data.date = widget.documentSnapshot['date'].toDate();
      }
      _mainReference = Firestore.instance
          .collection('users').document(firebaseUser.uid)
          .collection('transaction').document(widget.documentSnapshot.documentID);

      // 編集時のとき、アイコンを有効化
      deleteFlg = true;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('貸し借り入力'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
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
            onPressed: !deleteFlg ? null : () {
              print("削除ボタンを押しました");
              _confirmDeletionAlert();
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              print("共有ボタンを押しました");
              if(_formKey.currentState.validate()) {
                _formKey.currentState.save();
                Share.share(
                  "【" + (_data.borrowOrLend == "lend" ? "貸" : "借") + "】" +
                    _data.stuff + "\n期限： " + _data.date.toString().substring(0,10) +
                    "\n相手： " + _data.user + "\n#貸し借りメモ"
                );
              }
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
                onChanged: (String value) {
                  print("借りたをタッチしました");
                  _setLendOrRent(value);
                  print("貸し借りステータスを${_data.borrowOrLend}へ変更しました");
                },
              ),
              RadioListTile(
                value: "lend",
                groupValue: _data.borrowOrLend,
                title: Text("貸した"),
                onChanged: (String value) {
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
                onSaved: (String value) {
                  _data.user = value;
                },
                validator: (value) {
                  if(value.isEmpty) {
                    return '名前を入力してください';
                  }
                },
                initialValue: _data.user,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.business_center),
                  hintText: '借りたもの、貸したもの',
                  labelText: 'Loan',
                ),
                onSaved: (String value) {
                  _data.stuff = value;
                },
                validator: (value) {
                  if(value.isEmpty) {
                    return '対象のものを入力してください';
                  }
                },
                initialValue: _data.stuff,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("締め切り日：${_data.date.toString().substring(0,10)}"),
              ),
              RaisedButton(
                child: const Text("締め切り日変更"),
                onPressed: () {
                  print("締め切り日変更をタッチしました");
                  _selectTime(context).then((time) {
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