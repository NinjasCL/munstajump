// title:  👹 Munsta Jump 👹
// author: Camilo Castro (@clsource) <camilo@ninjas.cl>
// desc:   Simple Monster Jumping Game
// engine: dome (https://domeengine.com/)
// script: wren (http://wren.io)
// license: MIT
// context: DomeJam March 2020. Theme: Flow
// interpretation: An infinite flow of monsters!
// repo: https://github.com/NinjasCL/munstajump

import "graphics" for Canvas, Color
import "input" for Keyboard
import "dome" for Window, Process
import "font" for Font 
import "audio" for AudioEngine

// Random is part of the Wren Language, not the Dome Engine
import "random" for Random

class Settings {
  static scale {1}
  static width {600} // px
  static height {150}
  static title {"👹 Munsta Jump 👹"}
  static debug {false}
  static mute {false}

  static load() {
    Canvas.resize(width, height)
    Window.resize(scale * Canvas.width, scale * Canvas.height)
    Window.title = title
  }
}

class Console {
  static enabled {Settings.debug}
  static log(message) {
    // System is part of the Wren language too
    enabled ? System.print(message) : null
  }
}

class Sounds {
  static path {"./assets/sound/"}

  static jump {"jump"}
  static score {"score"}
  static hurt {"hurt"}
  static gameover {"gameover"}
  
  static load() {
    AudioEngine.load(jump, path + "jump.wav")
    AudioEngine.load(score, path + "score.wav")
    AudioEngine.load(hurt, path + "hurt.wav")
    AudioEngine.load(gameover, path + "gameover.wav")
  }

  static play(sound) {
    Settings.mute ? null : AudioEngine.play(sound)
  }

  static playJump() {
    play(jump)
  }

  static playScore() {
    play(score)
  }

  static playHurt() {
    play(hurt)
  }

  static playGameover() {
    play(gameover)
  }
}

class Colors {
  static frio { Color.hex("#F7F7F7") }
  static metal { Color.hex("#535353") }
}

class Keys {

  static enter {"enter"}
  static escape {"escape"}
  static space {"space"}
  static up {"up"}
  static left {"left"}
  static right {"right"}
  

  static isEscape() {
    return Keyboard.isKeyDown(escape)
  }

  static isSpace() {
    return Keyboard.isKeyDown(space)
  }

  static isUp() {
    return Keyboard.isKeyDown(up)
  }

  static isLeft() {
    return Keyboard.isKeyDown(left)
  }

  static isRight() {
    return Keyboard.isKeyDown(right)
  }

  static isEnter() {
    return Keyboard.isKeyDown(enter)
  }

  // Combined Keys
  static isJump() {
    return (isSpace() || isUp())
  }

  static isQuit() {
    return isEscape()
  }

  static isReset() {
    return (isEnter() || isSpace())
  }
}

class Score {
  static score() {
    if(!__score) {
      __score = 0
    }
    return __score
  }

  static inc() {
    __score = __score + 100
    if(__score > 10000000) {
      __score = 10000000
    }
  }

  static dec() {
    __score = __score - 100
  }

  static isAboveZero() {
    return __score >= 0
  }

  static isBelowZero() {
    return __score < 0
  }

  static reset() {
    __score = 0
  }

  static draw() {
    Canvas.print("Score  %(Score.score())", Canvas.width - 100, 5, Colors.metal)
  }
}

class Background {
  static draw() {
    Canvas.cls(Colors.frio)
  }
}

class Floor {
  static draw() {
    Canvas.rectfill(0, Canvas.height - 25, Canvas.width, 30, Colors.metal)
  }
}

class Monsters {
  
  static font {"monsta"}
  static fontSmall {"monsta-small"}
  static path {"./assets/fonts/monstapix/monstapix.ttf"}

  static player {"\""}
  static enemies {["A", "N", "M", "P", "X", "T", "<", "4", "v", "z", "Á", "w", "Z", "Y", "u", "U", "O", "Ü"]}

  static load () {
    Font.load(font, path, 32)
    Font.load(fontSmall, path, 18)
  }

  static draw(monster, x, y) {
    Canvas.print(monster, x, y, Colors.metal, font)
  }

  static drawSmall(monster, x, y) {
    Canvas.print(monster, x, y, Colors.metal, fontSmall)
  }

  static pickRandomEnemy() {
    var index = Random.new().int(enemies.count)
    var enemy = enemies[index]
    Console.log("Selected Enemy %(enemy)")
    return enemy
  }
  
}

class EnemyStates {
  static moving {0}
  static crash {1}
}

class HitBox {
  // Implements
  // https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection
  static collide(hitbox, hitbox2) {
    // Console.log("Checking x %(hitbox.x) y %(hitbox.y) w %(hitbox.width) h %(hitbox.height) with x %(hitbox2.x) y %(hitbox2.y) w %(hitbox2.width) h %(hitbox2.height)")
    return (hitbox.x < hitbox2.x + hitbox2.width &&
            hitbox.x + hitbox.width > hitbox2.x &&
            hitbox.y < hitbox2.y + hitbox2.height &&
            hitbox.y + hitbox.height > hitbox2.y)
  }
}

class ScoreHitBox is HitBox {
  x {_x}
  y {_y}
  width {_width}
  height {_height}
  construct new(x, y, width, height) {
    _x = x
    _y = y
    _width = width
    _height = height
  }

  update(x, y) {
    _x = x
    _y = y
  }

