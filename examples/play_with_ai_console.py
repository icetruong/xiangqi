from engine.game import Game
from engine.serializer.fen import board_to_fen, load_fen

def piece_to_char(cell: str) -> str:
    if cell == ".":
        return "."
    color = cell[0]
    t = cell[1]
    return t.upper() if color == "r" else t.lower()


def print_board(game: Game):
    b = game.board
    turn = getattr(game.turn, "value", game.turn)
    status = getattr(game.status, "value", game.status)

    # Các dòng command sẽ hiển thị bên phải (mỗi dòng ứng với 1 dòng board)
    cmd_lines = [
        "Commands:",
        "  move sr sc dr dc",
        "  undo",
        "  fen",
        "  load <fen>",
        "  ai <depth>",
        "  quit",
    ]

    # Header trái (board)
    header1 = f"Turn: {turn}   Status: {status}"
    header2 = "    0 1 2 3 4 5 6 7 8"
    top_border = "   +" + "--" * 9 + "+"

    # độ rộng cố định cho phần board để canh phải đẹp
    # (board_line sẽ luôn ~ 4 + 2*9 + 4 ký tự)
    def right(i: int) -> str:
        return cmd_lines[i] if 0 <= i < len(cmd_lines) else ""

    print("\n" + "=" * 80)
    # in header + command (2 dòng đầu)
    print(f"{header1:<30}   {right(0)}")
    print(f"{header2:<30}   {right(1)}")
    print(f"{top_border:<30}   {right(2)}")

    # in 10 hàng board; chèn dòng River sau r==4
    cmd_idx = 3  # tiếp tục từ cmd_lines[3]
    for r in range(b.ROWS):
        row_cells = [piece_to_char(b.get(r, c)) for c in range(b.COLS)]
        left_line = f"{r:2} | " + " ".join(row_cells) + " |"
        print(f"{left_line:<30}   {right(cmd_idx)}")
        cmd_idx += 1

        if r == 4:
            river_line = "   | ~ ~ ~ ~ River ~ ~ ~ ~ |"
            print(f"{river_line:<30}   {right(cmd_idx)}")
            cmd_idx += 1

    bottom_border = "   +" + "--" * 9 + "+"
    print(f"{bottom_border:<30}   {right(cmd_idx)}")
    print("=" * 80)


def main():
    game = Game()

    print("Choose your side:")
    print("  r = Red (go first)")
    print("  b = Black")
    human = input("> ").strip().lower()
    if human not in ("r", "b"):
        human = "r"

    ai_color = "b" if human == "r" else "r"

    print_board(game)

    while True:
        turn = getattr(game.turn, "value", game.turn)

        # AI turn
        if turn == ai_color:
            print("\nAI thinking...")
            game.ai_move_minimax(depth=3)
            print_board(game)

            if getattr(game.status, "value", game.status) in ("CHECKMATE", "STALEMATE"):
                print("Game over.")
                break
            continue

        # Human turn
        cmd = input("> ").strip()
        if not cmd:
            continue

        parts = cmd.split()
        action = parts[0].lower()

        if action in ("q", "quit", "exit"):
            print("Bye bro.")
            break

        if action == "undo":
            game.undo()
            game.undo()  # undo cả AI move
            print_board(game)
            continue

        if action == "fen":
            print(board_to_fen(game.board, turn))
            continue

        if action == "load":
            if len(parts) < 2:
                print("Usage: load <fen_string>")
                continue
            fen_str = " ".join(parts[1:])
            t = load_fen(game.board, fen_str)
            if t:
                # nếu Game.turn là enum Color thì cần ép: game.turn = Color(t)
                # còn nếu đang dùng string thì set trực tiếp
                game.turn = t
            print_board(game)
            continue

        if action == "ai":
            depth = 3
            if len(parts) > 1 and parts[1].isdigit():
                depth = int(parts[1])
            game.ai_move_minimax(depth=depth)
            print_board(game)
            continue

        if action == "move":
            if len(parts) != 5:
                print("Format: move sr sc dr dc")
                continue
            try:
                sr, sc, dr, dc = map(int, parts[1:])
                ok = game.make_move((sr, sc), (dr, dc))
                if not ok:
                    print("Illegal move.")
                print_board(game)

                if getattr(game.status, "value", game.status) in ("CHECKMATE", "STALEMATE"):
                    print("Game over.")
                    break

            except:
                print("Invalid input.")
            continue

        print("Unknown command.")


if __name__ == "__main__":
    main()
