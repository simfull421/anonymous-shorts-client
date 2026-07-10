-- SystemConfig
INSERT INTO SystemConfig (config_key, config_value, description) VALUES 
('BLIND_REPORT_THRESHOLD', 10, '자동 블라인드 누적 신고 임계치');

INSERT INTO SystemConfig (config_key, config_string, description) VALUES 
('REVIEWER_SECRET_CODE', '$2a$11$placeholder', '심사관 시크릿 BCrypt 해시 — 서버 시작 시 자동 갱신됨');

-- 시드 유저 지갑
INSERT IGNORE INTO UserWallet (uuid, credit_balance, role) VALUES
('seed-user-001', 5, 'User'),
('seed-user-002', 12, 'User'),
('seed-user-003', 0, 'User'),
('seed-user-004', 8, 'User'),
('seed-user-005', 15, 'User'),
('seed-user-006', 3, 'User'),
('seed-user-007', 20, 'User'),
('seed-user-008', 7, 'User'),
('seed-user-009', 11, 'User'),
('seed-user-010', 2, 'User');

-- 시드 쇼츠 30개
INSERT INTO Shorts (creator_uuid, language_code, text_content, custom_buttons, status, created_at) VALUES
('seed-user-001', 'ko', '알람 5개 맞춰놓고 결국 마지막 알람에 일어나는 사람 나만 있는 거 아니지?', '[{"index":0,"text":"나도 그럼 ㅋㅋ","votes":14},{"index":1,"text":"난 첫 알람에 일어남","votes":3}]', 'Active', UTC_TIMESTAMP() - INTERVAL 1 HOUR),
('seed-user-002', 'ko', '편의점 삼각김밥 먹을 때 김 안 찢어지고 완벽하게 열리면 오늘 운수 좋은 날이라고 생각함', '[{"index":0,"text":"인정 ㅋㅋㅋ","votes":22},{"index":1,"text":"그냥 음식인데...","votes":5}]', 'Active', UTC_TIMESTAMP() - INTERVAL 2 HOUR),
('seed-user-003', 'ko', '카페에서 노트북 펴면 일하는 척하면서 유튜브 보는 거 들킬까봐 긴장되는 건 나만 그런가', '[{"index":0,"text":"완전 공감","votes":18},{"index":1,"text":"당당하게 봄","votes":9}]', 'Active', UTC_TIMESTAMP() - INTERVAL 3 HOUR),
('seed-user-004', 'ko', '비 오는 날 창문 열고 이불 속에서 빗소리 듣는 게 세상에서 제일 행복한 순간임', '[{"index":0,"text":"최고의 힐링","votes":31},{"index":1,"text":"습해서 싫음","votes":4}]', 'Active', UTC_TIMESTAMP() - INTERVAL 4 HOUR),
('seed-user-005', 'ko', '떡볶이 먹을 때 국물에 밥 말아먹는 거 vs 그냥 떡볶이만 먹는 거', '[{"index":0,"text":"밥 필수!!","votes":27},{"index":1,"text":"떡볶이만","votes":12}]', 'Active', UTC_TIMESTAMP() - INTERVAL 2 HOUR),
('seed-user-006', 'ko', '치킨 부위 중에 제일 맛있는 건 닭다리파 vs 닭날개파', '[{"index":0,"text":"닭다리 원탑","votes":19},{"index":1,"text":"닭날개가 진리","votes":16}]', 'Active', UTC_TIMESTAMP() - INTERVAL 5 HOUR),
('seed-user-007', 'ko', '라면 끓일 때 스프 먼저 vs 면 먼저 이건 진짜 답이 있다고 생각하는데', '[{"index":0,"text":"스프 먼저","votes":13},{"index":1,"text":"면 먼저","votes":20}]', 'Active', UTC_TIMESTAMP() - INTERVAL 6 HOUR),
('seed-user-008', 'ko', '밥 먹고 나서 바로 디저트 먹는 사람들 위장이 두 개인 건지 진심 궁금함', '[{"index":0,"text":"디저트는 별도 위장","votes":25},{"index":1,"text":"배부르면 안 먹지","votes":8}]', 'Active', UTC_TIMESTAMP() - INTERVAL 3 HOUR),
('seed-user-009', 'ko', '월요일 아침 출근길에 금요일 퇴근 생각하는 사람 여기 모여라', '[{"index":0,"text":"매주 그러는 중","votes":33},{"index":1,"text":"월요일도 나쁘진 않아","votes":2}]', 'Active', UTC_TIMESTAMP() - INTERVAL 1 HOUR),
('seed-user-010', 'ko', '회의 중에 고개 끄덕이면서 사실 딴생각 하고 있는 거 실화임?', '[{"index":0,"text":"매일 그럼 ㅋ","votes":28},{"index":1,"text":"집중 잘 하는 편","votes":6}]', 'Active', UTC_TIMESTAMP() - INTERVAL 7 HOUR),
('seed-user-001', 'ko', '시험 전날에 갑자기 방 청소가 하고 싶어지는 현상 이름 있으면 알려줘', '[{"index":0,"text":"나도!! 왜 그런거냐","votes":21},{"index":1,"text":"그냥 공부해","votes":7}]', 'Active', UTC_TIMESTAMP() - INTERVAL 8 HOUR),
('seed-user-002', 'ko', '카톡 읽씹당하면 마음 접어야 하는 건지 한 번 더 보내봐야 하는 건지', '[{"index":0,"text":"읽씹은 답이다","votes":15},{"index":1,"text":"한 번 더 보내봐","votes":11}]', 'Active', UTC_TIMESTAMP() - INTERVAL 4 HOUR),
('seed-user-003', 'ko', '썸 탈 때 먼저 연락하면 지는 거라고 생각하는 사람 아직도 있음?', '[{"index":0,"text":"그건 옛날 얘기","votes":24},{"index":1,"text":"먼저 하면 진짜 짐","votes":9}]', 'Active', UTC_TIMESTAMP() - INTERVAL 9 HOUR),
('seed-user-004', 'ko', '여름에 에어컨 틀고 이불 덮는 게 인생 최대 사치라고 생각하는 사람?', '[{"index":0,"text":"이것이 진정한 럭셔리","votes":35},{"index":1,"text":"전기세 생각해","votes":6}]', 'Active', UTC_TIMESTAMP() - INTERVAL 2 HOUR),
('seed-user-005', 'ko', '겨울에 따뜻한 국밥 한 그릇 vs 여름에 시원한 냉면 한 그릇 어떤 순간이 더 행복?', '[{"index":0,"text":"겨울 국밥","votes":17},{"index":1,"text":"여름 냉면","votes":19}]', 'Active', UTC_TIMESTAMP() - INTERVAL 10 HOUR),
('seed-user-006', 'ko', '넷플릭스 켜놓고 뭐 볼지 30분째 고르다가 결국 본 거 또 보는 사람', '[{"index":0,"text":"매번 이러는 중","votes":29},{"index":1,"text":"바로 골라서 봄","votes":4}]', 'Active', UTC_TIMESTAMP() - INTERVAL 5 HOUR),
('seed-user-007', 'ko', '운동 시작한 지 3일째인데 벌써 몸 좋아진 것 같은 착각 드는 거 정상임?', '[{"index":0,"text":"거울 3번은 봄 ㅋ","votes":20},{"index":1,"text":"3일은 아직...","votes":10}]', 'Active', UTC_TIMESTAMP() - INTERVAL 6 HOUR),
('seed-user-008', 'ko', '새벽에 감성 폭발해서 쓴 메모 아침에 보면 소름끼치는 경험 해본 사람?', '[{"index":0,"text":"그래서 새벽에 안 씀","votes":16},{"index":1,"text":"새벽 감성이 진짜임","votes":12}]', 'Active', UTC_TIMESTAMP() - INTERVAL 11 HOUR),
('seed-user-009', 'ko', '양치할 때 물 먼저 묻히는 파 vs 치약 먼저 짜는 파 진지하게 궁금', '[{"index":0,"text":"물 먼저","votes":14},{"index":1,"text":"치약 먼저","votes":18}]', 'Active', UTC_TIMESTAMP() - INTERVAL 7 HOUR),
('seed-user-010', 'ko', '샤워할 때 머리부터 감는 사람 vs 몸부터 씻는 사람 비율 궁금', '[{"index":0,"text":"머리부터","votes":21},{"index":1,"text":"몸부터","votes":15}]', 'Active', UTC_TIMESTAMP() - INTERVAL 12 HOUR),
('seed-user-001', 'ko', '택배 올 때까지 문 앞 CCTV 100번은 확인하는 거 나만 그런 건 아니겠지', '[{"index":0,"text":"배송조회 중독임","votes":23},{"index":1,"text":"올 때까지 잊고 삶","votes":5}]', 'Active', UTC_TIMESTAMP() - INTERVAL 3 HOUR),
('seed-user-002', 'ko', '카페 알바할 때 손님이 아아 달라고 하면 아이스 아메리카노 맞죠? 라고 되묻는 거 필수인가', '[{"index":0,"text":"아아는 국룰이지","votes":26},{"index":1,"text":"풀네임으로 말해줘","votes":7}]', 'Active', UTC_TIMESTAMP() - INTERVAL 8 HOUR),
('seed-user-003', 'ko', '잠들기 직전에 갑자기 몸이 뚝 떨어지는 느낌 받아본 사람? 그거 뭔데 진짜', '[{"index":0,"text":"맨날 그럼 무서움","votes":30},{"index":1,"text":"한번도 안 겪음","votes":3}]', 'Active', UTC_TIMESTAMP() - INTERVAL 13 HOUR),
('seed-user-004', 'ko', '고양이가 새벽 4시에 운동회 시작하는 이유를 아는 사람 있음? 진심 궁금', '[{"index":0,"text":"야행성이라 어쩔수없음","votes":18},{"index":1,"text":"관심 달라는 거임","votes":14}]', 'Active', UTC_TIMESTAMP() - INTERVAL 9 HOUR),
('seed-user-005', 'ko', '강아지 산책 나가면 다른 강아지 만날 때 주인끼리 어색한 미소 짓는 거 웃김', '[{"index":0,"text":"매번 그 미소 ㅋㅋ","votes":22},{"index":1,"text":"나는 말 걸어봄","votes":8}]', 'Active', UTC_TIMESTAMP() - INTERVAL 14 HOUR),
('seed-user-006', 'ko', 'AI가 내 일자리 뺏을까봐 걱정되는 사람 vs AI 덕분에 더 편해질 거라고 믿는 사람', '[{"index":0,"text":"걱정된다 솔직히","votes":16},{"index":1,"text":"도구일 뿐이야","votes":19}]', 'Active', UTC_TIMESTAMP() - INTERVAL 10 HOUR),
('seed-user-007', 'ko', '스마트폰 배터리 1% 남았을 때의 긴장감이 공포영화보다 무서운 건 팩트', '[{"index":0,"text":"충전기 어디!!","votes":27},{"index":1,"text":"1%로 30분 버팀","votes":8}]', 'Active', UTC_TIMESTAMP() - INTERVAL 15 HOUR),
('seed-user-008', 'ko', '어릴 때는 어른이 되고 싶었는데 어른이 되니까 어릴 때로 돌아가고 싶은 이 모순', '[{"index":0,"text":"진짜 공감 눈물남","votes":32},{"index":1,"text":"지금이 제일 좋음","votes":5}]', 'Active', UTC_TIMESTAMP() - INTERVAL 16 HOUR),
('seed-user-009', 'ko', '혼자 있는 시간이 좋은데 외로운 건 싫은 이 복잡한 심리 이해하는 사람?', '[{"index":0,"text":"완전 내 얘기","votes":24},{"index":1,"text":"사람 만나면 해결됨","votes":6}]', 'Active', UTC_TIMESTAMP() - INTERVAL 17 HOUR),
('seed-user-010', 'ko', '지금 이 순간에도 지구 반대편에서는 누군가 아침을 먹고 있다는 게 신기하지 않음?', '[{"index":0,"text":"생각해본 적 없는데 신기","votes":15},{"index":1,"text":"당연한 거 아닌가","votes":11}]', 'Active', UTC_TIMESTAMP() - INTERVAL 18 HOUR);

