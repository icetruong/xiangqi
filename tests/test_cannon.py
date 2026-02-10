from engine.board import Board
from engine.rules.move_rules import cannon_moves

def test_cannon_moves_like_rook_when_no_screen():
    b = Board()
    b.set(5, 4, "rC")
    moves = set(cannon_moves(b, (5, 4)))

    # đi được thẳng tới biên giống rook (vì không có màn)
    assert (0, 4) in moves
    assert (9, 4) in moves
    assert (5, 0) in moves
    assert (5, 8) in moves

def test_cannon_cannot_capture_without_screen():
    b = Board()
    b.set(5, 4, "rC")
    b.set(5, 7, "bP")  # có địch nhưng không có màn ở giữa

    moves = set(cannon_moves(b, (5, 4)))
    assert (5, 7) not in moves  # không được ăn trực tiếp
    # nhưng vẫn đi được tới trước nó
    assert (5, 6) in moves

def test_cannon_can_capture_with_exactly_one_screen():
    b = Board()
    b.set(5, 4, "rC")
    b.set(5, 6, "rP")  # màn
    b.set(5, 8, "bP")  # địch sau màn

    moves = set(cannon_moves(b, (5, 4)))

    # trước màn vẫn đi được
    assert (5, 5) in moves
    # ô màn không đi vào được theo luật pháo (không ăn như rook)
    assert (5, 6) not in moves
    # ăn được quân sau màn
    assert (5, 8) in moves
    # không đi xuyên qua quân bị ăn
    assert (5, 7) not in moves

def test_cannon_cannot_capture_same_color_after_screen():
    b = Board()
    b.set(5, 4, "rC")
    b.set(5, 6, "bP")  # màn (màn có thể là bất kỳ màu)
    b.set(5, 8, "rP")  # quân mình sau màn

    moves = set(cannon_moves(b, (5, 4)))
    assert (5, 8) not in moves  # không được ăn quân mình

def test_cannon_only_first_piece_after_screen_is_relevant():
    b = Board()
    b.set(5, 4, "rC")
    b.set(5, 6, "rP")  # màn
    b.set(5, 7, "bP")  # địch 1 (ăn được)
    b.set(5, 8, "bR")  # địch 2 (không được vì bị chặn bởi địch 1)

    moves = set(cannon_moves(b, (5, 4)))
    assert (5, 7) in moves
    assert (5, 8) not in moves

def test_cannon_blocked_immediately_by_screen_next_to_it():
    b = Board()
    b.set(5, 4, "rC")
    b.set(5, 5, "bP")  # màn ngay bên cạnh
    b.set(5, 7, "bR")  # địch sau màn

    moves = set(cannon_moves(b, (5, 4)))
    # không có ô trống trước màn
    assert (5, 5) not in moves
    # ăn được quân đầu tiên sau màn (ở đây là (5,7) nếu (5,6) trống)
    assert (5, 7) in moves
