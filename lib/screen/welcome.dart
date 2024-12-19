import 'package:flutter/material.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Welcome',
                      style: TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.w900,
                          color: Color.fromARGB(255, 66, 77, 228)),
                    ),
                  ),
                  Expanded(
                    child: Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Image.asset('assets/logo.png')),
                  ),
                  Text(
                    'Weather Forecast',
                    style: TextStyle(
                      fontSize: 40.0,
                      fontWeight: FontWeight.w900,
                      color: Color.fromARGB(255, 120, 237, 255),
                    ),
                  ),
                  SizedBox(
                    height: 80,
                  ),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.height * 0.07,
                      child: ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                  Color.fromARGB(255, 120, 237, 255))),
                          onPressed: () {
                            Navigator.pushNamed(context, '/navigation');
                          },
                          child: Text(
                            "GET STARTED",
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ))),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
