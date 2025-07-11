import 'package:chatapp_final/helper/helper_function.dart';
import 'package:chatapp_final/pages/auth/login_page.dart';
import 'package:chatapp_final/pages/profile_page.dart';
import 'package:chatapp_final/pages/search_page.dart';
import 'package:chatapp_final/pages/personal_chat_menu.dart';
import 'package:chatapp_final/service/auth_service.dart';
import 'package:chatapp_final/service/database_service.dart';
import 'package:chatapp_final/widgets/group_tile.dart';
import 'package:chatapp_final/widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";
  String email = "";
  AuthService authService = AuthService();
  Stream? groups;
  bool _isLoading = false;
  String groupName = "";

  @override
  void initState() {
    super.initState();
    gettingUserData();
  }

  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  String getName(String res) {
    return res.substring(res.indexOf("_") + 1);
  }

  gettingUserData() async {
    await HelperFunctions.getUserEmailFromSF().then((value) {
      setState(() {
        email = value!;
      });
    });
    await HelperFunctions.getUserNameFromSF().then((val) {
      setState(() {
        userName = val!;
      });
    });
    await DatabaseService(
      uid: FirebaseAuth.instance.currentUser!.uid,
    ).getUserGroups().then((snapshot) {
      setState(() {
        groups = snapshot;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              nextScreen(context, const SearchPage());
            },
            icon: const Icon(Icons.search),
          ),
        ],
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Groups",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 27,
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 50),
          children: <Widget>[
            Icon(Icons.account_circle, size: 150, color: Colors.grey[700]),
            const SizedBox(height: 15),
            Text(
              userName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Divider(height: 2),
            ListTile(
              onTap: () {},
              selectedColor: Theme.of(context).primaryColor,
              selected: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 5,
              ),
              leading: const Icon(Icons.group),
              title: const Text("Groups", style: TextStyle(color: Colors.black)),
            ),
            ListTile(
              onTap: () {
                nextScreenReplace(
                  context,
                  ProfilePage(userName: userName, email: email),
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.person),
              title: const Text("Profile", style: TextStyle(color: Colors.black)),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonalChatMenu(
                      currentUserId: FirebaseAuth.instance.currentUser!.uid,
                    ),
                  ),
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.chat),
              title: const Text("Personal Chats", style: TextStyle(color: Colors.black)),
            ),
            ListTile(
              onTap: () async {
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.cancel, color: Colors.red),
                        ),
                        IconButton(
                          onPressed: () async {
                            await authService.signOut();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                                  (route) => false,
                            );
                          },
                          icon: const Icon(Icons.done, color: Colors.green),
                        ),
                      ],
                    );
                  },
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: const Icon(Icons.exit_to_app),
              title: const Text("Logout", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
      body: groupList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          popUpDialog(context);
        },
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  popUpDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: ((context, setState) {
            return AlertDialog(
              title: const Text("Create a group", textAlign: TextAlign.left),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoading
                      ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                      : TextField(
                    onChanged: (val) {
                      setState(() {
                        groupName = val;
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (groupName.isNotEmpty) {
                      setState(() {
                        _isLoading = true;
                      });
                      await DatabaseService(
                        uid: FirebaseAuth.instance.currentUser!.uid,
                      ).createGroup(
                        userName,
                        FirebaseAuth.instance.currentUser!.uid,
                        groupName,
                      );
                      _isLoading = false;
                      Navigator.of(context).pop();
                      showSnackbar(context, Colors.green, "Group created successfully.");
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                  child: const Text("CREATE"),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget groupList() {
    return StreamBuilder(
      stream: groups,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && snapshot.data['groups'] != null && snapshot.data['groups'].length != 0) {
          return ListView.builder(
            itemCount: snapshot.data['groups'].length,
            itemBuilder: (context, index) {
              int reverseIndex = snapshot.data['groups'].length - index - 1;
              return GroupTile(
                groupId: getId(snapshot.data['groups'][reverseIndex]),
                groupName: getName(snapshot.data['groups'][reverseIndex]),
                userName: snapshot.data['fullName'],
              );
            },
          );
        } else {
          return noGroupWidget();
        }
      },
    );
  }

  Widget noGroupWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              popUpDialog(context);
            },
            child: Icon(Icons.add_circle, color: Colors.grey[700], size: 75),
          ),
          const SizedBox(height: 20),
          const Text(
            "You've not joined any groups, tap on the add icon to create a group or also search from top search button.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
