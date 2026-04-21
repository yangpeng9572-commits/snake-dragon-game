import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'game_state.dart';

class SinglePlayerVsNpcWidget extends StatefulWidget {
  const SinglePlayerVsNpcWidget({super.key});

  @override
  State<SinglePlayerVsNpcWidget> createState() => _SinglePlayerVsNpcWidgetState();
}

class _SinglePlayerVsNpcWidgetState extends State<SinglePlayerVsNpcWidget> {
  // Player (human) - Green snake
  late GameState _playerState;
  // NPC - Red snake
  late GameState _npcState;
  
  Timer? _timer;
  bool _isGameOver = false;
  String? _winner;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _initGame();
    _startTimer();
  }

  void _initGame() {
    _playerState = GameState(
      snake: [Position(7, 12), Position(6, 12), Position(5, 12)],
      food: Position(12, 12),
      direction: Direction.right,
      currentDragonLevel: 1,
    );
    
    _npcState = GameState(
      snake: [Position(17, 12), Position(18, 12), Position(19, 12)],
      food: Position(12, 12),
      direction: Direction.left,
      currentDragonLevel: 1,
    );
    
    _respawnFood();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  void _respawnFood() {
    final allPositions = [..._playerState.snake, ..._npcState.snake];
    final food = _generateFood(allPositions);
    _playerState.food = food;
    _npcState.food = food;
  }

  // Simple NPC AI - chase food and avoid collisions
  void _npcAI() {
    if (_npcState.isGameOver || _npcState.isPaused) return;
    
    final head = _npcState.snake.first;
    final food = _npcState.food;
    
    // Calculate direction to food
    int dx = food.x - head.x;
    int dy = food.y - head.y;
    
    // Possible moves
    List<Direction> possibleMoves = [];
    
    if (dx > 0 && _npcState.direction != Direction.left) possibleMoves.add(Direction.right);
    if (dx < 0 && _npcState.direction != Direction.right) possibleMoves.add(Direction.left);
    if (dy > 0 && _npcState.direction != Direction.up) possibleMoves.add(Direction.down);
    if (dy < 0 && _npcState.direction != Direction.down) possibleMoves.add(Direction.up);
    
    // Filter out moves that would cause collision
    List<Direction> safeMoves = [];
    for (Direction move in possibleMoves) {
      Position nextPos = _getNextPosition(head, move);
      if (_isSafePosition(nextPos, _npcState.snake)) {
        safeMoves.add(move);
      }
    }
    
    // Choose best move
    if (safeMoves.isNotEmpty) {
      // Prefer moves towards food
      if (dx.abs() >= dy.abs() && safeMoves.contains(dx > 0 ? Direction.right : Direction.left)) {
        _npcState.nextDirection = dx > 0 ? Direction.right : Direction.left;
      } else if (safeMoves.contains(dy > 0 ? Direction.down : Direction.up)) {
        _npcState.nextDirection = dy > 0 ? Direction.down : Direction.up;
      } else {
        _npcState.nextDirection = safeMoves[Random().nextInt(safeMoves.length)];
      }
    }
  }

  Position _getNextPosition(Position head, Direction dir) {
    switch (dir) {
      case Direction.up: return Position(head.x, head.y - 1);
      case Direction.down: return Position(head.x, head.y + 1);
      case Direction.left: return Position(head.x - 1, head.y);
      case Direction.right: return Position(head.x + 1, head.y);
    }
  }

  bool _isSafePosition(Position pos, List<Position> snake) {
    // Check wall collision
    if (pos.x < 0 || pos.x >= GameConstants.gridWidth ||
        pos.y < 0 || pos.y >= GameConstants.gridHeight) {
      return false;
    }
    // Check self collision (skip head)
    for (int i = 1; i < snake.length - 1; i++) {
      if (snake[i] == pos) return false;
    }
    return true;
  }

  void _gameLoop() {
    if (_isGameOver || _isPaused) return;

    // NPC makes decision
    _npcAI();

    setState(() {
      // Move both
      _playerState.move();
      _npcState.move();

      // Check for food
      if (_playerState.snake.first == _playerState.food) {
        _playerState.score += 10;
        _playerState.currentDragonLevel = _calculateLevel(_playerState.score);
        _respawnFood();
      }
      
      if (_npcState.snake.first == _npcState.food) {
        _npcState.score += 10;
        _npcState.currentDragonLevel = _calculateLevel(_npcState.score);
        _respawnFood();
      }

      // Collision detection
      final pHead = _playerState.snake.first;
      final nHead = _npcState.snake.first;
      
      bool pDead = pHead.x < 0 || pHead.x >= GameConstants.gridWidth ||
                    pHead.y < 0 || pHead.y >= GameConstants.gridHeight;
      bool nDead = nHead.x < 0 || nHead.x >= GameConstants.gridWidth ||
                    nHead.y < 0 || nHead.y >= GameConstants.gridHeight;

      // Self collision
      for (int i = 1; i < _playerState.snake.length; i++) {
        if (_playerState.snake[i] == pHead) { pDead = true; break; }
      }
      for (int i = 1; i < _npcState.snake.length; i++) {
        if (_npcState.snake[i] == nHead) { nDead = true; break; }
      }

      // Head-to-head
      if (pHead == nHead) { pDead = true; nDead = true; }

      // Head-to-body
      for (int i = 1; i < _npcState.snake.length; i++) {
        if (_npcState.snake[i] == pHead) { pDead = true; break; }
      }
      for (int i = 1; i < _playerState.snake.length; i++) {
        if (_playerState.snake[i] == nHead) { nDead = true; break; }
      }

      if (pDead || nDead) {
        _isGameOver = true;
        _timer?.cancel();
        if (pDead && nDead) {
          _winner = '平手！';
        } else if (pDead) {
          _winner = 'NPC 勝利！';
        } else {
          _winner = '玩家 勝利！';
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

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Player controls (WASD)
    if (key == LogicalKeyboardKey.keyW) {
      if (_playerState.direction != Direction.down) {
        _playerState.nextDirection = Direction.up;
      }
    } else if (key == LogicalKeyboardKey.keyS) {
      if (_playerState.direction != Direction.up) {
        _playerState.nextDirection = Direction.down;
      }
    } else if (key == LogicalKeyboardKey.keyA) {
      if (_playerState.direction != Direction.right) {
        _playerState.nextDirection = Direction.left;
      }
    } else if (key == LogicalKeyboardKey.keyD) {
      if (_playerState.direction != Direction.left) {
        _playerState.nextDirection = Direction.right;
      }
    }

    // Pause with Space
    if (key == LogicalKeyboardKey.space) {
      setState(() { _isPaused = !_isPaused; });
    }

    // Restart with R
    if (key == LogicalKeyboardKey.keyR) {
      setState(() {
        _isGameOver = false;
        _winner = null;
        _initGame();
        _startTimer();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKey,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0 && _playerState.direction != Direction.right) {
            _playerState.nextDirection = Direction.left;
          } else if (details.primaryVelocity! > 0 && _playerState.direction != Direction.left) {
            _playerState.nextDirection = Direction.right;
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < 0 && _playerState.direction != Direction.down) {
            _playerState.nextDirection = Direction.up;
          } else if (details.primaryVelocity! > 0 && _playerState.direction != Direction.up) {
            _playerState.nextDirection = Direction.down;
          }
        },
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [GameConstants.skyBlue, GameConstants.forestGreen],
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
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: GameConstants.gridWidth / GameConstants.gridHeight,
                            child: CustomPaint(
                              painter: _VsNpcPainter(_playerState, _npcState),
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
          _buildControlButton(Icons.arrow_upward, Direction.up, Colors.green),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(Icons.arrow_back, Direction.left, Colors.green),
              const SizedBox(width: 80),
              _buildControlButton(Icons.arrow_forward, Direction.right, Colors.green),
            ],
          ),
          const SizedBox(height: 8),
          _buildControlButton(Icons.arrow_downward, Direction.down, Colors.green),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Direction dir, Color color) {
    return GestureDetector(
      onTap: () {
        if (dir == Direction.up && _playerState.direction != Direction.down) {
          _playerState.nextDirection = Direction.up;
        } else if (dir == Direction.down && _playerState.direction != Direction.up) {
          _playerState.nextDirection = Direction.down;
        } else if (dir == Direction.left && _playerState.direction != Direction.right) {
          _playerState.nextDirection = Direction.left;
        } else if (dir == Direction.right && _playerState.direction != Direction.left) {
          _playerState.nextDirection = Direction.right;
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
          // Player score
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
                  '玩家: ${_playerState.score}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          // VS
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
          // NPC score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  'NPC: ${_npcState.score}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Text('🤖', style: TextStyle(fontSize: 20)),
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
                  _initGame();
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
          if (_isPaused) const Text('⏸️ 暫停中', style: TextStyle(color: Colors.yellow, fontSize: 20)),
          const SizedBox(height: 8),
          const Text('WASD 移動 | 空白鍵暫停 | R重新開始', style: TextStyle(color: Colors.white70, fontSize: 12)),
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

class _VsNpcPainter extends CustomPainter {
  final GameState player;
  final GameState npc;

  _VsNpcPainter(this.player, this.npc);

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

    // Draw Player (green)
    _drawSnake(canvas, player, cellWidth, cellHeight, Colors.green);

    // Draw NPC (red)
    _drawSnake(canvas, npc, cellWidth, cellHeight, Colors.red);
  }

  void _drawFood(Canvas canvas, double cellWidth, double cellHeight) {
    final food = player.food;
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

      if (i == 0) { path.moveTo(outerX, outerY); }
      else { path.lineTo(outerX, outerY); }
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
