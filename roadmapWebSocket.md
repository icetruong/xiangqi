1. Mục tiêu tổng quát

Triển khai tính năng chơi người với người theo thời gian thực bằng WebSocket trong project Django hiện tại, theo hướng:

- Người chơi tạo phòng
- Người chơi khác vào phòng
- Hai client kết nối cùng một room qua WebSocket
- Gửi và nhận nước đi realtime
- Server kiểm tra lượt đi và tính hợp lệ trước khi broadcast
- Có đồng bộ trạng thái bàn cờ khi reconnect hoặc refresh

2. Bối cảnh project hiện tại

Project đang có cấu trúc gần như sau:

- games/ là app chính
- Có models.py, views.py, urls.py, api_views.py
- Có thư mục services/
- Có templates/, static/
- Có xiangqi_project/ là config project

Yêu cầu khi code phải giữ đúng phong cách cấu trúc hiện có, ưu tiên tách logic vào services/, không nhồi toàn bộ logic vào views.py hay consumers.py.

3. Phạm vi cần làm

Cần triển khai theo thứ tự từ nền tảng đến chức năng:

Giai đoạn 1: Hạ tầng WebSocket
- Cài và cấu hình Django Channels
- Cập nhật settings.py
- Cập nhật asgi.py
- Tạo games/routing.py
- Tạo games/consumers.py
- Kết nối WebSocket theo room id

Giai đoạn 2: Quản lý phòng chơi
- Tạo model Room hoặc model tương đương để lưu:
    + mã phòng
    + người chơi đỏ
    + người chơi đen
    + trạng thái trận đấu
    + lượt hiện tại
    + trạng thái bàn cờ
    + người thắng nếu có
- Tạo API hoặc view để:
    + tạo phòng
    + tham gia phòng
    + lấy thông tin phòng
- Chỉ cho tối đa 2 người chơi trong một room nếu người thứ 3 trở lên tham gia vào thì cho họ ở chế độ xem thôi
Giai đoạn 3: Realtime move
- Khi một người chơi gửi nước đi qua WebSocket:
    + server xác định người gửi là ai
    + kiểm tra có thuộc room không
    + kiểm tra có đúng lượt không
    + kiểm tra nước đi hợp lệ bằng engine hiện có nếu tận dụng được
    + cập nhật board state
    + broadcast nước đi và trạng thái mới cho cả hai client

Giai đoạn 4: Đồng bộ trạng thái
- Khi client vừa connect hoặc reconnect:
    + server gửi toàn bộ state hiện tại của trận
    + gồm board state, lượt chơi, trạng thái room, danh tính side của người chơi
- Refresh trang không được làm mất trạng thái trận

Giai đoạn 5: Các sự kiện bổ sung
- player joined
- player left
- game over
- invalid move
- optional: surrender, restart, draw request

4. Yêu cầu kỹ thuật

Phải tuân thủ các nguyên tắc sau:

Kiến trúc
- Không viết toàn bộ nghiệp vụ trong consumer
- Tách logic vào các file trong games/services/, ví dụ:
    + room_service.py
    + match_service.py
    + move_service.py
- Consumer chỉ nên làm nhiệm vụ:
    + nhận message
    + gọi service
    + trả response / broadcast

Bảo mật và tính đúng đắn
- Không tin dữ liệu từ frontend
- Server là nơi quyết định:
    + người chơi nào được phép đi
    + nước đi có hợp lệ không
    + game đã kết thúc chưa
- Không cho người ngoài room gửi move vào room
Tương thích project
- Tận dụng engine cờ hiện có nếu project đã có logic validate nước đi
- Không phá cấu trúc cũ
- Hạn chế sửa những phần không liên quan
Code quality
- Viết code rõ ràng, có comment ngắn ở đoạn quan trọng
- Tên biến, tên hàm dễ hiểu
- Nếu cần migration thì tạo đầy đủ
- Nếu thêm dependency thì ghi rõ package cần cài

