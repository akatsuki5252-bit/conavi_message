import 'package:flutter/material.dart';

class TestNavigationA extends StatefulWidget {
  const TestNavigationA({Key? key}) : super(key: key);

  @override
  State<TestNavigationA> createState() => _TestNavigationAState();
}

class _TestNavigationAState extends State<TestNavigationA> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画面A'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: TextButton(
          onPressed: () async {
            var result = await Navigator.push(context,
              MaterialPageRoute(
                  builder: (context) => const TestNavigationB()
              ),
            );
            print(result);
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
          ),
          child: const Text('画面Bへ移動',style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class TestNavigationB extends StatefulWidget {
  const TestNavigationB({Key? key}) : super(key: key);

  @override
  State<TestNavigationB> createState() => _TestNavigationBState();
}

class _TestNavigationBState extends State<TestNavigationB> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画面B'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () async {
                var result = await Navigator.push(context,
                  MaterialPageRoute(
                      builder: (context) => const TestNavigationC()
                  ),
                );
                if(result != null){
                  print(result);
                  Navigator.pop(context,'B2');
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
              ),
              child: const Text('画面Cへ移動',style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context,'B');
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
              ),
              child: const Text('画面Aへ戻る',style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class TestNavigationC extends StatefulWidget {
  const TestNavigationC({Key? key}) : super(key: key);

  @override
  State<TestNavigationC> createState() => _TestNavigationCState();
}

class _TestNavigationCState extends State<TestNavigationC> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画面C'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context,'C');
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
              ),
              child: const Text('画面Aへ戻る',style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}