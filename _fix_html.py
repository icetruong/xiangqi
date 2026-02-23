content = """\
{% load static %}
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xiangqi Game</title>
    <link rel="icon" type="image/svg+xml" href="{% static 'games/img/favicon.svg' %}">
    <link rel="stylesheet" href="{% static 'games/css/style.css' %}">
    <link href="https://fonts.googleapis.com/css2?family=Ma+Shan+Zheng&family=Noto+Sans+SC:wght@400;700&display=swap"
        rel="stylesheet">
</head>

<body>
    <div class="main-container">
        <div class="game-area">
            <div class="board-wrapper">
                <div class="board-inner" id="board"></div>
            </div>
        </div>
    </div>

    <!-- game.js MUST come before the inline script so initGame() is defined -->
    <script src="{% static 'games/js/game.js' %}"></script>
    <script>
        initGame({
            gameId: "{{ game.id }}",
            boardState: {{ game.board_state|safe }},
            currentTurn: "{{ game.current_turn }}",
            status: "{{ game.status }}",
            playerSide: "{{ game.player_side }}",
            aiSide: "{{ game.ai_side }}",
            legalMoves: {{ legal_moves|default:"[]"|safe }}
        });
    </script>
</body>

</html>
"""

with open(
    r"d:\TaiLieuNam3_DUT\HKII\Python\xiangqi\games\templates\games\game.html",
    "w",
    encoding="utf-8",
    newline="\r\n",
) as f:
    f.write(content)

print("OK - file written successfully")
