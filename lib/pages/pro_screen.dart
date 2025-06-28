import 'package:flutter/material.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Pro Screen'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                margin: const EdgeInsets.all(5),
                height: 100,
                width: 100,
                color: Colors.blue,
                duration: const Duration(milliseconds: 500),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(margin: EdgeInsets.all(5), child: Text('AB')),
                  Switch(
                    value: true,
                    onChanged: (newValue) {},
                    activeColor: Colors.lightBlue,
                    inactiveThumbColor: Colors.amber,
                  ),
                  Container(margin: EdgeInsets.all(5), child: Text('LB')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
