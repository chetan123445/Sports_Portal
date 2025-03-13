import 'package:flutter/material.dart';

class IYSCEventsPage extends StatelessWidget {
  final List<dynamic> events;

  IYSCEventsPage({required this.events});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 50),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 79, 188, 247),
                Color.fromARGB(255, 142, 117, 205),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              'IYSC Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            events.isEmpty
                ? Center(child: Text('No events available'))
                : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventCard(
                      context,
                      event['team1'] ?? 'Team 1',
                      event['team2'] ?? 'Team 2',
                      event['date']?.split('T')[0] ?? 'No Date',
                      event['time'] ?? 'No Time',
                      event['type'] ?? 'No Type',
                      event['gender'] ?? 'Unknown',
                      event['venue'] ?? 'No Venue',
                    );
                  },
                ),
      ),
    );
  }

 Widget _buildEventCard(
  BuildContext context,
  String team1,
  String team2,
  String date,
  String time,
  String type,
  String gender,
  String venue,
) {
  bool isFavorite = false; // Replace with actual favorite status

  return Card(
    elevation: 3.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(8.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade200,
            Colors.blue.shade200,
            Colors.pink.shade100,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Teams Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  team1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'v/s',
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  team2,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.0), // Reduced spacing

          // Date and Time Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(date, style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
              Text(time, style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 4.0),

          // Type and Gender Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(gender, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 4.0),

          // Venue Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'Venue: $venue',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 4.0),

          // Favorite Button
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.yellow : null,
                size: 18, // Reduced icon size
              ),
              onPressed: () {
                // Handle favorite toggle
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}