5. Danh sách file dự kiến agent cần tạo hoặc sửa
File có thể cần tạo mới
- games/consumers.py
- games/routing.py
- games/services/room_service.py
- games/services/move_service.py
- games/services/match_service.py
File có thể cần sửa
- xiangqi_project/settings.py
- xiangqi_project/asgi.py
- games/models.py
- games/views.py
- games/api_views.py
- games/urls.py
- template room hiện tại hoặc tạo template mới cho room multiplayer

6. Chuẩn message WebSocket cần thống nhất

Cần triển khai protocol JSON thống nhất.

Client → Server
- Kết nối room
    + thông qua URL websocket: /ws/game/<room_id>/

- Gửi nước đi
{
  "type": "move",
  "from": [9, 0],
  "to": [8, 0]
}
- Đầu hàng
{
  "type": "surrender"
}
Server → Client
- Kết nối thành công
{
  "type": "connection_success",
  "room_id": "abc123",
  "side": "red",
  "current_turn": "red",
  "status": "playing",
  "board_state": {}
}
- Có người vào phòng
{
  "type": "player_joined",
  "username": "player2"
}
- Nước đi hợp lệ
{
  "type": "move",
  "player": "player1",
  "side": "red",
  "from": [9, 0],
  "to": [8, 0],
  "current_turn": "black",
  "board_state": {}
}
- Báo lỗi
{
  "type": "error",
  "message": "Chưa tới lượt của bạn"
}
- Kết thúc game
{
  "type": "game_over",
  "winner": "red",
  "reason": "checkmate"
}
- Đồng bộ state
{
  "type": "sync_state",
  "room_id": "abc123",
  "status": "playing",
  "current_turn": "black",
  "board_state": {}
}

7. Thứ tự implement mong muốn

Yêu cầu làm theo từng bước, mỗi bước chạy được rồi mới sang bước tiếp:
- Bước 1: Cấu hình Channels và WebSocket route chạy được.
- Bước 2: Tạo Room model, migration, create/join room flow.
- Bước 3: Tạo consumer để 2 client vào cùng room và nhận được event join/leave.
- Bước 4: Cho gửi move realtime giữa 2 client, chưa cần validate sâu.
- Bước 5: Gắn validate turn và validate move bằng engine hiện có.
- Bước 6: Lưu board state vào DB và sync lại khi reconnect.
- Bước 7: Bổ sung game over, surrender, lỗi, logging cơ bản.

8. Definition of Done

Tính năng được coi là hoàn thành khi đạt đủ các điều kiện:
- Có thể tạo phòng và join phòng
- Hai tab trình duyệt khác nhau vào cùng room
- Kết nối WebSocket thành công cho cả hai
- Một bên đi quân thì bên kia thấy ngay realtime
- Không thể đi sai lượt
- Không thể gửi move nếu không thuộc room
- Board state không mất khi refresh
- Có thể xác định thắng thua hoặc ít nhất nhận biết game kết thúc
- Code tách lớp rõ ràng, không dồn toàn bộ vào một file

9. Ràng buộc quan trọng cho agent
- Không tự ý refactor cả project
- Chỉ thêm và sửa những phần cần thiết cho multiplayer WebSocket
- Nếu engine cờ hiện có chưa rõ, hãy tìm cách tái sử dụng trước khi viết logic mới
- Nếu phải giả định về board state format thì ghi rõ giả định đó
- Trước khi viết code, hãy phân tích nhanh cấu trúc project hiện tại và nêu danh sách file sẽ sửa

10. Thiết kế UI/UX:
Luồng:
- Người dùng vào trang chơi online. Có thể:
    + tạo phòng mới
    + nhập mã phòng để tham gia
    + hoặc chọn phòng đang chờ nếu có hỗ trợ
