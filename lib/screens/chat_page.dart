import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testapp/services/database_services.dart';
import 'package:testapp/widgets/message_tile.dart';

import 'geomap_page.dart';

class ChatPage extends StatefulWidget {
  final String groupId;
  final String userName;
  final String groupName;
  final String uid;

  ChatPage({this.groupId, this.userName, this.groupName, this.uid});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Stream<QuerySnapshot> _chats;
  TextEditingController messageEditingController = new TextEditingController();
  bool isWriting = false;

  Widget _chatMessages() {
    return StreamBuilder(
      stream: _chats,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  return MessageTile(
                    message: snapshot.data.docs[index].data()["messages"],
                    sender: snapshot.data.docs[index].data()["sender"],
                    sentByMe: widget.userName ==
                        snapshot.data.docs[index].data()["sender"],
                  );
                })
            : Container();
      },
    );
  }

  _sendMessage() {
    if (messageEditingController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "message": messageEditingController.text,
        "sender": widget.userName,
        'time': DateTime.now().millisecondsSinceEpoch,
      };
      print(messageEditingController.text);

      DatabaseService().sendMessage(widget.groupId, chatMessageMap);

      setState(() {
        isWriting = false;
      });
      messageEditingController.text = "";
    }
  }

  @override
  void initState() {
    super.initState();
    DatabaseService().getChats(widget.groupId).then((val) {
      // print(val);
      setState(() {
        _chats = val;
        DatabaseService().savelocation(widget.uid, widget.groupId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              Icons.map,
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => MyMap()));
            },
          )
        ],
        title: Text(widget.groupName, style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black87,
        elevation: 0.0,
      ),
      body: Container(
        child: Stack(
          children: <Widget>[
            _chatMessages(),
            // Container(),
            Container(
              alignment: Alignment.bottomCenter,
              width: MediaQuery.of(context).size.width,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                color: Colors.white,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageEditingController,
                        style: TextStyle(color: Colors.blueGrey),
                        decoration: InputDecoration(
                            hintText: "Send a message ...",
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            border: InputBorder.none),
                      ),
                    ),
                    SizedBox(width: 12.0),
                    GestureDetector(
                      onTap: () {
                        _sendMessage();
                      },
                      child: Container(
                        height: 50.0,
                        width: 50.0,
                        decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(50)),
                        child: Center(
                            child: Icon(Icons.send, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
