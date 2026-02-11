# examples/play_with_ai_console.py

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
    turn = game.turn.value
    status = game.status.value

    print("\n" + "=" * 50)
    print(f"Turn: {turn}   Status: {status}")
    print("    0 1 2 3 4 5 6 7 8")
    print("   +" + "--" * 9 + "+")

    for r in range(b.ROWS):
        row = [piece_to_char(b.get(r, c)) for c in range(b.COLS)]
        print(f"{r:2} | " + " ".join(row) + " |")
        if r == 4:
            print("   | ~ ~ ~ ~ River ~ ~ ~ ~ |")

    print("   +" + "--" * 9 + "+")
    print("Commands:")
    print("  move sr sc dr dc")
    print("  undo")
    print("  fen")
    print("  load <fen>")
    print("  ai <depth>")
    print("  quit")
    print("=" * 50)


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
        turn = game.turn.value

        # AI turn
        if turn == ai_color:
            print("\nAI thinking...")
            game.ai_move_minimax(depth=3)
            print_board(game)

            if game.status.value in ("CHECKMATE", "STALEMATE"):
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

                if game.status.value in ("CHECKMATE", "STALEMATE"):
                    print("Game over.")
                    break

            except:
                print("Invalid input.")
            continue

        print("Unknown command.")


if __name__ == "__main__":
    main()
