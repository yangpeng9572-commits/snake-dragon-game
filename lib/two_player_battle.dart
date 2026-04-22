import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'game_state.dart';
import 'audio_service.dart';

class TwoPlayerBattleWidget extends StatefulWidget {
  const TwoPlayerBattleWidget({super.key});

  @override
  State<TwoPlayerBattleWidget> createState() => _TwoPlayerBattleWidgetState();
}

class _TwoPlayerBattleWidgetState extends State<TwoPlayerBattleWidget> {
  // Player 1 (WASD) - Green snake
  late GameState _player1State;
  // Player 2 (Arrow keys) - Blue snake
  late GameState _player2State;
  
  Timer? _timer;
  bool _isGameOver = false;
  String? _winner;
  bool _isPaused = false;
  
  // Fixed focus node to prevent KeyboardListener from losing focus on rebuild
  late FocusNode _focusNode;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _audioService.init();
    _audioService.playBgm();
    _initGame();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.stopBgm();
    _audioService.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initGame() {
    // Create snake bodies first (don't reference each other's snake for food generation)
    _player1State = GameState(
      snake: [
        Position(7, 12),
        Position(6, 12),
        Position(5, 12),
      ],
      direction: Direction.right,
      currentDragonLevel: 1,
    );
    
    _player2State = GameState(
      snake: [
        Position(17, 12),
        Position(18, 12),
        Position(19, 12),
      ],
      direction: Direction.left,
      currentDragonLevel: 1,
    );
    
    // Generate and assign food AFTER both snakes exist (fixes late init bug)
    final sharedFood = _generateFood([..._player1State.snake, ..._player2State.snake]);
    _player1State.food = sharedFood;
    _player2State.food = sharedFood;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: 180),
      (_) => _gameLoop(),
    );
  }

  Position _generateFood(List<Position> allSnakes) {
    final random = Random();
    Position food;
    do {
      food = Position(
        random.nextInt(GameConstants.gridWidth),
        random.nextInt(GameConstants.gridHeight),
      );
    } while (allSnakes.contains(food));
    return food;
  }

  void _gameLoop() {
    if (_isGameOver || _isPaused) return;

    setState(() {
      // Move both snakes
      _player1State.move();
      _player2State.move();

      // MUST call updateEvolution every tick to decrement evolutionFrame
      _player1State.updateEvolution();
      _player2State.updateEvolution();

      // Check for food collision - who eats first gets the point
      if (_player1State.snake.first == _player1State.food ||
          _player1State.snake.first == _player2State.food) {
        _player1State.score += 10;
        _player1State.currentDragonLevel = _calculateLevel(_player1State.score);
        _audioService.playEat();
        _respawnFood();
      }
      
      if (_player2State.snake.first == _player2State.food ||
          _player2State.snake.first == _player1State.food) {
        _player2State.score += 10;
        _player2State.currentDragonLevel = _calculateLevel(_player2State.score);
        _audioService.playEat();
        _respawnFood();
      }

      // Wall collision
      final p1Head = _player1State.snake.first;
      final p2Head = _player2State.snake.first;
      
      bool p1Dead = p1Head.x < 0 || p1Head.x >= GameConstants.gridWidth ||
                     p1Head.y < 0 || p1Head.y >= GameConstants.gridHeight;
      bool p2Dead = p2Head.x < 0 || p2Head.x >= GameConstants.gridWidth ||
                     p2Head.y < 0 || p2Head.y >= GameConstants.gridHeight;

      // Self collision
      if (!_player1State.isGameOver) {
        for (int i = 1; i < _player1State.snake.length; i++) {
          if (_player1State.snake[i] == p1Head) {
            p1Dead = true;
            break;
          }
        }
      }
      
      if (!_player2State.isGameOver) {
        for (int i = 1; i < _player2State.snake.length; i++) {
          if (_player2State.snake[i] == p2Head) {
            p2Dead = true;
            break;
          }
        }
      }

      // Head-to-head collision
      if (p1Head == p2Head) {
        p1Dead = true;
        p2Dead = true;
      }

      // Head-to-body collision
      for (int i = 1; i < _player2State.snake.length; i++) {
        if (_player2State.snake[i] == p1Head) {
          p1Dead = true;
          break;
        }
      }
      for (int i = 1; i < _player1State.snake.length; i++) {
        if (_player1State.snake[i] == p2Head) {
          p2Dead = true;
          break;
        }
      }

      if (p1Dead || p2Dead) {
        _isGameOver = true;
        _timer?.cancel();
        _audioService.playGameOver();
        if (p1Dead && p2Dead) {
          _winner = '平手！';
        } else if (p1Dead) {
          _winner = '玩家2 勝利！';
        } else {
          _winner = '玩家1 勝利！';
        }
      }
    });
  }

  int _calculateLevel(int score) {
    if (score >= 250) return 5;
    if (score >= 150) return 4;
    if (score >= 80) return 3;
    if (score >= 30) return 2;
    return 1;
  }

  void _respawnFood() {
    final allPositions = [..._player1State.snake, ..._player2State.snake];
    _player1State.food = _generateFood(allPositions);
    _player2State.food = _player1State.food;
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Player 1 controls (WASD)
    if (key == LogicalKeyboardKey.keyW) {
      if (_player1State.direction != Direction.down) {
        _player1State.nextDirection = Direction.up;
      }
    } else if (key == LogicalKeyboardKey.keyS) {
      if (_player1State.direction != Direction.up) {
        _player1State.nextDirection = Direction.down;
      }
    } else if (key == LogicalKeyboardKey.keyA) {
      if (_player1State.direction != Direction.right) {
        _player1State.nextDirection = Direction.left;
      }
    } else if (key == LogicalKeyboardKey.keyD) {
      if (_player1State.direction != Direction.left) {
        _player1State.nextDirection = Direction.right;
      }
    }

    // Player 2 controls (Arrow keys)
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_player2State.direction != Direction.down) {
        _player2State.nextDirection = Direction.up;
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (_player2State.direction != Direction.up) {
        _player2State.nextDirection = Direction.down;
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (_player2State.direction != Direction.right) {
        _player2State.nextDirection = Direction.left;
      }
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (_player2State.direction != Direction.left) {
        _player2State.nextDirection = Direction.right;
      }
    }

    // Pause with Space
    if (key == LogicalKeyboardKey.space) {
      setState(() {
        _isPaused = !_isPaused;
      });
    }

    // Restart with R
    if (key == LogicalKeyboardKey.keyR) {
      setState(() {
        _isGameOver = false;
        _winner = null;
        _player1State = GameState(
          snake: [Position(7, 12), Position(6, 12), Position(5, 12)],
          food: Position(12, 12),
          direction: Direction.right,
          currentDragonLevel: 1,
        );
        _player2State = GameState(
          snake: [Position(17, 12), Position(18, 12), Position(19, 12)],
          food: Position(12, 12),
          direction: Direction.left,
          currentDragonLevel: 1,
        );
        _respawnFood();
        _startTimer();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      autofocus: true,
      child: Scaffold(
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
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: GameConstants.gridWidth / GameConstants.gridHeight,
                          child: CustomPaint(
                            painter: _TwoPlayerPainter(_player1State, _player2State),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Player 1 score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🐍', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'P1: ${_player1State.score}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          // VS or winner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isGameOver ? _winner! : 'VS',
              style: TextStyle(
                color: _isGameOver ? Colors.amber : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          // Player 2 score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  'P2: ${_player2State.score}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Text('🐍', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isGameOver)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isGameOver = false;
                  _winner = null;
                  _player1State = GameState(
                    snake: [Position(7, 12), Position(6, 12), Position(5, 12)],
                    food: Position(12, 12),
                    direction: Direction.right,
                    currentDragonLevel: 1,
                  );
                  _player2State = GameState(
                    snake: [Position(17, 12), Position(18, 12), Position(19, 12)],
                    food: Position(12, 12),
                    direction: Direction.left,
                    currentDragonLevel: 1,
                  );
                  _respawnFood();
                  _startTimer();
                });
              },
              icon: const Text('🔄'),
              label: const Text('再玩一次'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          const SizedBox(height: 12),
          if (_isPaused)
            const Text('⏸️ 暫停中', style: TextStyle(color: Colors.yellow, fontSize: 20)),
          const SizedBox(height: 8),
          const Text(
            '玩家1: WASD 控制 | 玩家2: 方向鍵控制 | 空白鍵暫停 | R重新開始',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Text('🏠'),
            label: const Text('回到主選單'),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _TwoPlayerPainter extends CustomPainter {
  final GameState player1;
  final GameState player2;

  _TwoPlayerPainter(this.player1, this.player2);

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / GameConstants.gridWidth;
    final cellHeight = size.height / GameConstants.gridHeight;

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int x = 0; x <= GameConstants.gridWidth; x++) {
      canvas.drawLine(Offset(x * cellWidth, 0), Offset(x * cellWidth, size.height), gridPaint);
    }
    for (int y = 0; y <= GameConstants.gridHeight; y++) {
      canvas.drawLine(Offset(0, y * cellHeight), Offset(size.width, y * cellHeight), gridPaint);
    }

    // Draw food
    _drawFood(canvas, cellWidth, cellHeight);

    // Draw Player 1 (green)
    _drawSnake(canvas, player1, cellWidth, cellHeight, Colors.green);

    // Draw Player 2 (blue)
    _drawSnake(canvas, player2, cellWidth, cellHeight, Colors.blue);
  }

  void _drawFood(Canvas canvas, double cellWidth, double cellHeight) {
    final food = player1.food;
    final centerX = food.x * cellWidth + cellWidth / 2;
    final centerY = food.y * cellHeight + cellHeight / 2;
    final radius = cellWidth / 2 - 2;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [GameConstants.sunYellow, GameConstants.sunsetOrange],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));

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
  }

  void _drawSnake(Canvas canvas, GameState state, double cellWidth, double cellHeight, Color baseColor) {
    for (int i = state.snake.length - 1; i >= 0; i--) {
      final segment = state.snake[i];
      final isHead = i == 0;

      final colorProgress = 1.0 - (i / state.snake.length);
      final segmentColor = Color.lerp(baseColor.withOpacity(0.7), baseColor, colorProgress)!;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(segment.x * cellWidth + 1, segment.y * cellHeight + 1, cellWidth - 2, cellHeight - 2),
        Radius.circular(cellWidth * 0.3),
      );

      canvas.drawRRect(rect, Paint()..color = segmentColor);

      if (isHead) {
        // Draw eyes
        final headX = segment.x * cellWidth + cellWidth / 2;
        final headY = segment.y * cellHeight + cellHeight / 2;
        final eyeOffset = cellWidth * 0.2;
        final eyeSize = cellWidth * 0.15;

        Offset leftEye, rightEye;
        switch (state.direction) {
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

        canvas.drawCircle(leftEye, eyeSize, Paint()..color = Colors.white);
        canvas.drawCircle(rightEye, eyeSize, Paint()..color = Colors.white);
        canvas.drawCircle(leftEye, eyeSize * 0.5, Paint()..color = Colors.black);
        canvas.drawCircle(rightEye, eyeSize * 0.5, Paint()..color = Colors.black);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
