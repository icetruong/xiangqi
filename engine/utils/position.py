from typing import Optional, Tuple

EMPTY = "."

def in_bounds(row: int, col: int) -> bool:
    return 0 <= row < 10 and 0 <= col < 9

def in_palace(row: int, col: int, color: str) -> bool:
    if color == "b":
        return (3 <= col <= 5) and (0 <= row <= 2) 
    else:
        return (3 <= col <= 5) and (7 <= row <= 9) 

def is_empty(cell: str) -> bool:
    return cell == EMPTY

def color_of(cell: str) -> Optional[str]:
    return None if cell == EMPTY else cell[0]

def type_of(cell: str) -> Optional[str]:
    return None if cell == EMPTY else cell[1]

def same_color(a: str, b: str) -> bool:
    ca = color_of(a)
    cb = color_of(b)
    return ca is not None and ca == cb

def enemy_color(color: str) -> str:
    return "r" if color == "b" else "b"