from typing import Optional, Tuple

EMPTY = 0

def in_bounds(row: int, col: int) -> bool:
    return 0 <= row < 10 and 0 <= col < 9

def in_palace(row: int, col: int, color: str) -> bool:
    if color == "b":
        return (3 <= col <= 5) and (0 <= row <= 2) 
    else:
        return (3 <= col <= 5) and (7 <= row <= 9) 

def is_empty(cell: int) -> bool:
    return cell == EMPTY

def color_of(cell: int) -> Optional[str]:
    if cell > 0:
        return "r"
    elif cell < 0:
        return "b"
    return None

PIECE_TYPE_MAP = {
    1: "K", 2: "A", 3: "E", 4: "N", 5: "R", 6: "C", 7: "P"
}

def type_of(cell: int) -> Optional[str]:
    if cell == EMPTY:
        return None
    return PIECE_TYPE_MAP.get(abs(cell))

def same_color(a: int, b: int) -> bool:
    ca = color_of(a)
    cb = color_of(b)
    return ca is not None and ca == cb

def enemy_color(color: str) -> str:
    return "r" if color == "b" else "b"
