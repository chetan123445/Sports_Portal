import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async'; // Add this import for blinking animation
import 'constants.dart';
import 'services/favorite_service.dart';
import 'team_details_page.dart'; // Import the new page
import 'IRCCEventDetailsPage.dart';
import 'PlayerProfilePage.dart'; // Import the player profile page

class IRCCPage extends StatefulWidget {
  @override
  _IRCCPageState createState() => _IRCCPageState();
}

class _IRCCPageState extends State<IRCCPage> {
  List<dynamic> events = [];
  bool isLoading = true;
  Map<String, bool> favoriteStatus = {};
  String? userId;
  String _searchQuery = ''; // Add search query state
  bool _isBlinking = true; // Add blinking state

  @override
  void initState() {
    super.initState();
    _startBlinking(); // Start blinking animation
    _initializeData(); // Initialize data
  }

  void _startBlinking() {
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
      } else {
        setState(() {
          _isBlinking = !_isBlinking;
        });
      }
    });
  }

  Future<void> _initializeData() async {
    await _getUserId(); // Get userId first
    await _fetchIRCCEvents(); // Then fetch events
    await _loadFavoriteStatus(); // Finally load favorites
  }

  Future<void> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      print('Retrieved userId from SharedPreferences: $storedUserId');

      if (storedUserId != null && storedUserId.isNotEmpty) {
        setState(() {
          userId = storedUserId;
        });
      } else {
        print('No valid user ID found in SharedPreferences');
      }
    } catch (e) {
      print('Error getting userId: $e');
    }
  }

  Future<void> _fetchIRCCEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-ircc-events?type=Cricket'),
      );
      print('Fetching IRCC events...');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final fetchedEvents = responseBody['data'];
        if (fetchedEvents is List) {
          setState(() {
            events = fetchedEvents;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    if (userId == null || userId!.isEmpty || events.isEmpty) {
      print(
        'Cannot load favorites: userId=$userId, events.length=${events.length}',
      );
      return;
    }

    print('Loading favorites for user: $userId');
    try {
      for (var event in events) {
        if (event['_id'] == null) continue;

        String eventId = event['_id'];
        print('Checking favorite for event: $eventId');

        bool isFavorite = await FavoriteService.verifyFavorite(
          'IRCC',
          eventId,
          userId!,
        );
        print('Favorite status for $eventId: $isFavorite');

        if (mounted) {
          setState(() {
            favoriteStatus[eventId] = isFavorite;
          });
        }
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite(String eventId, bool currentStatus) async {
    if (userId == null) return;

    bool success;
    if (currentStatus) {
      success = await FavoriteService.removeFavorite('IRCC', eventId, userId!);
    } else {
      success = await FavoriteService.addFavorite('IRCC', eventId, userId!);
    }

    if (success && mounted) {
      setState(() {
        favoriteStatus[eventId] = !currentStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents =
        events.where((event) {
          final query = _searchQuery.toLowerCase();
          return (event['gender']?.toLowerCase() ==
                  query) || // Exact match for gender
              (event['date'] ?? '').toLowerCase().contains(query) ||
              (event['time'] ?? '').toLowerCase().contains(query) ||
              (event['team1'] ?? '').toLowerCase().contains(query) ||
              (event['team2'] ?? '').toLowerCase().contains(query) ||
              (event['venue'] ?? '').toLowerCase().contains(query) ||
              (event['type'] ?? '').toLowerCase().contains(query);
        }).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
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
              'IRCC Cricket Matches',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by gender, date, time, teams and Venue...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredEvents.isEmpty
                    ? Center(
                      child: Text('No cricket matches match your search'),
                    )
                    : ListView.builder(
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        return _buildEventCard(context, event);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    String team1 = event['team1'] ?? 'Team 1';
    String team2 = event['team2'] ?? 'Team 2';
    String date = event['date']?.split('T')[0] ?? 'No Date';
    String time = event['time'] ?? 'No Time';
    String type = event['type'] ?? 'No Type';
    String gender = event['gender'] ?? 'Unknown';
    String venue = event['venue'] ?? 'No Venue';
    String eventId = event['_id'] ?? '';
    String eventType = event['eventType'] ?? 'No Type';
    bool isFavorite = favoriteStatus[eventId] ?? false;
    bool isLive = date == DateTime.now().toIso8601String().split('T')[0];

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2.0),
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
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      eventType,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (event['team1Details'] == null) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Team Details Not Available'),
                                      content: Text(
                                        'Team member details for "${event['team1'] ?? 'Team 1'}" have not been added yet.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text('OK'),
                                        ),
                                      ],
                                    ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TeamDetailsPage(
                                        teamId: event['team1Details'],
                                      ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            team1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'v/s',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (event['team2Details'] == null) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Team Details Not Available'),
                                      content: Text(
                                        'Team member details for "${event['team2'] ?? 'Team 2'}" have not been added yet.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text('OK'),
                                        ),
                                      ],
                                    ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TeamDetailsPage(
                                        teamId: event['team2Details'],
                                      ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            team2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),
                Column(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      gender,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Venue: $venue',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 4.0),

                // Add description if available
                if (event['description'] != null &&
                    event['description'].isNotEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      event['description'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                SizedBox(height: 12.0),
                // Buttons Row
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.people, size: 16),
                      label: Text('Event Managers'),
                      onPressed: () {
                        if (event['eventManagers'] == null ||
                            (event['eventManagers'] as List).isEmpty) {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('No Event Managers'),
                                  content: Text(
                                    'No event managers have been assigned to this event.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                          );
                          return;
                        }

                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                backgroundColor: Colors.transparent,
                                contentPadding: EdgeInsets.zero,
                                content: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
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
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Event Managers',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      ...event['eventManagers']
                                          .map<Widget>(
                                            (manager) => ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    Colors.blue.shade100,
                                                child: Icon(
                                                  Icons.person,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              title: Text(
                                                manager['name'] ?? 'Unknown',
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          context,
                                                        ) => PlayerProfilePage(
                                                          playerName:
                                                              manager['name'],
                                                          playerEmail:
                                                              manager['email'],
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                          .toList(),
                                      SizedBox(height: 16),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Close'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade200,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.info_outline, size: 16),
                      label: Text('Event Details'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => IRCCEventDetailsPage(
                                  event: event,
                                  isReadOnly: true,
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade200,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.emoji_events, size: 16),
                      label: Text('View Result'),
                      onPressed: () {
                        String message = '';
                        DateTime eventDate = DateTime.parse(date);
                        DateTime now = DateTime.now();

                        if (eventDate.isAfter(now)) {
                          message = 'Match has not started yet';
                        } else if (eventDate.year == now.year &&
                            eventDate.month == now.month &&
                            eventDate.day == now.day) {
                          message =
                              'Match is live, results will be updated soon';
                        } else {
                          if (event['winner'] == null ||
                              event['winner'].isEmpty) {
                            message = 'No results available';
                          } else if (event['winner'] == 'Draw') {
                            message = 'Match ended in a draw';
                          } else {
                            message = _getCricketMatchResult(
                              event['team1'],
                              event['team2'],
                              event['team1Score'],
                              event['team2Score'],
                              event['winner'],
                            );
                          }
                        }

                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text('Match Status'),
                                content: Text(message),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade200,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.yellow : null,
                    ),
                    onPressed: () => _toggleFavorite(eventId, isFavorite),
                  ),
                ),
              ],
            ),
          ),
          if (isLive)
            Positioned(
              bottom: 8.0,
              left: 8.0,
              child: AnimatedOpacity(
                opacity: _isBlinking ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventManagerCard(Map<String, dynamic> manager) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PlayerProfilePage(
                    playerName: manager['name'] ?? 'Unknown',
                    playerEmail: manager['email'] ?? '',
                  ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.orange.shade200,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.black),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person, color: Colors.blue),
              ),
              SizedBox(width: 8),
              Text(
                manager['name'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCricketMatchResult(
    String team1,
    String team2,
    Map<String, dynamic> team1Score,
    Map<String, dynamic> team2Score,
    String winner,
  ) {
    final team1Runs = team1Score['runs'] ?? 0;
    final team2Runs = team2Score['runs'] ?? 0;
    final team2Wickets = team2Score['wickets'] ?? 0;

    if (team1Runs == team2Runs) {
      return 'Match ended in a draw';
    }

    if (team2Runs > team1Runs) {
      return '$team2 won by ${10 - team2Wickets} wickets';
    } else if (team1Runs > team2Runs) {
      return '$team1 won by ${team1Runs - team2Runs} runs';
    }

    return '$winner won this match!';
  }
}
