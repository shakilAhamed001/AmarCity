// lib/screens/citizen/citizen_screen.dart

import 'package:flutter/material.dart';

class CitizenDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Citizen Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to the Citizen Dashboard',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Action for button tap
              },
              child: Text('View Your Profile'),
            ),
            ElevatedButton(
              onPressed: () {
                // Action for button tap
              },
              child: Text('Report an Issue'),
            ),
            ElevatedButton(
              onPressed: () {
                // Action for button tap
              },
              child: Text('Community Services'),
            ),
          ],
        ),
      ),
    );
  }
}