- Sau khi vào phòng:
    + nếu chưa đủ người thì ở trạng thái waiting
    + khi đủ 2 người thì chuyển sang playing
- Trong trận:
    + hiển thị bàn cờ
    + gửi nước đi qua WebSocket
    + nhận nước đi realtime từ đối thủ
    + cập nhật trạng thái trận
- Nếu refresh hoặc reconnect:
    + frontend tự đồng bộ lại từ server

11. Phạm vi cần làm

Frontend cần bao phủ đầy đủ 3 khu vực:
A. Entry flow
- trang lobby
- tạo phòng
- nhập mã phòng để tham gia
- điều hướng vào room
B. Room flow
- trạng thái waiting
- trạng thái playing
- trạng thái finished
C. Realtime flow
- kết nối WebSocket
- gửi move
- nhận event realtime
- reconnect và sync state

12. Nguyên tắc triển khai

Agent phải tuân thủ các nguyên tắc sau:
- Ưu tiên tận dụng giao diện bàn cờ hiện có
- Không viết lại toàn bộ frontend nếu project đã có template/JS cho bàn cờ
- Frontend không quyết định luật game
- Frontend chỉ:
    + render state từ server
    + gửi action người dùng
    + cập nhật UI theo response websocket / API
- Không tự coi nước đi là hợp lệ nếu server chưa xác nhận
- Không refactor lan rộng toàn bộ code frontend

13. Các màn hình cần có
13.1. Trang Lobby / Vào trận
Đây là trang entry để người dùng bắt đầu chơi online.
Mục tiêu
Cho phép người dùng:
- tạo phòng mới
- nhập mã phòng để tham gia
UI tối thiểu
- tiêu đề kiểu “Chơi online”
- nút Tạo phòng -> hiển thị input nhập tên người chơi nhập tên xong bấm tạo phòng
- nút Vào phòng -> hiển thị input nhập tên và mã phòng -> nhập xong bấm vào phòng
- vùng hiển thị lỗi nếu mã phòng không hợp lệ
- tùy chọn: danh sách phòng chờ
Hành vi
bấm Tạo phòng → gọi endpoint backend create room → redirect vào room page
nhập mã phòng + bấm Vào phòng → gọi endpoint join room → redirect vào room page
nếu join thất bại → hiển thị lỗi rõ ràng

13.2. Trang Room Multiplayer
Trang này là nơi xử lý cả: 
- waiting room
- game room
- finished state
Không cần tách thành nhiều trang nếu không cần. Có thể dùng một page duy nhất và đổi UI theo status.
Thông tin cần hiển thị
- room id / mã phòng
- thông tin người chơi đỏ / đen
- trạng thái trận: waiting, playing, finished
- trạng thái kết nối websocket
- current turn
- bàn cờ
- vùng thông báo hệ thống
- tùy chọn: nút đầu hàng, rời phòng

14. Các trạng thái UI cần hỗ trợ
14.1. waiting
Dùng khi chưa đủ 2 người chơi.
UI nên hiển thị:
- mã phòng
- nút copy mã phòng / copy link
- thông báo “Đang chờ người chơi còn lại”
- bàn cờ có thể hiển thị nhưng khóa thao tác
14.2. playing
Dùng khi đã đủ 2 người.
UI nên hiển thị:
- bàn cờ hoạt động
- tới lượt ai
- mình đang cầm quân nào
- nếu chưa tới lượt thì khóa thao tác hoặc chỉ cho chọn xem
14.3. finished
Dùng khi game kết thúc. 
UI nên hiển thị:
- người thắng
- lý do kết thúc nếu có
- khóa bàn cờ
nút rời phòng hoặc chơi lại nếu về sau có hỗ trợ
14.4. disconnected
Dùng khi WebSocket mất kết nối.
UI nên hiển thị:
- “Mất kết nối, đang kết nối lại...”
- khóa tạm thao tác
- khi reconnect thành công thì sync state lại từ server

