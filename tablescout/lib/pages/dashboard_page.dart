import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    var padHeight = (MediaQuery.sizeOf(context).height * 0.2) / 3;
    var padWidth = MediaQuery.sizeOf(context).width * 0.1;
    return Container( // Creates stack for events and floor view containers

      child: Column(
        children: [
          Container( // Ongoing Events
            height: MediaQuery.sizeOf(context).height * 0.4,
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(padWidth, padHeight, padWidth, padHeight / 2),
            color: Colors.grey[200],
            child: Center(
              child: Text('Ongoing Events'),
            ),
            //get number of events
            //display ongoing events in columns
            //needs to be scrollable

          ),
          Container( // Floor View
            color: Colors.grey[300],
            height: MediaQuery.sizeOf(context).height * 0.4,
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(padWidth, padHeight / 2, padWidth, padHeight),
              child: Center(
                child: Text('Floor View'),
              ),
              //get store floor view

          ),
        ],
      ),
    );
  }
}
