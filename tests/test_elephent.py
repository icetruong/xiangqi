from engine.board import Board
from engine.rules.move_rules import elephant_moves

def test_elephant_eye_blocked():
    b = Board()
    b.set(9, 2, "rE")      # tượng đỏ góc trái
    b.set(8, 3, "rP")      # chặn mắt tượng (8,3)

    moves = set(elephant_moves(b, (9, 2)))
    assert (7, 4) not in moves  # bị chặn nên không đi được

def test_elephant_basic_moves_red_from_corner():
    b = Board()
    b.set(9, 2, "rE")

    moves = set(elephant_moves(b, (9, 2)))
    assert (7, 0) in moves
    assert (7, 4) in moves

def test_elephant_cannot_cross_river_red():
    b = Board()
    # tượng đỏ ở gần sông: (5,2) có thể đi lên (3,0)/(3,4) nếu không chặn luật
    b.set(5, 2, "rE")

    moves = set(elephant_moves(b, (5, 2)))
    # vì đỏ không được tới row < 5
    assert (3, 0) not in moves
    assert (3, 4) not in moves

def test_elephant_cannot_cross_river_black():
    b = Board()
    # tượng đen ở (4,2) mà đi xuống (6,0)/(6,4) là qua sông -> cấm
    b.set(4, 2, "bE")

    moves = set(elephant_moves(b, (4, 2)))
    assert (6, 0) not in moves
    assert (6, 4) not in moves

def test_elephant_can_capture_enemy_not_same_color():
    b = Board()
    b.set(9, 2, "rE")
    b.set(7, 4, "bP")  # địch ở điểm đến

    moves = set(elephant_moves(b, (9, 2)))
    assert (7, 4) in moves

def test_elephant_cannot_capture_same_color():
    b = Board()
    b.set(9, 2, "rE")
    b.set(7, 4, "rP")  # quân mình

    moves = set(elephant_moves(b, (9, 2)))
    assert (7, 4) not in moves
