import 'package:flutter/material.dart';
import 'snake_game.dart';
import 'two_player_battle.dart';
import 'single_player_npc.dart';
import 'constants.dart';
import 'leaderboard_service.dart';

void main() {
  runApp(const SnakeApp());
}

class SnakeApp extends StatelessWidget {
  const SnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '龍之森林 - 貪吃蛇',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService();

  @override
  void initState() {
    super.initState();
    _leaderboardService.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameConstants.skyBlue,
              GameConstants.forestGreen,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Title with Ghibli style
                const Text(
                  '🐉',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ).createShader(bounds),
                  child: const Text(
                    '龍之森林',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Snake Dragon Evolution',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                // Menu buttons
                _buildMenuButton(
                  context,
                  '🐍 單人遊戲',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SnakeGameWidget(isTwoPlayer: false),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  '👥 雙人對戰',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TwoPlayerBattleWidget(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  '🤖 單人對戰（VS電腦）',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SinglePlayerVsNpcWidget(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  '🏆 排行榜',
                  () => _showLeaderboard(context),
                ),
                const Spacer(),
                // Footer
                const Text(
                  '🐍 單人 | 👥 雙人 | 🤖 VS電腦',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  '吉卜力風格 · 蛇變龍進化',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, VoidCallback onTap) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: GameConstants.nightSky,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          shadowColor: Colors.black26,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showLeaderboard(BuildContext context) async {
    // Reload to get latest data
    await _leaderboardService.load();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏆 排行榜'),
        content: SizedBox(
          width: double.maxFinite,
          child: _leaderboardService.entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('還沒有記錄！開始遊戲上榜吧！'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _leaderboardService.entries.length,
                  itemBuilder: (context, index) {
                    final entry = _leaderboardService.entries[index];
                    return ListTile(
                      leading: _getMedalIcon(index),
                      title: Text(entry.name),
                      subtitle: Text('Level ${entry.maxLevel}'),
                      trailing: Text(
                        '${entry.score}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  Widget _getMedalIcon(int index) {
    switch (index) {
      case 0:
        return const Text('🥇', style: TextStyle(fontSize: 24));
      case 1:
        return const Text('🥈', style: TextStyle(fontSize: 24));
      case 2:
        return const Text('🥉', style: TextStyle(fontSize: 24));
      default:
        return CircleAvatar(
          radius: 14,
          backgroundColor: Colors.grey[300],
          child: Text('${index + 1}'),
        );
    }
  }
}
