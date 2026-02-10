from engine.board import Board

board = Board()
board.setup_initial();

for row in board.board:
    print(row)