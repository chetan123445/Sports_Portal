import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart'; // Import the LoginPage
import 'IYSC.dart'; // Import the IYSCPage
import 'Events.dart'; // Import the EventsPage
import 'GC.dart'; // Import the GCPage
import 'IRCC.dart'; // Import the IRCCPage
import 'PHL.dart'; // Import the PHLPage
import 'BasketBrawl.dart'; // Import the BasketBrawlPage
import 'Profile.dart'; // Import the ProfilePage
import 'main.dart'; // Import MainPage
import 'PlayersPage.dart'; // Import the PlayersPage
import 'constants.dart'; // Import the constants file
import 'dart:convert'; // Import for JSON decoding
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'MyEvents.dart'; // Import the MyEventsPage
import 'ManagingEvents.dart'; // Import the ManagingEventsPage
import 'NotificationsPage.dart'; // Import the NotificationsPage

void main() {
  runApp(SportsPortalApp());
}

class SportsPortalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(email: 'sports@iitrpr.ac.in'),
    );
  }
}

class HomePage extends StatelessWidget {
  final String email; // Add email parameter

  HomePage({required this.email}); // Update constructor

  final bool isLoggedIn = false; // Change this based on user authentication

  Future<String?> _fetchProfilePic(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile?email=$email'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'][0]['ProfilePic'] ?? null;
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  Future<List<dynamic>> _fetchNotifications(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?email=$email'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['notifications'] ?? [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
    return [];
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/notifications/mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  void _showNotifications(BuildContext context) async {
    await _markNotificationsAsRead();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsPage(email: email)),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch phone $phoneNumber';
    }
  }

  void _launchEmail(String emailAddress) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: emailAddress);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch email $emailAddress';
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text))
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied to clipboard: $text'),
              duration: Duration(seconds: 2),
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to copy: $error'),
              duration: Duration(seconds: 2),
            ),
          );
        });
  }

  // Update logout method
  Future<void> _logout(BuildContext context) async {
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // This removes all data from SharedPreferences

    // Navigate to main page and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => MainPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: [
          // Simplified notifications icon without count
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () => _showNotifications(context),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: FutureBuilder<String?>(
              future: _fetchProfilePic(email),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(Icons.person, color: Colors.white),
                  );
                } else if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.isNotEmpty) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(email: email),
                        ),
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click, // Change cursor to hand
                      child: CircleAvatar(
                        radius: 16, // Reduced radius to fit in the black box
                        backgroundImage: NetworkImage(
                          '$baseUrl/${snapshot.data}',
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(email: email),
                        ),
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click, // Change cursor to hand
                      child: CircleAvatar(
                        radius: 16, // Reduced radius to fit in the black box
                        backgroundImage: AssetImage(
                          'assets/profile.png',
                        ), // Default image
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.5,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 96.0,
              child: DrawerHeader(
                decoration: BoxDecoration(
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
                margin: EdgeInsets.all(0),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.sports_soccer),
              title: Text('Events'),
              onTap: () {
                // Navigate to EventsPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_kabaddi),
              title: Text('IYSC'),
              onTap: () {
                // Navigate to IYSCPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => IYSCPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_cricket),
              title: Text('IRCC'),
              onTap: () {
                // Navigate to IRCCPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => IRCCPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sports_hockey), // Hockey icon for PHL
              title: Text('PHL'),
              onTap: () {
                // Navigate to PHLPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PHLPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.sports_basketball,
              ), // Basketball icon for BasketballBrawl
              title: Text('BasketBrawl'),
              onTap: () {
                // Navigate to BasketBrawlPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BasketBrawlPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.emoji_events),
              title: Text('GC'),
              onTap: () {
                // Navigate to IYSCPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GCPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.event_available),
              title: Text('My Events'),
              onTap: () {
                // Navigate to MyEventsPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyEventsPage(email: email),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.manage_accounts),
              title: Text('Managing Events'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManagingEventsPage(email: email),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_album),
              title: Text('Gallery'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Players'),
              onTap: () {
                // Navigate to PlayersPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlayersPage()),
                );
              },
            ),
            Divider(thickness: 1),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Logout'),
                      content: Text('Are you sure you want to logout?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            _logout(context); // Perform logout
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
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
        child: Column(
          children: [
            SizedBox(height: 16),
            Center(
              child: Text(
                'IIT Ropar Sports Portal',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/pngsport.png', fit: BoxFit.cover),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Contact Us:',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('+916377418791')),
                        ),
                    onLongPress:
                        () => _copyToClipboard(context, '+916377418791'),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Icon(Icons.phone, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text('Contact', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('sports@iitrpr.ac.in')),
                        ),
                    onLongPress:
                        () => _copyToClipboard(context, 'sports@iitrpr.ac.in'),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Icon(Icons.email, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text('Email', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('https://www.iitrpr.ac.in')),
                        ),
                    onLongPress:
                        () => _copyToClipboard(
                          context,
                          'https://www.iitrpr.ac.in',
                        ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Icon(Icons.web, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text('Website', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
