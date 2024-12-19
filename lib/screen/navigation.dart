import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:task2/screen/dashboard.dart';
import 'package:task2/screen/monthly_hourly.dart';

class Navigation extends StatefulWidget {
  final int? index;
  Navigation({super.key, this.index});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    Dashboard(),
    MonthlyHourly(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index != null ? widget.index! : 0;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Exit App'),
                content: Text('Do you really want to exit the app?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Yes'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Color.fromARGB(255, 185, 185, 185).withOpacity(.1),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
              child: GNav(
                rippleColor: Color.fromARGB(255, 65, 116, 255),
                hoverColor: Color.fromARGB(255, 118, 155, 255),
                gap: 10,
                activeColor: const Color.fromARGB(255, 255, 255, 255),
                iconSize: 25,
                padding: EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                duration: Duration(milliseconds: 100),
                tabBackgroundColor: Color.fromARGB(255, 66, 77, 228),
                color: Colors.black,
                tabs: const [
                  GButton(
                    icon: LineIcons.home,
                    text: 'Current',
                  ),
                  GButton(
                    icon: LineIcons.calendar,
                    text: 'Hourly & Monthly',
                  ),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
