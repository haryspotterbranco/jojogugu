import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'dart:math';

void main() {
  runApp(const RacingGameApp());
}

class RacingGameApp extends StatelessWidget {
  const RacingGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corrida Simples',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: SimpleRacingGame(),
        ),
      ),
    );
  }
}

// ✅ VERSÃO CORRIGIDA - Remove o TapDetector e usa métodos diretos
class SimpleRacingGame extends FlameGame {
  late PlayerCar player;
  List<Obstacle> obstacles = [];
  int score = 0;
  bool isGameOver = false;
  late TextComponent scoreText;
  
  double roadLeft = 0;
  double roadRight = 0;
  
  final Random random = Random();

  @override
  Future<void> onLoad() async {
    roadLeft = size.x * 0.2;
    roadRight = size.x * 0.8;
    
    player = PlayerCar(
      position: Vector2(size.x / 2 - 25, size.y - 100),
    );
    add(player);
    
    scoreText = TextComponent(
      text: 'Pontos: 0',
      position: Vector2(10, 10),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);
    
    startSpawning();
  }
  
  void startSpawning() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!isGameOver) {
        spawnObstacle();
        startSpawning();
      }
    });
  }
  
  void spawnObstacle() {
    double x = roadLeft + (roadRight - roadLeft - 40) * random.nextDouble();
    
    Obstacle obstacle = Obstacle(
      position: Vector2(x, -50),
    );
    obstacles.add(obstacle);
    add(obstacle);
  }
  
  @override
  void update(double dt) {
    if (!isGameOver) {
      // Atualiza movimento baseado nos toques (via onTapDown)
      updatePlayerMovement(dt);
      
      checkCollisions();
      
      score++;
      if (score % 60 == 0) {
        scoreText.text = 'Pontos: ${(score / 60).toInt()}';
      }
    }
  }
  
  // CONTROLES: Métodos que o Flame chama automaticamente quando toca na tela
  @override
  bool onTapDown(TapDownInfo info) {
    if (isGameOver) {
      // Reinicia o jogo
      children.clear();
      obstacles.clear();
      isGameOver = false;
      score = 0;
      onLoad();
    } else {
      // Move o carro baseado na posição do toque
      if (info.eventPosition.game.x < size.x / 2) {
        // Toque na metade ESQUERDA
        player.targetX = player.position.x - 50;
      } else {
        // Toque na metade DIREITA
        player.targetX = player.position.x + 50;
      }
    }
    return true;
  }
  
  void updatePlayerMovement(double dt) {
    // Movimento suave para a posição alvo
    if (player.targetX != null) {
      double diff = player.targetX! - player.position.x;
      player.position.x += diff * 5 * dt;
      
      // Limita dentro da pista
      player.position.x = player.position.x.clamp(roadLeft, roadRight - player.width);
      
      // Se chegou perto, para de mover
      if (diff.abs() < 1) {
        player.targetX = null;
      }
    }
  }
  
  void checkCollisions() {
    Rect playerRect = player.toRect();
    
    for (Obstacle obstacle in obstacles) {
      if (playerRect.overlaps(obstacle.toRect())) {
        gameOver();
        break;
      }
    }
  }
  
  void gameOver() {
    isGameOver = true;
    
    final gameOverText = TextComponent(
      text: 'GAME OVER\n\nSua pontuação: ${(score / 60).toInt()}\n\nToque para reiniciar',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(gameOverText);
  }
}

// ========== CARRO DO JOGADOR ==========
class PlayerCar extends RectangleComponent {
  double? targetX; // Posição alvo para movimento suave
  
  PlayerCar({required Vector2 position}) : super(
    position: position,
    size: Vector2(50, 80),
  ) {
    paint = Paint()..color = Colors.blue;
    targetX = null;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(10, 10, size.x - 20, 30),
      whitePaint,
    );
    
    final yellowPaint = Paint()..color = Colors.yellow;
    canvas.drawRect(
      Rect.fromLTWH(5, size.y - 15, 10, 10),
      yellowPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x - 15, size.y - 15, 10, 10),
      yellowPaint,
    );
    
    final blackPaint = Paint()..color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(5, size.y - 10, 12, 8),
      blackPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x - 17, size.y - 10, 12, 8),
      blackPaint,
    );
  }
}

// ========== OBSTÁCULO ==========
class Obstacle extends RectangleComponent {
  Obstacle({required Vector2 position}) : super(
    position: position,
    size: Vector2(40, 60),
  ) {
    paint = Paint()..color = Colors.red;
  }
  
  @override
  void update(double dt) {
    position.y += 300 * dt;
    
    if (position.y > 1000) {
      removeFromParent();
      final game = findParent<SimpleRacingGame>();
      if (game != null) {
        game.obstacles.remove(this);
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final darkRedPaint = Paint()..color = const Color(0xFF8B0000);
    canvas.drawRect(
      Rect.fromLTWH(5, 10, size.x - 10, 15),
      darkRedPaint,
    );
  }
}