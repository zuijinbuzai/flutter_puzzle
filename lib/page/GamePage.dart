import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_puzzle/magic/GameEngine.dart';
import 'package:flutter_puzzle/magic/GamePainter.dart';
import 'package:flutter_puzzle/magic/ImageNode.dart';
import 'package:flutter_puzzle/magic/PuzzleMagic.dart';

class GamePage extends StatefulWidget {
  final Size size;
  final String imgPath;
  final int level;
  GamePage(this.size, this.imgPath, this.level);

  @override
  State<StatefulWidget> createState() {
    return GamePageState(size, imgPath, level);
  }
}

enum Direction { none, left, right, top, bottom }
enum GameState { loading, play, complete }

class GamePageState extends State<GamePage> with TickerProviderStateMixin {
  final Size size;
  var image;
  PuzzleMagic puzzleMagic;
  List<ImageNode> nodes;

  Animation<int> alpha;
  AnimationController controller;
  Map<int, ImageNode> nodeMap = Map();

  int level;
  String path;
  ImageNode hitNode;

  double downX, downY, newX, newY;
  int emptyIndex;
  Direction direction;
  bool needdraw = true;
  List<ImageNode> hitNodeList = [];

  GameState gameState = GameState.loading;

  GamePageState(this.size, this.path, this.level) {
    puzzleMagic = PuzzleMagic();
    emptyIndex = level * level - 1;

    puzzleMagic.init(path, size, level).then((val) {
      setState(() {
        nodes = puzzleMagic.doTask();
        GameEngine.makeRandom(nodes);
        setState(() {
          gameState = GameState.play;
        });
        showStartAnimation();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (gameState == GameState.loading) {
      return Center(
        child: Text('Loading'),
      );
    } else if (gameState == GameState.complete) {
      return Center(
          child: RaisedButton(
        child: Text('Restart'),
        onPressed: () {
          GameEngine.makeRandom(nodes);
          setState(() {
            gameState = GameState.play;
          });
          showStartAnimation();
        },
      ));
    } else {
      return Stack(
        children: [
          GestureDetector(
            child: CustomPaint(
                painter: GamePainter(nodes, level, hitNode, hitNodeList,
                    direction, downX, downY, newX, newY, needdraw),
                size: Size.infinite),
            onPanDown: onPanDown,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanUp,
          ),
        ],
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void showStartAnimation() {
    needdraw = true;
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    alpha = IntTween(begin: 0, end: 100).animate(controller);
    nodes.forEach((node) {
      nodeMap[node.curIndex] = node;

      Rect rect = node.rect;
      Rect dstRect = puzzleMagic.getOkRectF(
          node.curIndex % level, (node.curIndex / level).floor());

      final double deltX = dstRect.left - rect.left;
      final double deltY = dstRect.top - rect.top;

      final double oldX = rect.left;
      final double oldY = rect.top;

      alpha.addListener(() {
        double oldNewX2 = alpha.value * deltX / 100;
        double oldNewY2 = alpha.value * deltY / 100;
        setState(() {
          node.rect = Rect.fromLTWH(
              oldX + oldNewX2, oldY + oldNewY2, rect.width, rect.height);
        });
      });
    });
    alpha.addStatusListener((AnimationStatus val) {
      if (val == AnimationStatus.completed) {
        needdraw = false;
      }
    });
    controller.forward();
  }

  void onPanDown(DragDownDetails details) {
    if (controller != null && controller.isAnimating) {
      return;
    }

    needdraw = true;
    RenderBox referenceBox = context.findRenderObject();
    Offset localPosition = referenceBox.globalToLocal(details.globalPosition);
    for (int i = 0; i < nodes.length; i++) {
      ImageNode node = nodes[i];
      if (node.rect.contains(localPosition)) {
        hitNode = node;
        direction = isBetween(hitNode, emptyIndex);
        if (direction != Direction.none) {
          newX = downX = localPosition.dx;
          newY = downY = localPosition.dy;

          nodes.remove(hitNode);
          nodes.add(hitNode);
        }
        setState(() {});
        break;
      }
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (hitNode == null) {
      return;
    }
    RenderBox referenceBox = context.findRenderObject();
    Offset localPosition = referenceBox.globalToLocal(details.globalPosition);
    newX = localPosition.dx;
    newY = localPosition.dy;
    if (direction == Direction.top) {
      newY = min(downY, max(newY, downY - hitNode.rect.width));
    } else if (direction == Direction.bottom) {
      newY = max(downY, min(newY, downY + hitNode.rect.width));
    } else if (direction == Direction.left) {
      newX = min(downX, max(newX, downX - hitNode.rect.width));
    } else if (direction == Direction.right) {
      newX = max(downX, min(newX, downX + hitNode.rect.width));
    }

    setState(() {});
  }

  void onPanUp(DragEndDetails details) {
    if (hitNode == null) {
      return;
    }
    needdraw = false;
    if (direction == Direction.top) {
      if (-(newY - downY) > hitNode.rect.width / 2) {
        swapEmpty();
      }
    } else if (direction == Direction.bottom) {
      if (newY - downY > hitNode.rect.width / 2) {
        swapEmpty();
      }
    } else if (direction == Direction.left) {
      if (-(newX - downX) > hitNode.rect.width / 2) {
        swapEmpty();
      }
    } else if (direction == Direction.right) {
      if (newX - downX > hitNode.rect.width / 2) {
        swapEmpty();
      }
    }

    hitNodeList.clear();
    hitNode = null;

    var isComplete = true;
    nodes.forEach((node) {
      if (node.curIndex != node.index) {
        isComplete = false;
      }
    });
    if (isComplete) {
      gameState = GameState.complete;
    }

    setState(() {});
  }

  Direction isBetween(ImageNode node, int emptyIndex) {
    int x = emptyIndex % level;
    int y = (emptyIndex / level).floor();

    int x2 = node.curIndex % level;
    int y2 = (node.curIndex / level).floor();

    if (x == x2) {
      if (y2 < y) {
        for (int index = y2; index < y; ++index) {
          hitNodeList.add(nodeMap[index * level + x]);
        }
        return Direction.bottom;
      } else if (y2 > y) {
        for (int index = y2; index > y; --index) {
          hitNodeList.add(nodeMap[index * level + x]);
        }
        return Direction.top;
      }
    }
    if (y == y2) {
      if (x2 < x) {
        for (int index = x2; index < x; ++index) {
          hitNodeList.add(nodeMap[y * level + index]);
        }
        return Direction.right;
      } else if (x2 > x) {
        for (int index = x2; index > x; --index) {
          hitNodeList.add(nodeMap[y * level + index]);
        }
        return Direction.left;
      }
    }
    return Direction.none;
  }

  void swapEmpty() {
    int v = -level;
    if (direction == Direction.right) {
      v = 1;
    } else if (direction == Direction.left) {
      v = -1;
    } else if (direction == Direction.bottom) {
      v = level;
    }
    hitNodeList.forEach((node) {
      node.curIndex += v;
      nodeMap[node.curIndex] = node;
      node.rect = puzzleMagic.getOkRectF(
          node.curIndex % level, (node.curIndex / level).floor());
    });
    emptyIndex -= v * hitNodeList.length;
  }
}
