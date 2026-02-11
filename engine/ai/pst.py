# engine/ai/pst.py
from typing import List

# Bảng điểm theo vị trí cho RED (row 9 là nhà đỏ, row 0 là nhà đen)
# Mỗi bảng là 10x9 (ROWS x COLS)
# Giá trị nhỏ thôi (5..30), vì PIECE_VALUE đã lớn rồi.

# Pawn: khuyến khích tiến lên + qua sông + đứng giữa
PAWN_RED: List[List[int]] = [
    # row 0 (đất đen) -> row 9 (đất đỏ)
    [0, 0, 0, 2, 2, 2, 0, 0, 0],   # 0
    [0, 0, 0, 2, 4, 2, 0, 0, 0],   # 1
    [0, 0, 2, 4, 6, 4, 2, 0, 0],   # 2
    [0, 2, 4, 6, 8, 6, 4, 2, 0],   # 3
    [2, 4, 6, 8, 10, 8, 6, 4, 2],  # 4  (sát sông phía đen)
    [6, 8, 10, 12, 14, 12, 10, 8, 6],  # 5 (vừa qua sông)
    [8, 10, 12, 14, 16, 14, 12, 10, 8],# 6
    [10, 12, 14, 16, 18, 16, 14, 12, 10],# 7
    [12, 14, 16, 18, 20, 18, 16, 14, 12],# 8
    [0, 0, 0, 0, 0, 0, 0, 0, 0],   # 9 (tốt không ở hàng này thường)
]

# Knight: thích trung tâm, ghét góc
KNIGHT_RED: List[List[int]] = [
    [0, 2, 4, 6, 6, 6, 4, 2, 0],
    [2, 4, 6, 8, 8, 8, 6, 4, 2],
    [4, 6, 10, 12, 12, 12, 10, 6, 4],
    [6, 8, 12, 14, 14, 14, 12, 8, 6],
    [6, 8, 12, 14, 16, 14, 12, 8, 6],
    [6, 8, 12, 14, 16, 14, 12, 8, 6],
    [6, 8, 12, 14, 14, 14, 12, 8, 6],
    [4, 6, 10, 12, 12, 12, 10, 6, 4],
    [2, 4, 6, 8, 8, 8, 6, 4, 2],
    [0, 2, 4, 6, 6, 6, 4, 2, 0],
]

# Rook: thích hoạt động (ra khỏi nhà), kiểm soát trung tâm cột
ROOK_RED: List[List[int]] = [
    [6, 8, 10, 12, 12, 12, 10, 8, 6],
    [6, 8, 10, 12, 14, 12, 10, 8, 6],
    [6, 8, 10, 12, 14, 12, 10, 8, 6],
    [6, 8, 10, 12, 14, 12, 10, 8, 6],
    [6, 8, 10, 12, 14, 12, 10, 8, 6],
    [6, 8, 10, 12, 14, 12, 10, 8, 6],
    [4, 6, 8, 10, 12, 10, 8, 6, 4],
    [2, 4, 6, 8, 10, 8, 6, 4, 2],
    [0, 2, 4, 6, 8, 6, 4, 2, 0],
    [0, 0, 0, 2, 4, 2, 0, 0, 0],
]

# Cannon: mạnh khi ở hàng trung bình (dễ có "màn"), hơi giống rook nhưng nhẹ hơn
CANNON_RED: List[List[int]] = [
    [4, 6, 8, 10, 10, 10, 8, 6, 4],
    [4, 6, 8, 10, 12, 10, 8, 6, 4],
    [4, 6, 8, 10, 12, 10, 8, 6, 4],
    [4, 6, 8, 10, 12, 10, 8, 6, 4],
    [4, 6, 8, 10, 12, 10, 8, 6, 4],
    [4, 6, 8, 10, 12, 10, 8, 6, 4],
    [2, 4, 6, 8, 10, 8, 6, 4, 2],
    [0, 2, 4, 6, 8, 6, 4, 2, 0],
    [0, 0, 2, 4, 6, 4, 2, 0, 0],
    [0, 0, 0, 2, 4, 2, 0, 0, 0],
]

# King/Advisor/Elephant: thường "ở nhà" trong cung/không qua sông, nên PST ít quan trọng
# Ta cho nhẹ để tránh AI đưa tướng ra ngoài (dù luật đã chặn trong cung)
KING_RED: List[List[int]] = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 2, 3, 2, 0, 0, 0],
    [0, 0, 0, 2, 4, 2, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 2, 4, 2, 0, 0, 0],
    [0, 0, 0, 2, 3, 2, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
]

# Map theo piece type
PST_RED = {
    "P": PAWN_RED,
    "N": KNIGHT_RED,
    "R": ROOK_RED,
    "C": CANNON_RED,
    "K": KING_RED,
    # "E","A" nếu muốn cũng có thể thêm sau
}

def pst_value(piece_type: str, color: str, row: int, col: int) -> int:
    """
    Lấy bonus PST cho quân (piece_type, color) ở (row,col).
    PST xây theo RED, nên BLACK sẽ lật theo trục ngang (row -> 9-row).
    """
    table = PST_RED.get(piece_type)

    if table is None:
        return 0
    if color == "r":
        return table[row][col]
    else:
        return table[9-row][col]
