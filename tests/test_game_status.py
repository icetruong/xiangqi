from engine.board import Board
from engine.game import Game
from engine.enums import Color, GameStatus

def clear_board(b: Board):
    for r in range(b.ROWS):
        for c in range(b.COLS):
            b.set(r, c, ".")

def test_status_check():
    g = Game()
    clear_board(g.board)

    # đặt 2 tướng
    g.board.set(9, 4, "rK")
    g.board.set(0, 4, "bK")

    # đến lượt đỏ
    g.turn = Color.RED

    # đặt xe đen chiếu tướng đỏ (cùng cột 4)
    g.board.set(5, 4, "bR")

    g._update_status()

    # status là enum
    assert g.status == GameStatus.CHECK
    # (tuỳ thích) check string helper
    assert g.get_status() == GameStatus.CHECK.value
