from engine.board import Board
from engine.rules.game_rules import is_legal_move

def clear_board(b: Board):
    for r in range(b.ROWS):
        for c in range(b.COLS):
            b.set(r, c, ".")

def test_illegal_if_move_opponent_piece():
    b = Board()
    clear_board(b)
    b.set(9, 4, "rK")
    b.set(0, 4, "bK")
    b.set(5, 4, "bR")

    # turn đỏ nhưng lại đi xe đen
    assert is_legal_move(b, (5,4), (5,3), "r") is False

def test_illegal_if_self_in_check_after_move():
    b = Board()
    clear_board(b)
    b.set(9, 4, "rK")
    b.set(0, 4, "bK")

    # xe đen đang chiếu đỏ theo cột 4
    b.set(5, 4, "bR")

    # đỏ có 1 quân để chặn chiếu
    b.set(7, 4, "rR")

    # nếu đỏ đi xe rR ra chỗ khác => tướng đỏ vẫn bị chiếu => illegal
    assert is_legal_move(b, (7,4), (7,3), "r") is False

def test_legal_if_block_check():
    b = Board()
    clear_board(b)
    b.set(9, 4, "rK")
    b.set(0, 4, "bK")

    b.set(5, 4, "bR")      # chiếu
    b.set(7, 3, "rR")      # đỏ có xe để chặn

    # chặn chiếu bằng cách đi vào (7,4)
    assert is_legal_move(b, (7,3), (7,4), "r") is True

def test_illegal_if_creates_king_face():
    b = Board()
    clear_board(b)
    b.set(9, 4, "rK")
    b.set(0, 4, "bK")

    # có 1 quân chắn giữa
    b.set(5, 4, "rP")

    # nếu đỏ di chuyển quân chắn đi chỗ khác => 2 tướng đối mặt => illegal
    # giả sử rP đã qua sông rồi cho phép đi ngang: đặt ở (4,4) cho chắc
    clear_board(b)
    b.set(9, 4, "rK")
    b.set(0, 4, "bK")
    b.set(4, 4, "rP")  # đỏ đã qua sông

    assert is_legal_move(b, (4,4), (4,5), "r") is False
