import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants.dart'; // Import baseUrl
import 'PlayerProfilePage.dart'; // Import PlayerProfilePage

class ParticipantsPage extends StatefulWidget {
  final String eventId;

  ParticipantsPage({required this.eventId});

  @override
  _ParticipantsPageState createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  List<Map<String, dynamic>> teamDetails = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-event-participants/${widget.eventId}'),
      );

      if (response.statusCode == 200) {
        final participants = json.decode(response.body)['participants'];
        if (participants is List) {
          setState(() {
            teamDetails = participants.cast<Map<String, dynamic>>();
            isLoading = false;
          });
        }
      } else {
        print('Failed to load participants: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching participants: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Participants')),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Changed from gradient to solid white
        ),
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : teamDetails.isEmpty
                ? Center(child: Text('No participants found'))
                : ListView.builder(
                  itemCount: teamDetails.length,
                  itemBuilder: (context, index) {
                    final team = teamDetails[index];
                    final memberCount = team['members']?.length ?? 0;
                    final isScrollable = memberCount > 3;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade200,
                            Colors.blue.shade200,
                            Colors.pink.shade100,
                          ],
                        ), // Gradient border for team box
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
                      height:
                          isScrollable
                              ? MediaQuery.of(context).size.height /
                                  2.2 // Two boxes fit on screen
                              : (memberCount * 80.0) +
                                  100.0, // Adjust height for fewer members
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team ${index + 1}: ${team['teamName'] ?? 'No Name'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'Participants:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          CustomPaint(
                            size: Size(double.infinity, 1),
                            painter: DashPainter(), // Dotted line
                          ),
                          SizedBox(height: 8.0),
                          Expanded(
                            child: Container(
                              color:
                                  Colors
                                      .white, // Background color after dotted line
                              child:
                                  isScrollable
                                      ? ListView.builder(
                                        itemCount: memberCount,
                                        itemBuilder: (context, memberIndex) {
                                          final member =
                                              team['members'][memberIndex];
                                          return Container(
                                            margin: EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            padding: EdgeInsets.all(12.0),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.5),
                                                  spreadRadius: 2,
                                                  blurRadius: 5,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${memberIndex + 1}.',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(width: 8.0),
                                                Expanded(
                                                  child: Text(
                                                    member['name'],
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    softWrap: true,
                                                  ),
                                                ),
                                                SizedBox(width: 8.0),
                                                MouseRegion(
                                                  cursor:
                                                      SystemMouseCursors
                                                          .click, // Show hand cursor on hover
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => PlayerProfilePage(
                                                                playerName:
                                                                    member['name'],
                                                                playerEmail:
                                                                    member['email'] ??
                                                                    'N/A',
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.all(
                                                        12.0,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors
                                                                .orange
                                                                .shade200, // Orange color for "Profile"
                                                        shape:
                                                            BoxShape
                                                                .circle, // Circular shape
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                            spreadRadius: 2,
                                                            blurRadius: 5,
                                                            offset: Offset(
                                                              0,
                                                              3,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .person, // Profile icon
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                      : Column(
                                        children:
                                            team['members']?.map<Widget>((
                                              member,
                                            ) {
                                              return Container(
                                                margin: EdgeInsets.symmetric(
                                                  vertical: 8.0,
                                                ),
                                                padding: EdgeInsets.all(12.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.0,
                                                      ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey
                                                          .withOpacity(0.5),
                                                      spreadRadius: 2,
                                                      blurRadius: 5,
                                                      offset: Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '${team['members'].indexOf(member) + 1}.',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8.0),
                                                    Expanded(
                                                      child: Text(
                                                        member['name'],
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                        softWrap: true,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8.0),
                                                    MouseRegion(
                                                      cursor:
                                                          SystemMouseCursors
                                                              .click, // Show hand cursor on hover
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    context,
                                                                  ) => PlayerProfilePage(
                                                                    playerName:
                                                                        member['name'],
                                                                    playerEmail:
                                                                        member['email'] ??
                                                                        'N/A',
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                12.0,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .orange
                                                                    .shade200, // Orange color for "Profile"
                                                            shape:
                                                                BoxShape
                                                                    .circle, // Circular shape
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                      0.5,
                                                                    ),
                                                                spreadRadius: 2,
                                                                blurRadius: 5,
                                                                offset: Offset(
                                                                  0,
                                                                  3,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .person, // Profile icon
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList() ??
                                            [],
                                      ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

class DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
