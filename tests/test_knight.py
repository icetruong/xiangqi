from engine.board import Board
from engine.rules.move_rules import knight_moves

def test_knight_center_empty_board_has_8_moves():
    b = Board()
    b.set(5, 4, "rN")
    moves = set(knight_moves(b, (5, 4)))

    expected = {
        (3, 3), (3, 5),
        (4, 2), (4, 6),
        (6, 2), (6, 6),
        (7, 3), (7, 5)
    }
    assert moves == expected

def test_knight_blocked_leg_vertical():
    b = Board()
    b.set(5, 4, "rN")
    # chặn chân theo hướng dr=-2 (leg = (4,4))
    b.set(4, 4, "rP")

    moves = set(knight_moves(b, (5, 4)))
    # 2 nước bị chặn: (-2,-1) và (-2,1) => (3,3) (3,5)
    assert (3, 3) not in moves
    assert (3, 5) not in moves

    # các hướng khác vẫn đi được
    assert (4, 2) in moves
    assert (7, 5) in moves

def test_knight_blocked_leg_horizontal():
    b = Board()
    b.set(5, 4, "rN")
    # chặn chân theo hướng dc=+2 (leg = (5,5))
    b.set(5, 5, "bP")

    moves = set(knight_moves(b, (5, 4)))
    # 2 nước bị chặn: (-1,+2) và (+1,+2) => (4,6) (6,6)
    assert (4, 6) not in moves
    assert (6, 6) not in moves

    # hướng khác vẫn ok
    assert (3, 3) in moves
    assert (7, 3) in moves

def test_knight_cannot_capture_same_color_but_can_capture_enemy():
    b = Board()
    b.set(5, 4, "rN")
    # đặt mục tiêu ở (7,5) là quân mình -> không được ăn
    b.set(7, 5, "rP")
    # đặt mục tiêu ở (7,3) là quân địch -> ăn được
    b.set(7, 3, "bP")

    moves = set(knight_moves(b, (5, 4)))
    assert (7, 5) not in moves
    assert (7, 3) in moves

def test_knight_near_corner_has_fewer_moves():
    b = Board()
    b.set(0, 0, "rN")
    moves = set(knight_moves(b, (0, 0)))

    # từ góc (0,0) chỉ có thể tới (1,2) và (2,1) nếu không bị chặn chân
    expected = {(1, 2), (2, 1)}
    assert moves == expected
