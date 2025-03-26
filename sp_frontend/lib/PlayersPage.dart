import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart';

class PlayersPage extends StatefulWidget {
  @override
  _PlayersPageState createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  List<Map<String, dynamic>> playersWithDetails = [];
  List<Map<String, dynamic>> filteredPlayers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchPlayers();
  }

  Future<void> fetchPlayers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all-players-from-teams'),
      );
      if (response.statusCode == 200) {
        final players = json.decode(response.body);
        setState(() {
          playersWithDetails = _groupPlayersByEmail(
            List<Map<String, dynamic>>.from(players),
          );
          filteredPlayers = playersWithDetails; // Initialize filtered list
          isLoading = false;
        });
      } else {
        print('Failed to fetch players');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching players: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _groupPlayersByEmail(
    List<Map<String, dynamic>> players,
  ) {
    final Map<String, Map<String, dynamic>> groupedPlayers = {};

    for (var player in players) {
      final email = player['email'] ?? '';
      if (email.isEmpty) continue;

      if (!groupedPlayers.containsKey(email)) {
        groupedPlayers[email] = {
          'name': player['name'] ?? 'Unknown',
          'email': email,
          'teamNames': [player['teamName'] ?? 'Unknown'],
        };
      } else {
        // Merge team names
        final existingPlayer = groupedPlayers[email];
        existingPlayer!['teamNames'].add(player['teamName'] ?? 'Unknown');

        // Take the longer name if names differ
        if ((player['name'] ?? '').length >
            (existingPlayer['name'] ?? '').length) {
          existingPlayer['name'] = player['name'];
        }
      }
    }

    // Convert grouped players back to a list
    return groupedPlayers.values
        .map(
          (player) => {
            'name': player['name'],
            'email': player['email'],
            'teamNames': List<String>.from(
              player['teamNames'],
            ), // Ensure List<String>
          },
        )
        .toList();
  }

  void _filterPlayers(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredPlayers = playersWithDetails;
      } else {
        filteredPlayers =
            playersWithDetails.where((player) {
              final name = player['name']?.toLowerCase() ?? '';
              final email = player['email']?.toLowerCase() ?? '';
              return name.contains(query.toLowerCase()) ||
                  email.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  Future<void> _showTeamDetails(String teamName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-team-details-by-name/$teamName'),
      );

      if (response.statusCode == 200) {
        final teamDetails = json.decode(response.body)['team'];
        if (teamDetails != null) {
          _showTeamDetailsDialog(teamDetails);
        } else {
          _showErrorDialog('Team not found');
        }
      } else {
        _showErrorDialog('Failed to fetch team details');
      }
    } catch (e) {
      print('Error fetching team details: $e');
      _showErrorDialog('Error fetching team details');
    }
  }

  void _showTeamDetailsDialog(Map<String, dynamic> teamDetails) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
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
            child: SingleChildScrollView(
              // Prevent overflow by making content scrollable
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Team Name: ',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${teamDetails['teamName']}',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Players:',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // Set background color to white
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(12.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            teamDetails['members'].length > 7
                                ? 400.0 // Limit height for scrolling if more than 7 players
                                : teamDetails['members'].length * 80.0 +
                                    20.0, // Adjust height dynamically
                      ),
                      child:
                          teamDetails['members'].length > 7
                              ? Scrollbar(
                                thumbVisibility: true,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: teamDetails['members'].length,
                                  itemBuilder: (context, index) {
                                    final member =
                                        teamDetails['members'][index];
                                    return _buildPlayerBox(index + 1, member);
                                  },
                                ),
                              )
                              : Column(
                                children:
                                    teamDetails['members']
                                        .asMap()
                                        .entries
                                        .map<Widget>((entry) {
                                          final index = entry.key + 1;
                                          final member = entry.value;
                                          return _buildPlayerBox(index, member);
                                        })
                                        .toList(), // Ensure List<Widget>
                              ),
                    ),
                  ),
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
    );
  }

  Widget _buildPlayerBox(int index, Map<String, dynamic> member) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(12.0),
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
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$index.', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              member['name'],
              style: TextStyle(fontWeight: FontWeight.bold),
              softWrap: true,
            ),
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              member['email'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTeamsDialog(String playerName, List<String> teamNames) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
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
            child: SingleChildScrollView(
              // Prevent overflow by making content scrollable
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Participating for Teams',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  teamNames.isEmpty
                      ? Text(
                        'No teams found for this player.',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      )
                      : Column(
                        children:
                            teamNames.asMap().entries.map((entry) {
                              final index = entry.key + 1; // Serial number
                              final teamName = entry.value;
                              return GestureDetector(
                                onTap: () => _showTeamDetails(teamName),
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 8.0),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors
                                            .orange
                                            .shade200, // Orange box color
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '$index. ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          teamName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Players')),
      body: Container(
        color: Colors.white, // Set the background color to white
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search), // Search icon
                ),
                onChanged: _filterPlayers,
              ),
            ),
            Expanded(
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : filteredPlayers.isEmpty
                      ? Center(child: Text('No players found'))
                      : ListView.builder(
                        padding: EdgeInsets.all(16.0),
                        itemCount: filteredPlayers.length,
                        itemBuilder: (context, index) {
                          final player = filteredPlayers[index];
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            padding: EdgeInsets.all(12.0),
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
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    player['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    player['email'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                ElevatedButton(
                                  onPressed:
                                      () => _showTeamsDialog(
                                        player['name'] ?? 'Unknown',
                                        List<String>.from(
                                          player['teamNames'],
                                        ), // Ensure List<String>
                                      ),
                                  child: Text('Teams'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
