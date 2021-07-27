import 'package:flutter/material.dart';
import 'package:flutter_sandbox/call/call_page.dart';
import 'package:flutter_sandbox/shared/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CallPage()),
            );
          },
          style: ButtonStyle(
            elevation: MaterialStateProperty.all(0),
            minimumSize: MaterialStateProperty.all(Size(339, 50)),
            backgroundColor: MaterialStateProperty.all(AppColors.purple),
          ),
          child: Text('Join'),
        ),
      ),
    );
  }
}
