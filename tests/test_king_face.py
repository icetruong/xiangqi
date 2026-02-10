from engine.board import Board
from engine.rules.king_face_rule import kings_face_each_other

def test_kings_face_each_other_true_when_same_file_no_block():
    b = Board()
    # clear board
    for r in range(b.ROWS):
        for c in range(b.COLS):
            b.set(r, c, ".")

    b.set(0, 4, "bK")
    b.set(9, 4, "rK")

    assert kings_face_each_other(b) is True

def test_kings_face_each_other_false_when_blocked():
    b = Board()
    for r in range(b.ROWS):
        for c in range(b.COLS):
            b.set(r, c, ".")

    b.set(0, 4, "bK")
    b.set(9, 4, "rK")
    b.set(5, 4, "rP")  # quân chắn giữa

    assert kings_face_each_other(b) is False

def test_kings_face_each_other_false_when_different_column():
    b = Board()
    for r in range(b.ROWS):
        for c in range(b.COLS):
            b.set(r, c, ".")

    b.set(0, 3, "bK")
    b.set(9, 4, "rK")

    assert kings_face_each_other(b) is False