-- 블라인드 테스트용
INSERT INTO Shorts (creator_uuid, language_code, text_content, custom_buttons, status, created_at) VALUES
('seed-user-003', 'ko', '이 글은 테스트용 신고 대상 게시글입니다.', '[{"index":0,"text":"신고","votes":0},{"index":1,"text":"패스","votes":0}]', 'Active', UTC_TIMESTAMP() - INTERVAL 1 HOUR);

SET @report_target = LAST_INSERT_ID();
INSERT IGNORE INTO ReportLog (target_shorts_id, reporter_uuid) VALUES
(@report_target, 'seed-reporter-001'),(@report_target, 'seed-reporter-002'),
(@report_target, 'seed-reporter-003'),(@report_target, 'seed-reporter-004'),
(@report_target, 'seed-reporter-005'),(@report_target, 'seed-reporter-006'),
(@report_target, 'seed-reporter-007'),(@report_target, 'seed-reporter-008'),
(@report_target, 'seed-reporter-009'),(@report_target, 'seed-reporter-010');
UPDATE Shorts SET status = 'Blind' WHERE id = @report_target;

SELECT CONCAT('Done! Active: ', (SELECT COUNT(*) FROM Shorts WHERE status='Active'), ', Blind: ', (SELECT COUNT(*) FROM Shorts WHERE status='Blind')) AS result;
