import 'package:flutter/material.dart';
import 'package:testapp/screens/chat_page.dart';

class GroupTile extends StatelessWidget {
  final String userName;
  final String groupId;
  final String groupName;

  GroupTile({this.userName, this.groupId, this.groupName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatPage(
                      groupId: groupId,
                      userName: userName,
                      groupName: groupName,
                    )));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 30.0),
        child: ListTile(
          leading: CircleAvatar(
            radius: 30.0,
            backgroundColor: Colors.blueAccent,
            child: Text(groupName.substring(0, 1).toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white)),
          ),
          title: Text(groupName, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle:
              Text("Joined as $userName", style: TextStyle(fontSize: 13.0)),
        ),
      ),
    );
  }
}
