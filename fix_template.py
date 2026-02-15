import os

filepath = os.path.join(os.path.dirname(__file__), 'games', 'templates', 'games', 'game.html')

content = r'''{% load static %}
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xiangqi Game</title>
    <link rel="stylesheet" href="{% static 'games/css/style.css' %}">
    <link href="https://fonts.googleapis.com/css2?family=Ma+Shan+Zheng&family=Noto+Sans+SC:wght@400;700&display=swap" rel="stylesheet">
</head>

<body>
    <div class="main-container">
        <div class="game-area">
            <div class="board-wrapper">
                <div class="board-inner" id="board"></div>
            </div>
        </div>
    </div>

    <script src="{% static 'games/js/game.js' %}"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            var movesData = {{ legal_moves|default:"[]"|safe }};
            initGame({
                gameId: "{{ game.id }}",
                boardState: {{ game.board_state|safe }},
                currentTurn: "{{ game.current_turn }}",
                status: "{{ game.status }}",
                playerSide: "{{ game.player_side }}",
                aiSide: "{{ game.ai_side }}",
                legalMoves: movesData
            });
        });
    </script>
</body>

</html>
'''

with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)

print(f"Written {len(content)} bytes to {filepath}")

# Verify
with open(filepath, 'r', encoding='utf-8') as f:
    verify = f.read()

if 'default:"[]"|safe' in verify:
    print("SUCCESS: Template syntax is correct")
else:
    print("FAIL: Template syntax is still wrong")
    for i, line in enumerate(verify.split('\n'), 1):
        if 'default' in line or 'movesData' in line:
            print(f"  Line {i}: {line!r}")
