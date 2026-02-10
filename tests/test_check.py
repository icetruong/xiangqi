from engine.board import Board
from engine.rules.check_rules import is_in_check

def empty_board_with_kings():
    b = Board()
    for r in range(b.ROWS):
        for c in range(b.COLS):
            b.set(r, c, ".")
    b.set(0, 4, "bK")
    b.set(9, 4, "rK")
    return b

def test_check_by_rook():
    b = empty_board_with_kings()
    # xe đen chiếu tướng đỏ theo cột 4
    b.set(5, 4, "bR")
    assert is_in_check(b, "r") is True
    assert is_in_check(b, "b") is False

def test_rook_check_blocked():
    b = empty_board_with_kings()
    b.set(5, 4, "bR")
    b.set(7, 4, "rP")  # chặn đường
    assert is_in_check(b, "r") is False

def test_check_by_cannon_requires_screen():
    b = empty_board_with_kings()
    b.set(5, 4, "bC")   # pháo đen cùng cột với tướng đỏ
    assert is_in_check(b, "r") is False  # chưa có màn nên không chiếu

    b.set(7, 4, "rP")   # màn giữa pháo và tướng
    assert is_in_check(b, "r") is True

def test_check_by_knight_with_leg_block():
    b = empty_board_with_kings()
    # đặt mã đen sao cho có thể chiếu tướng đỏ ở (9,4)
    # một vị trí chiếu hợp lệ: mã ở (7,3) tấn công (9,4)
    b.set(7, 3, "bN")
    assert is_in_check(b, "r") is True

    # chặn chân mã: với dr=+2,dc=+1 từ (7,3) tới (9,4)
    # leg = (8,3)
    b.set(8, 3, "rP")
    assert is_in_check(b, "r") is False