  draw() {
    Settings.debug ? Canvas.rect(_x, _y, _width, _height, Color.green) : null
  }
}

class EnemyHitBox is HitBox {
  x {_x}
  y {_y}
  width {_width}
  height {_height}
  construct new(x, y, width, height) {
    _x = x
    _y = y
    _width = width
    _height = height
  }

  update(x, y) {
    _x = x
    _y = y
  }

  draw() {
    Settings.debug ? Canvas.rect(_x, _y, _width, _height, Color.red) : null
  }
}

class Enemy {
  
  hitbox {_hitbox}
  scoreHitbox {_scoreHitbox}

  construct new() {
    this.reset()
  }

  reset() {
    _monster = Monsters.pickRandomEnemy()
    _xVelocity = Random.new().int(10) + 2
    _x = Canvas.width + 20
    _y = 80 - Random.new().int(20)
    _maxX = -30
    _state = EnemyStates.moving
    _hitboxY = 10
    _hitbox = EnemyHitBox.new(_x, _y + _hitboxY, 16, 32)
    _scoreHitbox = ScoreHitBox.new(_x, _y - _hitboxY * 7.5, 16, 80)
  }

  draw(player) {

    if(HitBox.collide(_hitbox, player.hitbox)) {
      Sounds.playHurt()
      Score.dec()
      return this.reset()
    }

    if(HitBox.collide(_scoreHitbox, player.hitbox)) {
      Sounds.playScore()
      Score.inc()
      return this.reset()
    }

    _x = _x - _xVelocity
    Monsters.drawSmall(_monster, _x, _y)
    _hitbox.update(_x, _y + _hitboxY)
    _scoreHitbox.update(_x, _y - _hitboxY * 7.5)
    _hitbox.draw()
    _scoreHitbox.draw()

    if(_x <= _maxX) {
      this.reset()
    }
  }
}

class PlayerStates {
  static idle {0}
  static jump {1}
  static airUp {2}
  static airDown {3}
  static hurt {4}
  static left {5}
  static right {6}
}

class PlayerHitBox is HitBox {

  x {_x}
  y {_y}
  width {_width}
  height {_height}

  construct new(x, y, width, height) {
    _x = x
    _y = y
    _width = width
    _height = height
  }

  update(x, y) {
    _x = x
    _y = y
  }

  draw() {
    Settings.debug ? Canvas.rect(_x, _y, _width, _height, Color.blue) : null
  }
}

class Player {
  
  hitbox {_hitbox}

  construct new() {
    
    _yVelocity = 10
    _xVelocity = 10

    _maxY = 60
    _minY = -20
    _minX = 10
    _maxX = Canvas.width - 25

    this.reset()
  }

  reset() {
    _x = 20
    _y = 60
    _state = PlayerStates.idle
    _hitbox = PlayerHitBox.new(_x, _y + 70, 22, 65)
  }
  
  move() {


      if(Keys.isJump() && _state == PlayerStates.idle) {
        Console.log("Jump!")
        _state = PlayerStates.jump
        Sounds.playJump()
      }

      if(_state == PlayerStates.jump || _state == PlayerStates.airUp) {
        _state = PlayerStates.airUp
        _y = _y - _yVelocity
      }

      if(_y <= _minY || _state == PlayerStates.airDown) {
          _state = PlayerStates.airDown
          _y = _y + _yVelocity

          if(_y >= _maxY) {
            _state = PlayerStates.idle
            _y = _maxY
          }
      }

      // Only allow horizontal movement while jumping
      if(Keys.isJump()) {
        if(Keys.isLeft()) {
          Console.log("Left!")
          _x = _x - _xVelocity
          if(_x <= _minX) {
            _x = _minX
          }
        }

        if(Keys.isRight()) {
          Console.log("Right!")
          _x = _x + _xVelocity
          if(_x >= _maxX) {
            _x = _maxX
          }
        }
      }

      _hitbox.update(_x, _y)
  }

  draw() {
    this.move()
    Monsters.draw(Monsters.player, _x, _y)
    _hitbox.draw()
  }
}


class GameStates {
  static play {1}
  static over {2}

  static state() {
    return __state
  }

  static setState(state) {
    __state = state
  }

  static reset() {
    setState(play)
  }

  static setGameOver() {
    setState(over)
  }

  static canPlay() {
    return (Score.isAboveZero() && state() == play)
  }
}

class GameOver {
  static draw() {
    Canvas.print("Game Over", 260, 75, Colors.metal)
  }
}

// Just load the files once
Settings.load()
Monsters.load()
Sounds.load()

class Game {
    
    static init() {
      
      Score.reset()
      __player = Player.new()
      __enemy = Enemy.new()
      __playedGameOverSound = false
      GameStates.reset()
    }

    static update() {
      if(Keys.isQuit()) {
        Console.log("Thank you for playing. bye bye~~")
        Process.exit()
      }
    }

    static draw(dt) {
      
      Background.draw()
      Floor.draw()
      
      if(GameStates.canPlay()) {
        Score.draw()
        __player.draw()
        __enemy.draw(__player)
        return 
      }

      Console.log("Game Over")
      
      if(!__playedGameOverSound) {
        Sounds.playGameover()
        __playedGameOverSound = true
      }

      GameStates.setGameOver()
      GameOver.draw()

      Console.log("Press Enter or Space to Reset Game")
      if(Keys.isReset()) {
        Game.init()
      }
    }
}
