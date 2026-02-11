from typing import Tuple, List

from engine.game import Game

def piece_to_char(cell: str) -> str:
    """
    Quy ước hiển thị:
      - RED: chữ HOA (R,N,E,A,K,C,P)
      - BLACK: chữ thường (r,n,e,a,k,c,p)
    """
    if cell == ".":
        return "."
    
    color = cell[0]
    t = cell[1]

    return t.lower() if color == "b" else t.upper()


def print_board(game: Game) -> None:
    b = game.board

    # turn/status (handle cả enum và string)
    turn = game.turn.value
    status = game.status.value

    print("\n" + "=" * 40)
    print(f"Turn: {turn}   Status: {status}")
    print("    c0 c1 c2 c3 c4 c5 c6 c7 c8")
    print("   +" + "---" * 9 + "+")
    for r in range(b.ROWS):
        row_cells = [piece_to_char(b.get(r, c)) for c in range(b.COLS)]
        print(f"r{r} | " + "  ".join(row_cells) + " |")
        if r == 4:
            print("   |" + "  ~~~~~~~~~ River ~~~~~~~~~  |")
    print("   +" + "---" * 9 + "+")
    print("Commands: move sr sc dr dc | undo | moves | help | quit")
    print("=" * 40)


def parse_move(parts: List[str]) -> Tuple[Tuple[int, int], Tuple[int, int]]:
    # parts = ["move", "sr", "sc", "dr", "dc"]
    if len(parts) != 5:
        raise ValueError("Format: move sr sc dr dc")
    sr = int(parts[1]); sc = int(parts[2]); dr = int(parts[3]); dc = int(parts[4])
    return (sr, sc), (dr, dc)


def main() -> None:
    game = Game()
    print_board(game)

    while True:
        try:
            cmd = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nBye bro.")
            break

        if not cmd:
            continue

        parts = cmd.split()
        action = parts[0].lower()

        if action in ("q", "quit", "exit"):
            print("Bye bro.")
            break

        if action in ("h", "help"):
            print(
                "\nHelp:\n"
                "  move sr sc dr dc   : đi 1 nước\n"
                "  undo               : quay lại 1 nước\n"
                "  moves              : in tất cả nước hợp lệ của bên đang đi (nếu Game có method get_legal_moves)\n"
                "  quit               : thoát\n"
                "Examples:\n"
                "  move 9 0 8 0\n"
                "  move 6 0 5 0\n"
            )
            continue

        if action == "undo":
            ok = game.undo()
            print("Undo OK." if ok else "Nothing to undo.")
            print_board(game)
            continue

        if action == "moves":
            # optional: nếu bro có get_legal_moves() thì show
            if hasattr(game, "get_legal_moves"):
                mv = game.get_legal_moves()  # list of ((sr,sc),(dr,dc))
                print(f"Legal moves: {len(mv)}")
                for (src, dst) in mv[:60]:
                    print(f"  {src} -> {dst}")
                if len(mv) > 60:
                    print("  ... (truncated)")
            else:
                print("Game chưa có get_legal_moves(). Nếu muốn mình viết luôn.")
            continue

        if action == "move":
            try:
                src, dst = parse_move(parts)
            except Exception as e:
                print(f"Invalid input: {e}")
                continue

            ok = game.make_move(src, dst)
            print("Move OK." if ok else "Illegal move.")
            print_board(game)

            # nếu game đã kết thúc thì báo và dừng
            status = game.status.value
            if status in ("CHECKMATE", "STALEMATE"):
                print(f"Game over: {status}")
                break
            continue

        # cho phép nhập nhanh: "sr sc dr dc" không cần chữ move
        if len(parts) == 4 and all(p.lstrip("-").isdigit() for p in parts):
            try:
                sr, sc, dr, dc = map(int, parts)
                ok = game.make_move((sr, sc), (dr, dc))
                print("Move OK." if ok else "Illegal move.")
                print_board(game)
            except Exception as e:
                print(f"Invalid input: {e}")
            continue

        print("Unknown command. Type 'help'.")


if __name__ == "__main__":
    main()