15. Tổ chức code frontend
Agent nên tách frontend theo trách nhiệm, không để toàn bộ logic vào một file JS quá lớn.
Nên chia thành 3 phần
- A. UI render: Chịu trách nhiệm:
    + render thông tin room
    + render board
    + render trạng thái trận
    + render message / lỗi / kết nối
- B. WebSocket client: Chịu trách nhiệm:
    + mở kết nối
    + reconnect
    + gửi message
    + nhận message
    + chuyển message sang handler phù hợp
- C. Board interaction: Chịu trách nhiệm:
    + xử lý click chọn quân
    + chọn ô đích
    + tạo payload move
    + gọi send qua websocket
Nếu project hiện tại đã có JS bàn cờ, ưu tiên gắn thêm websocket vào logic sẵn có.

16. State frontend cần quản lý
Frontend nên có state cục bộ để render UI, ví dụ:
{
  roomId: null,
  mySide: null,
  status: "waiting",
  currentTurn: null,
  boardState: null,
  isConnected: false,
  reconnecting: false,
  selectedCell: null,
  players: {
    red: null,
    black: null
  },
  winner: null,
  systemMessage: ""
}

Lưu ý:
- đây chỉ là state render ở client
- nguồn sự thật cuối cùng vẫn là server

17. Giao tiếp với backend
17.1. HTTP/API cần dùng
Frontend sẽ cần gọi các action như:
- create room
- join room
- get room detail hoặc initial room state nếu cần
Nếu backend chưa có đủ endpoint, agent cần ghi rõ endpoint nào cần bổ sung.

17.2. WebSocket URL
Frontend cần connect theo room:
/ws/game/<room_id>/
Agent phải hỗ trợ:
- ws:// trong local/dev
- wss:// nếu production

18. Chuẩn event WebSocket cần xử lý
Agent cần viết frontend để xử lý đầy đủ các event sau từ backend:

- connection_success
Dùng khi vừa connect thành công.
Frontend cần:
- lưu roomId
- lưu mySide
- lưu status
- lưu currentTurn
- lưu board state nếu có
- render UI ban đầu
- sync_state

Dùng khi:
- vừa vào room
- reconnect
- refresh
- cần đồng bộ lại toàn bộ trận

