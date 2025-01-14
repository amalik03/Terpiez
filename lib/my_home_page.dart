import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:terpiez/finder_tab.dart';
import 'package:terpiez/list_tab.dart';
import 'package:terpiez/main.dart';
import 'package:terpiez/stats_tab.dart';
import 'package:terpiez/user_state_model.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.index});
  final String title;
  final int index;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _startApp();
    Provider.of<UserState>(context, listen: false).reqLocPerms();
  }

  Future<void> _startApp() async {
    await _loginCheck();
    await Provider.of<UserState>(context, listen: false).loadUserData();
  }

  Future<void> _loginCheck() async {
    String? username = await storage.read(key: "username");
    String? password = await storage.read(key: "password");
    if (username == null || password == null) {
      _showLoginScreen();
    }
  }

  void _showLoginScreen() {
    final GlobalKey<FormState> _fKey = GlobalKey<FormState>();
    String? username = '';
    String? password = '';

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
              title: Text("Sign In"),
              content: SingleChildScrollView(
                child: Form(
                  key: _fKey,
                  child: ListBody(children: <Widget>[
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Username"),
                      autocorrect: false,
                      obscureText: false,
                      autofocus: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'No Username provided';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        username = newValue;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Password"),
                      autocorrect: false,
                      obscureText: true,
                      autofocus: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'No Password provided';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        password = newValue;
                      },
                    ),
                  ]),
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                    child: Text("Sign In"),
                    onPressed: () async {
                      if (_fKey.currentState!.validate()) {
                        _fKey.currentState!.save();
                        await storage.write(key: 'username', value: username);
                        await storage.write(key: 'password', value: password);
                        Navigator.of(context).pop();
                      }
                    }),
              ]);
        });
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Data Deletion'),
          content: Text(
              'Are you sure you want to clear all data? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                await Provider.of<UserState>(context, listen: false)
                    .clearData();
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        initialIndex: widget.index,
        child: Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(widget.title),
                bottom: const TabBar(tabs: [
                  Tab(icon: Icon(Icons.auto_graph), text: "Stats"),
                  Tab(icon: Icon(Icons.search), text: "Finder"),
                  Tab(icon: Icon(Icons.filter_list), text: "List")
                ])),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.red,
                    ),
                    child: Text(
                      'Preferences',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Consumer<UserState>(
                    builder: (context, userState, child) {
                      return SwitchListTile(
                        title: const Text('Enable Sounds'),
                        value: userState.soundSet,
                        onChanged: (bool newValue) {
                          print("SOUNDSET IN HOME PAGE: $soundSet");
                          userState.toggleSound(newValue);
                          setState(() {
                            userState.soundSet = newValue;
                          });
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Clear Data'),
                    onTap: () {
                      _confirmClearData(context);
                    },
                  ),
                ],
              ),
            ),
            body: const TabBarView(children: [
              StatsTab(),
              FinderTab(),
              ListTab(),
            ])),
      ),
    );
  }
}
