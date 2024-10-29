import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_recipe/background_image_container.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final user = FirebaseAuth.instance.currentUser!;

  //current user document id
  List<String> docIds = [];

  //get current user document id
  Future getDocId() async{
    await FirebaseFirestore.instance.collection('users').get().then(
          (snapshot) => snapshot.docs.forEach((document)
          {
            print(document.reference);
            docIds.add(document.reference.id);
          }),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recipedia',
          style: TextStyle(color: Colors.greenAccent[400]),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.greenAccent[400]),
      ),
      body: BackgroundContainer(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Hello user, signed in as: " + user.email!,
                ),
                MaterialButton(
                  onPressed: (){
                    FirebaseAuth.instance.signOut();
                  },
                  color: Colors.green,
                  child: Text("Sign Out"),
                ),
                Expanded(
                    child: FutureBuilder(
                      future: getDocId(),
                      builder: (context, snapshot){
                        return ListView.builder(
                          itemCount: docIds.length,
                          itemBuilder: (context, index){
                            return ListTile(
                              title: Text(docIds[index]),
                            );
                          },
                        );
                      },
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


