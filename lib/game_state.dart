import 'dart:math';
import 'package:flutter/foundation.dart';
import 'constants.dart';

enum Direction { up, down, left, right }

class Position {
  final int x;
  final int y;
  Position(this.x, this.y);

  Position copyWith({int? x, int? y}) => Position(x ?? this.x, y ?? this.y);

  @override
  bool operator ==(Object other) =>
      other is Position && other.x == x && other.y == y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class GameState {
  List<Position> snake;
  Position food;
  Direction direction;
  Direction nextDirection;
  int score;
  int level;
  int speed;
  bool isGameOver;
  bool isPaused;
  bool isEvolving;
  int evolutionFrame;

  // Evolution state
  int currentDragonLevel;

  // Event callbacks for audio service
  VoidCallback? onEatFood;
  VoidCallback? onEvolution;

  GameState({
    required this.snake,
    required this.food,
    this.direction = Direction.right,
    this.nextDirection = Direction.right,
    this.score = 0,
    this.level = 1,
    this.speed = GameConstants.initialSpeed,
    this.isGameOver = false,
    this.isPaused = false,
    this.isEvolving = false,
    this.evolutionFrame = 0,
    this.currentDragonLevel = 1,
  });

  factory GameState.initial() {
    final snake = [
      Position(12, 12),
      Position(11, 12),
      Position(10, 12),
      Position(9, 12),
    ];
    return GameState(
      snake: snake,
      food: _generateFood(snake),
    );
  }

  static Position _generateFood(List<Position> snake) {
    final random = Random();
    Position food;
    do {
      food = Position(
        random.nextInt(GameConstants.gridWidth),
        random.nextInt(GameConstants.gridHeight),
      );
    } while (snake.contains(food));
    return food;
  }

  int _calculateDragonLevel() {
    if (score >= GameConstants.dragonLevel5Score) return 5;
    if (score >= GameConstants.dragonLevel4Score) return 4;
    if (score >= GameConstants.dragonLevel3Score) return 3;
    if (score >= GameConstants.dragonLevel2Score) return 2;
    return 1;
  }

  void move() {
    if (isPaused || isGameOver || isEvolving) return;

    direction = nextDirection;

    final head = snake.first;
    Position newHead;

    switch (direction) {
      case Direction.up:
        newHead = Position(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Position(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Position(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Position(head.x + 1, head.y);
        break;
    }

    // Wall collision
    if (newHead.x < 0 ||
        newHead.x >= GameConstants.gridWidth ||
        newHead.y < 0 ||
        newHead.y >= GameConstants.gridHeight) {
      isGameOver = true;
      return;
    }

    // Self collision
    if (snake.contains(newHead)) {
      isGameOver = true;
      return;
    }

    snake.insert(0, newHead);

    // Food collision
    if (newHead == food) {
      final oldLevel = currentDragonLevel;
      score += 10;
      level = (score ~/ 20) + 1;
      speed = GameConstants.initialSpeed - (level - 1) * GameConstants.speedIncrease;
      if (speed < 50) speed = 50;

      // Check for evolution - instant with just a quick visual flash
      final newDragonLevel = _calculateDragonLevel();
      if (newDragonLevel > oldLevel) {
        currentDragonLevel = newDragonLevel;
        isEvolving = true;
        evolutionFrame = 3; // Very quick flash (less than 1 second)
        onEvolution?.call();
      } else {
        onEatFood?.call();
      }

      food = _generateFood(snake);
    } else {
      snake.removeLast();
    }
  }

  void updateEvolution() {
    if (isEvolving && evolutionFrame > 0) {
      evolutionFrame--;
      if (evolutionFrame == 0) {
        isEvolving = false;
      }
    }
  }

  void togglePause() {
    if (!isGameOver) {
      isPaused = !isPaused;
    }
  }

  void reset() {
    final newState = GameState.initial();
    snake = newState.snake;
    food = newState.food;
    direction = newState.direction;
    nextDirection = newState.nextDirection;
    score = newState.score;
    level = newState.level;
    speed = newState.speed;
    isGameOver = newState.isGameOver;
    isPaused = newState.isPaused;
    isEvolving = newState.isEvolving;
    evolutionFrame = newState.evolutionFrame;
    currentDragonLevel = newState.currentDragonLevel;
  }
}
