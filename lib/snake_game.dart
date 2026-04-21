import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'game_state.dart';
import 'audio_service.dart';
import 'leaderboard_service.dart';

class SnakeGameWidget extends StatefulWidget {
  final bool isTwoPlayer;
  final GameState? externalGameState;

  const SnakeGameWidget({
    super.key,
    this.isTwoPlayer = false,
    this.externalGameState,
  });

  @override
  State<SnakeGameWidget> createState() => _SnakeGameWidgetState();
}

class _SnakeGameWidgetState extends State<SnakeGameWidget>
    with TickerProviderStateMixin {
  late GameState _gameState;
  Timer? _timer;
  final AudioService _audioService = AudioService();
  late LeaderboardService _leaderboardService;
  bool _hasShownGameOverDialog = false;

  // Two player state
  GameState? _player2State;

  @override
  void initState() {
    super.initState();
    _gameState = widget.externalGameState ?? GameState.initial();
    _leaderboardService = LeaderboardService();
    _leaderboardService.load();
    _audioService.init();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: _gameState.speed),
      (_) => _gameLoop(),
    );
  }

  void _gameLoop() {
    if (_gameState.isGameOver) {
      _timer?.cancel();
      return;
    }

    setState(() {
      _gameState.move();
      _gameState.updateEvolution();

      if (_gameState.isGameOver) {
        _timer?.cancel();
        _onGameOver();
      }
    });
  }

  void _onGameOver() {
    if (_hasShownGameOverDialog) return;
    _hasShownGameOverDialog = true;
    _audioService.playGameOver();
    if (_leaderboardService.isTopTen(_gameState.score)) {
      _showNameInputDialog();
    }
  }

  void _showNameInputDialog() {
    final controller = TextEditingController(text: 'Player');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏆 恭喜上榜！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('分數: ${_gameState.score}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '輸入你的名字',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _leaderboardService.addEntry(
                controller.text.isEmpty ? 'Player' : controller.text,
                _gameState.score,
                _gameState.currentDragonLevel,
              );
              Navigator.pop(context);
              _showLeaderboard();
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏆 排行榜'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _leaderboardService.entries.length,
            itemBuilder: (context, index) {
              final entry = _leaderboardService.entries[index];
              return ListTile(
                leading: _getMedalIcon(index),
                title: Text(entry.name),
                subtitle: Text('Level ${entry.maxLevel} - ${_formatDate(entry.date)}'),
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Player 1 controls
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW) {
      if (_gameState.direction != Direction.down) {
        _gameState.nextDirection = Direction.up;
      }
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      if (_gameState.direction != Direction.up) {
        _gameState.nextDirection = Direction.down;
      }
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      if (_gameState.direction != Direction.right) {
        _gameState.nextDirection = Direction.left;
      }
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      if (_gameState.direction != Direction.left) {
        _gameState.nextDirection = Direction.right;
      }
    } else if (key == LogicalKeyboardKey.space) {
      setState(() {
        _gameState.togglePause();
      });
    } else if (key == LogicalKeyboardKey.keyR) {
      setState(() {
        _gameState.reset();
        _hasShownGameOverDialog = false;
        _startTimer();
      });
    } else if (key == LogicalKeyboardKey.keyL) {
      _showLeaderboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKey,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0 && _gameState.direction != Direction.right) {
            _gameState.nextDirection = Direction.left;
          } else if (details.primaryVelocity! > 0 && _gameState.direction != Direction.left) {
            _gameState.nextDirection = Direction.right;
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < 0 && _gameState.direction != Direction.down) {
            _gameState.nextDirection = Direction.up;
          } else if (details.primaryVelocity! > 0 && _gameState.direction != Direction.up) {
            _gameState.nextDirection = Direction.down;
          }
        },
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: GameConstants.getBackgroundGradient(_gameState.level),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: GameConstants.gridWidth / GameConstants.gridHeight,
                            child: CustomPaint(
                              painter: _GhibliSnakePainter(_gameState),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildMobileControls(),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Up
          _buildControlButton(Icons.arrow_upward, Direction.up, Colors.blue),
          const SizedBox(height: 8),
          // Left - Center - Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(Icons.arrow_back, Direction.left, Colors.blue),
              const SizedBox(width: 80), // Center space
              _buildControlButton(Icons.arrow_forward, Direction.right, Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
          // Down
          _buildControlButton(Icons.arrow_downward, Direction.down, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Direction dir, Color color) {
    return GestureDetector(
      onTap: () {
        if (dir == Direction.up && _gameState.direction != Direction.down) {
          _gameState.nextDirection = Direction.up;
        } else if (dir == Direction.down && _gameState.direction != Direction.up) {
          _gameState.nextDirection = Direction.down;
        } else if (dir == Direction.left && _gameState.direction != Direction.right) {
          _gameState.nextDirection = Direction.left;
        } else if (dir == Direction.right && _gameState.direction != Direction.left) {
          _gameState.nextDirection = Direction.right;
        }
      },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dragon level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: GameConstants.dragonColors[_gameState.currentDragonLevel - 1]
                  .withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  _getDragonEmoji(_gameState.currentDragonLevel),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  GameConstants.getDragonName(_gameState.currentDragonLevel),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⭐ ${_gameState.score}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          // Mute button
          IconButton(
            onPressed: () {
              _audioService.toggleMute();
              setState(() {});
            },
            icon: Icon(
              _audioService.isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
          ),
          // Leaderboard button
          IconButton(
            onPressed: _showLeaderboard,
            icon: const Icon(Icons.emoji_events, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _getDragonEmoji(int level) {
    switch (level) {
      case 1:
        return '🐍';
      case 2:
        return '🐉';
      case 3:
        return '🐲';
      case 4:
        return '🐲';
      case 5:
        return '🐉';
      default:
        return '🐍';
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_gameState.isPaused)
            const Text(
              '⏸️ 暫停中',
              style: TextStyle(color: Colors.yellow, fontSize: 20),
            ),
          if (_gameState.isGameOver) _buildGameOverContent(),
          const SizedBox(height: 8),
          const Text(
            'WASD / 方向鍵移動 | 空白鍵暫停 | R重新開始 | L排行榜',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverContent() {
    return Column(
      children: [
        const Text(
          '💀 遊戲結束',
          style: TextStyle(color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '最終分數: ${_gameState.score} | 等級: ${GameConstants.getDragonName(_gameState.currentDragonLevel)}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _gameState.reset();
              _hasShownGameOverDialog = false;
              _startTimer();
            });
          },
          icon: const Text('🔄'),
          label: const Text('再玩一次'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GameConstants.dragonColors[_gameState.currentDragonLevel - 1],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Text('🏠'),
          label: const Text('回到主選單'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _GhibliSnakePainter extends CustomPainter {
  final GameState gameState;

  _GhibliSnakePainter(this.gameState);

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / GameConstants.gridWidth;
    final cellHeight = size.height / GameConstants.gridHeight;

    // Draw soft grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int x = 0; x <= GameConstants.gridWidth; x++) {
      canvas.drawLine(
        Offset(x * cellWidth, 0),
        Offset(x * cellWidth, size.height),
        gridPaint,
      );
    }
    for (int y = 0; y <= GameConstants.gridHeight; y++) {
      canvas.drawLine(
        Offset(0, y * cellHeight),
        Offset(size.width, y * cellHeight),
        gridPaint,
      );
    }

    // Draw decorative clouds
    _drawClouds(canvas, size, cellWidth);

    // Draw food (star/magical item)
    _drawFood(canvas, cellWidth, cellHeight);

    // Draw snake with Ghibli style
    _drawSnake(canvas, cellWidth, cellHeight);

    // Draw evolution effect
    if (gameState.isEvolving) {
      _drawEvolutionEffect(canvas, size, cellWidth);
    }
  }

  void _drawClouds(Canvas canvas, Size size, double cellWidth) {
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Simple decorative clouds
    final random = Random(42);
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.3;
      canvas.drawCircle(Offset(x, y), cellWidth * 1.5, cloudPaint);
      canvas.drawCircle(Offset(x + cellWidth, y - cellWidth * 0.5), cellWidth, cloudPaint);
      canvas.drawCircle(Offset(x - cellWidth, y + cellWidth * 0.3), cellWidth * 0.8, cloudPaint);
    }
  }

  void _drawFood(Canvas canvas, double cellWidth, double cellHeight) {
    final food = gameState.food;
    final centerX = food.x * cellWidth + cellWidth / 2;
    final centerY = food.y * cellHeight + cellHeight / 2;
    final radius = cellWidth / 2 - 2;

    // Ghibli-style magical star food
    final gradient = RadialGradient(
      colors: [
        GameConstants.sunYellow,
        GameConstants.sunsetOrange,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      );

    // Draw star shape
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final outerX = centerX + cos(angle) * radius;
      final outerY = centerY + sin(angle) * radius;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;
      final innerX = centerX + cos(innerAngle) * radius * 0.4;
      final innerY = centerY + sin(innerAngle) * radius * 0.4;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();

    canvas.drawPath(path, paint);

    // Add glow effect
    final glowPaint = Paint()
      ..color = GameConstants.sunYellow.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(centerX, centerY), radius * 1.5, glowPaint);
  }

  void _drawSnake(Canvas canvas, double cellWidth, double cellHeight) {
    final color = GameConstants.dragonColors[gameState.currentDragonLevel - 1];

    for (int i = gameState.snake.length - 1; i >= 0; i--) {
      final segment = gameState.snake[i];
      final isHead = i == 0;

      // Gradient color - lighter towards tail
      final colorProgress = 1.0 - (i / gameState.snake.length);
      final segmentColor = Color.lerp(
        color.withOpacity(0.7),
        color,
        colorProgress,
      )!;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          segment.x * cellWidth + 1,
          segment.y * cellHeight + 1,
          cellWidth - 2,
          cellHeight - 2,
        ),
        Radius.circular(cellWidth * 0.3),
      );

      // Draw segment with soft shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(
        rect.shift(const Offset(2, 2)),
        shadowPaint,
      );

      final segmentPaint = Paint()
        ..color = segmentColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, segmentPaint);

      // Draw scale pattern for higher levels
      if (gameState.currentDragonLevel >= 3) {
        _drawScales(canvas, segment, cellWidth, cellHeight, segmentColor);
      }

      // Draw eyes on head
      if (isHead) {
        _drawDragonHead(canvas, segment, cellWidth, cellHeight, color);
      }
    }
  }

  void _drawScales(Canvas canvas, Position segment, double cellWidth, double cellHeight, Color baseColor) {
    final scalePaint = Paint()
      ..color = baseColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final scaleSize = cellWidth * 0.25;
    final startX = segment.x * cellWidth + scaleSize;
    final startY = segment.y * cellHeight + scaleSize;

    // Draw simple scale pattern
    canvas.drawCircle(
      Offset(startX + scaleSize, startY + scaleSize),
      scaleSize * 0.5,
      scalePaint,
    );
  }

  void _drawDragonHead(
    Canvas canvas,
    Position segment,
    double cellWidth,
    double cellHeight,
    Color color,
  ) {
    final headX = segment.x * cellWidth + cellWidth / 2;
    final headY = segment.y * cellHeight + cellHeight / 2;

    // Draw larger, more expressive eyes based on level
    final eyeSize = cellWidth * (0.2 + gameState.currentDragonLevel * 0.03);
    final eyeOffset = cellWidth * 0.2;

    Offset leftEye, rightEye;
    switch (gameState.direction) {
      case Direction.up:
        leftEye = Offset(headX - eyeOffset, headY - eyeOffset * 0.5);
        rightEye = Offset(headX + eyeOffset, headY - eyeOffset * 0.5);
        break;
      case Direction.down:
        leftEye = Offset(headX - eyeOffset, headY + eyeOffset * 0.5);
        rightEye = Offset(headX + eyeOffset, headY + eyeOffset * 0.5);
        break;
      case Direction.left:
        leftEye = Offset(headX - eyeOffset * 0.5, headY - eyeOffset);
        rightEye = Offset(headX - eyeOffset * 0.5, headY + eyeOffset);
        break;
      case Direction.right:
        leftEye = Offset(headX + eyeOffset * 0.5, headY - eyeOffset);
        rightEye = Offset(headX + eyeOffset * 0.5, headY + eyeOffset);
        break;
    }

    // Eye whites
    final eyeWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(leftEye, eyeSize, eyeWhitePaint);
    canvas.drawCircle(rightEye, eyeSize, eyeWhitePaint);

    // Pupils (larger for higher levels - more dragon-like)
    final pupilSize = eyeSize * (0.5 + gameState.currentDragonLevel * 0.1);
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(leftEye, pupilSize, pupilPaint);
    canvas.drawCircle(rightEye, pupilSize, pupilPaint);

    // Highlight
    final highlightPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      leftEye + Offset(-pupilSize * 0.3, -pupilSize * 0.3),
      pupilSize * 0.3,
      highlightPaint,
    );
    canvas.drawCircle(
      rightEye + Offset(-pupilSize * 0.3, -pupilSize * 0.3),
      pupilSize * 0.3,
      highlightPaint,
    );

    // Draw horns/antlers for higher levels
    if (gameState.currentDragonLevel >= 3) {
      _drawHorns(canvas, headX, headY, cellWidth);
    }
  }

  void _drawHorns(Canvas canvas, double headX, double headY, double cellWidth) {
    final hornPaint = Paint()
      ..color = GameConstants.warmBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final hornLength = cellWidth * 0.6;

    // Draw two small horns
    canvas.drawLine(
      Offset(headX - cellWidth * 0.3, headY - cellWidth * 0.2),
      Offset(headX - cellWidth * 0.4, headY - hornLength),
      hornPaint,
    );
    canvas.drawLine(
      Offset(headX + cellWidth * 0.3, headY - cellWidth * 0.2),
      Offset(headX + cellWidth * 0.4, headY - hornLength),
      hornPaint,
    );
  }

  void _drawEvolutionEffect(Canvas canvas, Size size, double cellWidth) {
    final progress = gameState.evolutionFrame / 30;
    final glowRadius = cellWidth * 3 * (1 - progress);

    final glowPaint = Paint()
      ..color = GameConstants.sunYellow.withOpacity(progress * 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      glowRadius,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
