# 독백 (Dokbaek)
24시간 후 사라지는 익명 텍스트 투표 앱

[Google Play에서 보기](https://play.google.com/store/apps/details?id=com.anonymous.shorts)

## 개요
- 회원가입 없이 기기 UUID만으로 이용
- 게시물은 24시간 후 자동 소멸
- 댓글 대신 작성자가 정한 반응 버튼으로만 응답

## 기술 스택
Flutter/Dart · C#/.NET · MySQL · Railway

## 주요 구현
- 시간 감가상각 기반 피드 정렬
- 크레딧 시스템으로 읽기 전용 이용자 억제
- OpenAI Moderation API 기반 콘텐츠 검수
- 30분 주기 스케줄러로 만료 데이터 자동 파기

## 설계 기록
왜 그렇게 만들었는지 → [ADR 문서](https://shining-juice-96b.notion.site/38acbc2f0ed480cfb450cdf37022ad15?v=38acbc2f0ed4806a96e5000c0540e2d7)