Frontend cần:
- cập nhật full state
- render lại toàn bộ board
- cập nhật players, turn, status, winner nếu có
- player_joined
Frontend cần:
- cập nhật danh sách người chơi nếu backend trả về
- hiện thông báo
- nếu đủ 2 người và status đổi sang playing thì mở gameplay
- player_left
Frontend cần:
- hiện thông báo
- nếu trận chưa kết thúc thì có thể khóa thao tác
- cập nhật UI trạng thái chờ hoặc ngắt kết nối tùy thiết kế backend
- move
Frontend cần:
- cập nhật board state theo dữ liệu từ server
- cập nhật current turn
- render lại bàn cờ
- bỏ chọn ô đang chọn nếu có
- có thể highlight nước đi cuối nếu dễ làm
- error
Frontend cần:
- hiển thị lỗi
- không cập nhật board local sai cách
- giữ UI nhất quán
- game_over
Frontend cần:
- cập nhật trạng thái finished
- hiện winner
- khóa thao tác bàn cờ
19. Tương tác bàn cờ
Frontend cần hỗ trợ flow click như sau:
- người dùng click chọn quân
- frontend đánh dấu ô đang chọn
- người dùng click ô đích
frontend gửi lên server:
{
  "type": "move",
  "from": [x1, y1],
  "to": [x2, y2]
}
Lưu ý quan trọng
- frontend không tự chốt move là hợp lệ vĩnh viễn
- chỉ sau khi server trả event move hoặc sync_state thì mới cập nhật state chính thức
- có thể hiển thị trạng thái “đang gửi nước đi” nếu muốn, nhưng không bắt buộc ở phiên bản đầu
20. Reconnect và refresh
Agent cần hỗ trợ cơ chế reconnect cơ bản.
Yêu cầu
- khi onclose xảy ra:
- hiển thị trạng thái mất kết nối
- thử reconnect sau một khoảng thời gian hợp lý
- sau reconnect:
- chờ connection_success hoặc sync_state
- cập nhật lại toàn bộ state từ server
- refresh trang vẫn vào lại room đúng và lấy lại trạng thái trận
21. Error handling tối thiểu
Frontend phải hiển thị rõ các loại lỗi phổ biến:
- room không tồn tại
- room đã đủ người
- chưa tới lượt
- nước đi không hợp lệ
- không thuộc room
- mất kết nối websocket
- lỗi join room
- lỗi create room
Không để lỗi chỉ hiện trong console mà không có phản hồi UI.
22. UX tối thiểu nên có
Không cần đẹp ngay, nhưng nên rõ ràng:
- highlight ô đang chọn
- hiện “bạn là quân đỏ / quân đen”
- hiện “đến lượt bạn” hoặc “đang chờ đối thủ”
- hiện trạng thái kết nối
- hiện mã phòng dễ copy
- hiện lỗi dễ hiểu
- khóa thao tác khi chưa đủ 2 người hoặc không tới lượt
23. Danh sách file dự kiến cần sửa / tạo
Tùy code hiện tại, agent có thể cần sửa hoặc tạo các file như:
- template trang lobby
- template trang room multiplayer
- file JS cho WebSocket client
- file JS cho xử lý board interaction
- file CSS cơ bản nếu cần
- template hoặc JS bàn cờ hiện có để tích hợp realtime
Agent phải bắt đầu bằng việc đọc cấu trúc frontend hiện tại rồi mới quyết định file nào cần sửa.
24. Thứ tự implement mong muốn
Phase 1: Phân tích code hiện tại
- đọc cấu trúc template / static / JS hiện tại
- xác định board UI đang nằm ở đâu
- liệt kê file sẽ sửa / tạo
Phase 2: Entry flow
- làm trang lobby
- tạo luồng create room
- tạo luồng join room bằng room code
- redirect vào room page
Phase 3: Room page cơ bản
- render room page
- hiển thị waiting state
- hiển thị room id, player info, status
Phase 4: WebSocket client
- connect websocket theo room id
- xử lý onopen, onmessage, onclose, onerror
- hiển thị connection status
Phase 5: Sync state
- xử lý connection_success
- xử lý sync_state
- render board state từ server
Phase 6: Board interaction
- gắn click chọn quân / ô đích
- gửi move payload qua websocket
- chưa cần tối ưu UI phức tạp
Phase 7: Realtime update
- xử lý move
- xử lý player_joined
- xử lý player_left
- cập nhật UI đúng theo event
Phase 8: End game và lỗi
- xử lý error
- xử lý game_over
- khóa bàn cờ khi trận kết thúc
Phase 9: Reconnect
- tự reconnect khi ngắt websocket
- đồng bộ lại state sau reconnect
Phase 10: Dọn code và hướng dẫn test
- thêm comment ngắn ở đoạn quan trọng
- tóm tắt file đã sửa
- hướng dẫn test bằng 2 tab trình duyệt
25. Definition of Done
Phần frontend được coi là hoàn thành khi:
- có trang lobby để tạo phòng hoặc nhập mã phòng
- tạo phòng xong vào được room
- join phòng xong vào được room
- room page hiển thị được waiting state
- khi đủ 2 người, UI chuyển sang playing
- websocket kết nối thành công
- board render từ state server
- người dùng gửi được move
- đối thủ nhận được cập nhật realtime
- không cho thao tác sai khi chưa tới lượt hoặc chưa đủ người
- refresh vẫn đồng bộ lại trận
- hiển thị được lỗi và trạng thái mất kết nối
- hiển thị được kết thúc game