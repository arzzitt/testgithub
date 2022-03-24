import 'package:flutter/material.dart';
import 'package:testgithub/utils/homepage.dart';

void main() {
  runApp(MaterialApp(
    title: 'Your title',
    home: MyApp(),));}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
              title: Text('Screen'),
              backgroundColor: Colors.teal,
            ),
            body: Container(
              padding: EdgeInsets.symmetric(vertical: 100.0,horizontal: 100.0),
              color: Colors.transparent,
              child: ElevatedButton(
                  child: const Text('Enter'),
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.teal),
                      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 15.0,horizontal: 30.0))
                  ),
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context){
                      return CallPage();
                    }));
                  }
              ),
            ),
    );
  }
}
