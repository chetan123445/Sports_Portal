import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'constants.dart';
import 'services/favorite_service.dart';
import 'team_details_page.dart'; // Import TeamDetailsPage
import 'participants_page.dart'; // Import ParticipantsPage
import 'PlayerProfilePage.dart';
import 'IRCCEventDetailsPage.dart';
import 'PHLEventDetailsPage.dart';
import 'BasketBrawlEventDetailsPage.dart';
import 'IYSCEventDetailsPage.dart';
import 'GCEventDetailsPage.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: EventsPage()));
}

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> liveEvents = [];
  List<dynamic> upcomingEvents = [];
  List<dynamic> pastEvents = [];
  String searchQuery = '';
  bool showFavoritesOnly = false;
  Map<String, bool> favoriteStatus = {};
  String? userId;
  Map<String, dynamic> filters = {'eventType': [], 'gender': [], 'year': []};
  bool isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserId();
    await fetchEvents();
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

  Future<void> _loadFavoriteStatus(List<dynamic> events) async {
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
        String eventType = event['eventType'] ?? 'Unknown';
        print('Checking favorite for event: $eventId of type: $eventType');

        bool isFavorite = await FavoriteService.verifyFavorite(
          eventType,
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

  Future<void> _toggleFavorite(
    String eventId,
    String eventType,
    bool currentStatus,
  ) async {
    if (userId == null) return;

    bool success;
    if (currentStatus) {
      success = await FavoriteService.removeFavorite(
        eventType,
        eventId,
        userId!,
      );
    } else {
      success = await FavoriteService.addFavorite(eventType, eventId, userId!);
    }

    if (success && mounted) {
      setState(() {
        favoriteStatus[eventId] = !currentStatus;
      });
    }
  }

  Future<void> _showFilterDialog() async {
    Map<String, dynamic> tempFilters = Map.from(filters);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor:
                  Colors.transparent, // Make the dialog background transparent
              contentPadding: EdgeInsets.zero, // Remove default padding
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list, size: 24, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'Filter Events',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Type',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children:
                                ['IYSC', 'GC', 'IRCC', 'PHL', 'BasketBrawl']
                                    .map(
                                      (type) => FilterChip(
                                        label: Text(type),
                                        selected: tempFilters['eventType']
                                            .contains(type),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              tempFilters['eventType'].add(
                                                type,
                                              );
                                            } else {
                                              tempFilters['eventType'].remove(
                                                type,
                                              );
                                            }
                                          });
                                        },
                                        backgroundColor: Colors.orange.shade200,
                                        selectedColor: Colors.orange.shade400,
                                      ),
                                    )
                                    .toList(),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Gender',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children:
                                ['Male', 'Female', 'Neutral']
                                    .map(
                                      (gender) => FilterChip(
                                        label: Text(gender),
                                        selected: tempFilters['gender']
                                            .contains(gender),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              tempFilters['gender'].add(gender);
                                            } else {
                                              tempFilters['gender'].remove(
                                                gender,
                                              );
                                            }
                                          });
                                        },
                                        backgroundColor: Colors.orange.shade200,
                                        selectedColor: Colors.orange.shade400,
                                      ),
                                    )
                                    .toList(),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Year',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children:
                                ['2025', '2024', '2023', 'Older']
                                    .map(
                                      (year) => FilterChip(
                                        label: Text(year),
                                        selected: tempFilters['year'].contains(
                                          year,
                                        ),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              tempFilters['year'].add(year);
                                            } else {
                                              tempFilters['year'].remove(year);
                                            }
                                          });
                                        },
                                        backgroundColor: Colors.orange.shade200,
                                        selectedColor: Colors.orange.shade400,
                                      ),
                                    )
                                    .toList(),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    filters = {
                                      'eventType': [],
                                      'gender': [],
                                      'year': [],
                                    }; // Reset filters
                                    fetchEvents(); // Fetch all events
                                  });
                                  Navigator.pop(context); // Close the dialog
                                },
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    filters = tempFilters;
                                    fetchEvents(); // Re-fetch events with filters
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text('Apply'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    setState(() {
      isLoading = true; // Set loading to true when fetching starts
    });

    try {
      String query = '?';
      if (searchQuery.isNotEmpty) {
        query += 'search=$searchQuery&';
      }
      if (filters['eventType'].isNotEmpty) {
        query += 'eventType=${filters['eventType'].join(',')}&';
      }
      if (filters['gender'].isNotEmpty) {
        query += 'gender=${filters['gender'].join(',')}&';
      }
      if (filters['year'].isNotEmpty) {
        query += 'year=${filters['year'].join(',')}&';
      }

      final liveResponse = await http.get(
        Uri.parse('$baseUrl/live-events$query'),
      );
      final upcomingResponse = await http.get(
        Uri.parse('$baseUrl/upcoming-events$query'),
      );
      final pastResponse = await http.get(
        Uri.parse('$baseUrl/past-events$query'),
      );

      if (liveResponse.statusCode == 200 &&
          upcomingResponse.statusCode == 200 &&
          pastResponse.statusCode == 200) {
        if (mounted) {
          setState(() {
            liveEvents = json.decode(liveResponse.body);
            upcomingEvents = json.decode(upcomingResponse.body);
            pastEvents = json.decode(pastResponse.body);
            isLoading = false; // Set loading to false when fetch completes
          });
        }

        // Load favorites after events are loaded
        await _loadFavoriteStatus(liveEvents);
        await _loadFavoriteStatus(upcomingEvents);
        await _loadFavoriteStatus(pastEvents);
      }
    } catch (error) {
      print('Error fetching events: $error');
      if (mounted) {
        setState(() {
          isLoading = false; // Set loading to false even if there's an error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.star,
              color: showFavoritesOnly ? Colors.yellow : Colors.grey,
              size: 30,
            ),
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list, size: 30),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Live'), Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search), // Added search icon
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  fetchEvents();
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEventsList(context, liveEvents, isLive: true),
                _buildEventsList(context, upcomingEvents),
                _buildEventsList(context, pastEvents),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(
    BuildContext context,
    List<dynamic> events, {
    bool isLive = false,
  }) {
    // Show loading indicator while loading
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading events...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Filter events if showFavoritesOnly is true
    var filteredEvents =
        showFavoritesOnly
            ? events
                .where((event) => favoriteStatus[event['_id']] ?? false)
                .toList()
            : events;

    // Only show "No events found" when not loading and there are no events
    if (!isLoading && filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              showFavoritesOnly
                  ? 'No favorite events found'
                  : 'No events found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          return _buildEventCard(
            context,
            event, // Pass the entire event object
            event['team1'] ?? 'Team 1',
            event['team2'] ?? 'Team 2',
            event['date']?.split('T')[0] ?? 'No Date',
            event['time'] ?? 'No Time',
            event['type'] ?? 'No Type',
            event['gender'] ?? 'Unknown',
            event['venue'] ?? 'No Venue',
            event['eventType'] ?? 'No Event Type',
            isLive,
            event['_id'], // Pass the event ID
          );
        },
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    Map<String, dynamic> event,
    String team1,
    String team2,
    String date,
    String time,
    String type,
    String gender,
    String venue,
    String eventType,
    bool isLive,
    String eventId,
  ) {
    bool isFavorite = favoriteStatus[eventId] ?? false;

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
        padding: const EdgeInsets.symmetric(
          vertical: 6.0,
          horizontal: 8.0,
        ), // Reduced padding
        child: Stack(
          children: [
            // Event Type in the center of the box
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
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
            Column(
              mainAxisSize: MainAxisSize.min, // Ensures a minimal height layout
              children: [
                SizedBox(height: 20.0), // Adjust spacing for eventType
                if (['IYSC', 'IRCC', 'PHL', 'BasketBrawl'].contains(eventType))
                  Column(
                    children: [
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
                                            title: Text(
                                              'Team Details Not Available',
                                            ),
                                            content: Text(
                                              'Team member details for "$team1" have not been added yet.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
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
                            "vs",
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
                                            title: Text(
                                              'Team Details Not Available',
                                            ),
                                            content: Text(
                                              'Team member details for "$team2" have not been added yet.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
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
                      SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children:
                            (event['players'] ?? []).map<Widget>((player) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(5.0),
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Text(
                                  player,
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                SizedBox(height: 4.0),

                // Date & Time Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),

                // Type & Gender Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      gender,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

                // Add description before the buttons if it exists
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

                // Add Event Managers, Event Details and Match Result buttons in a Row
                SizedBox(height: 12.0),
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
                        // Special handling for IYSC specific event types
                        if (eventType == 'IYSC' &&
                            [
                              'field athletics',
                              'weightlifting',
                              'powerlifting',
                            ].contains(
                              event['type']?.toString().toLowerCase(),
                            )) {
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
                                        Icon(
                                          Icons.info,
                                          size: 40,
                                          color: Colors.black,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Pool System Information',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Players in this event have been divided into two pools for preliminary rounds.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(height: 16),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text('Close'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          );
                        } else {
                          // Original navigation logic for other event types
                          if (eventType == 'IRCC') {
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
                          } else if (eventType == 'PHL') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PHLEventDetailsPage(
                                      event: event,
                                      isReadOnly: true,
                                    ),
                              ),
                            );
                          } else if (eventType == 'BasketBrawl') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BasketBrawlEventDetailsPage(
                                      event: event,
                                      isReadOnly: true,
                                    ),
                              ),
                            );
                          } else if (eventType == 'IYSC') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => IYSCEventDetailsPage(
                                      event: event,
                                      isReadOnly: true,
                                    ),
                              ),
                            );
                          } else if (eventType == 'GC') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => GCEventDetailsPage(
                                      event: event,
                                      isReadOnly: true,
                                    ),
                              ),
                            );
                          }
                        }
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
                          } else {
                            // Special handling for different event types
                            if (eventType == 'IRCC' ||
                                (eventType == 'IYSC' &&
                                    event['type']?.toLowerCase() ==
                                        'cricket')) {
                              message = _getCricketMatchResult(
                                event['team1'],
                                event['team2'],
                                event['team1Score'],
                                event['team2Score'],
                                event['winner'],
                              );
                            } else if (eventType == 'PHL') {
                              message = _getPHLMatchResult(
                                event['team1'],
                                event['team2'],
                                event['team1Goals'],
                                event['team2Goals'],
                                event['winner'],
                              );
                            } else if (eventType == 'BasketBrawl') {
                              message = _getBasketBrawlMatchResult(
                                event['team1'],
                                event['team2'],
                                event['team1Score'],
                                event['team2Score'],
                                event['winner'],
                              );
                            } else if (eventType == 'IYSC' &&
                                event['team1Score']?['roundHistory'] != null) {
                              // For IYSC round-based games
                              message = _getIYSCRoundBasedResult(
                                event['team1'],
                                event['team2'],
                                event['team1Score'],
                                event['team2Score'],
                                event['winner'],
                              );
                            } else {
                              message = '${event['winner']} won this match!';
                            }
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
                SizedBox(height: 4.0),

                // Favorite Icon, View Participants (for GC), & Blinking Live Indicator in Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.yellow : null,
                        size: 20, // Reduced icon size
                      ),
                      onPressed:
                          () => _toggleFavorite(eventId, eventType, isFavorite),
                    ),
                    if (eventType == 'GC') // Show only for "GC" events
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (event['participants'] == null ||
                                event['participants'].isEmpty) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Participants Not Available'),
                                      content: Text(
                                        'No participants have been added for this event yet.',
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
                                      (context) => ParticipantsPage(
                                        eventId: eventId, // Pass event ID
                                      ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            'View Participants',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    if (isLive) BlinkingLiveIndicator(), // Blinking Red Circle
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BlinkingLiveIndicator extends StatefulWidget {
  @override
  _BlinkingLiveIndicatorState createState() => _BlinkingLiveIndicatorState();
}

class _BlinkingLiveIndicatorState extends State<BlinkingLiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
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

  // If team batting second (team2) has more runs, they won by wickets
  if (team2Runs > team1Runs) {
    return '$team2 won by ${10 - team2Wickets} wickets';
  }
  // If team batting first (team1) has more runs, they won by runs
  else if (team1Runs > team2Runs) {
    return '$team1 won by ${team1Runs - team2Runs} runs';
  }

  return '$winner won this match!';
}

String _getPHLMatchResult(
  String team1,
  String team2,
  dynamic team1Goals,
  dynamic team2Goals,
  String winner,
) {
  final goals1 = team1Goals ?? 0;
  final goals2 = team2Goals ?? 0;

  if (goals1 == goals2) {
    return 'Match ended in a draw';
  }

  return goals2 > goals1
      ? '$team2 won by ${goals2 - goals1} goals'
      : '$team1 won by ${goals1 - goals2} goals';
}

String _getBasketBrawlMatchResult(
  String team1,
  String team2,
  dynamic team1Score,
  dynamic team2Score,
  String winner,
) {
  // Access team scores directly since they are stored as numbers
  final score1 = num.tryParse(team1Score?.toString() ?? '0') ?? 0;
  final score2 = num.tryParse(team2Score?.toString() ?? '0') ?? 0;

  if (score1 == score2) {
    return 'Match ended in a draw';
  }

  return score2 > score1
      ? '$team2 won by ${score2 - score1} points'
      : '$team1 won by ${score1 - score2} points';
}

String _getIYSCRoundBasedResult(
  String team1,
  String team2,
  Map<String, dynamic> team1Score,
  Map<String, dynamic> team2Score,
  String winner,
) {
  // Extract round histories
  final team1Rounds = (team1Score['roundHistory'] as List<dynamic>?) ?? [];
  final team2Rounds = (team2Score['roundHistory'] as List<dynamic>?) ?? [];

  // Count rounds won by each team
  int team1RoundsWon = 0;
  int team2RoundsWon = 0;

  for (int i = 0; i < team1Rounds.length; i++) {
    final team1RoundScore = team1Rounds[i]['score'] ?? 0;
    final team2RoundScore = team2Rounds[i]['score'] ?? 0;

    if (team1RoundScore > team2RoundScore) {
      team1RoundsWon++;
    } else if (team2RoundScore > team1RoundScore) {
      team2RoundsWon++;
    }
  }

  // Determine winner based on rounds won
  if (team1RoundsWon == team2RoundsWon) {
    return 'Match ended in a draw';
  }

  return team1RoundsWon > team2RoundsWon
      ? '$team1 won by winning $team1RoundsWon rounds to $team2RoundsWon'
      : '$team2 won by winning $team2RoundsWon rounds to $team1RoundsWon';
}
