import 'package:flutter/material.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFD),
              Color(0xFFE6EDF7),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF667EEA).withOpacity(0.1),
                      Color(0xFF764BA2).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacer(),

                    // Title
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        fontSize: 28,
                        color: Color(0xFF718096),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: 8),

                    Text(
                      'Weather Pro',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                        height: 1.1,
                      ),
                    ),

                    SizedBox(height: 20),

                    // Description
                    Text(
                      'Your personal weather assistant providing real-time forecasts, alerts, and detailed analysis.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4A5568),
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 40),

                    // Features list
                    _buildFeatureItem(
                      icon: Icons.language_rounded,
                      title: 'Global Coverage',
                      subtitle: 'Weather data for any location worldwide',
                    ),
                    SizedBox(height: 20),

                    _buildFeatureItem(
                      icon: Icons.notifications_active_rounded,
                      title: 'Smart Alerts',
                      subtitle: 'Get notified about weather changes',
                    ),
                    SizedBox(height: 20),

                    _buildFeatureItem(
                      icon: Icons.insights_rounded,
                      title: 'Detailed Analytics',
                      subtitle: 'Hourly and weekly forecast breakdowns',
                    ),

                    Spacer(),

                    // Get Started Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/navigation');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5A67D8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Color(0xFF5A67D8).withOpacity(0.3),
                        ),
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Already have account?
                    // Center(
                    //   child: TextButton(
                    //     onPressed: () {},
                    //     child: Text(
                    //       'Skip to Dashboard',
                    //       style: TextStyle(
                    //         color: Color(0xFF718096),
                    //         fontSize: 14,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF5A67D8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Color(0xFF5A67D8),
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}