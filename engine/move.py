# Định nghĩa 1 nước đi
from typing import Tuple, Optional


class Move:
    # slot là giới hạn object chỉ được có những thuộc tính này
    __slots__ = ("src", "dst", "moved", "captured")

    def __init__(self, src: Tuple[int, int], dst: Tuple[int, int], moved : Optional[str] = None, captured : Optional[str] = None):
        self.src = src
        self.dst = dst
        self.moved = moved
        self.captured = captured

    def __repr__(self) -> str:
        return f"Move(src={self.src}, dst={self.dst}, moved={self.moved}, captured={self.captured})"
    


