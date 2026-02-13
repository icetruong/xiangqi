import os

# Create directory if not exists
BASE_DIR = os.path.join("games", "static", "games", "pieces")
os.makedirs(BASE_DIR, exist_ok=True)

# Chinese Characters for pieces
# Red (Traditional/Simplified mix): 帥(K) 士(A) 相(E) 傌(H) 俥(R) 炮(C) 兵(P)
# Black (Traditional/Simplified mix): 將(K) 士(A) 象(E) 馬(H)車(R) 砲(C) 卒(P)

PIECES = {
    # Red
    "rK": ("帥", "#cc0000", "#ffcccc"),
    "rA": ("士", "#cc0000", "#ffcccc"),
    "rE": ("相", "#cc0000", "#ffcccc"),
    "rH": ("傌", "#cc0000", "#ffcccc"),
    "rR": ("俥", "#cc0000", "#ffcccc"),
    "rC": ("炮", "#cc0000", "#ffcccc"),
    "rP": ("兵", "#cc0000", "#ffcccc"),
    
    # Black
    "bK": ("將", "#000000", "#ccccff"),
    "bA": ("士", "#000000", "#ccccff"), # Sometimes written differently for Black Advisor
    "bE": ("象", "#000000", "#ccccff"),
    "bH": ("馬", "#000000", "#ccccff"),
    "bR": ("車", "#000000", "#ccccff"),
    "bC": ("砲", "#000000", "#ccccff"),
    "bP": ("卒", "#000000", "#ccccff"),
}

def create_svg(filename, char, text_color, bg_color):
    svg_content = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="45" fill="{bg_color}" stroke="{text_color}" stroke-width="3" />
  <text x="50" y="65" font-family="KaiTi, SimKai, SERIF" font-size="60" text-anchor="middle" fill="{text_color}">{char}</text>
</svg>"""
    
    with open(os.path.join(BASE_DIR, filename), "w", encoding="utf-8") as f:
        f.write(svg_content)
    print(f"Created {filename}")

if __name__ == "__main__":
    for code, (char, t_col, bg_col) in PIECES.items():
        create_svg(f"{code}.svg", char, t_col, bg_col)
    
    # Create empty transparent SVG for consistency if needed? Not needed, we use <img> only if piece exists.
