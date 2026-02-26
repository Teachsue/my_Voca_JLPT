<p align="center">
  <img src="assets/icon.png" width="120" height="120" alt="냥냥 일본어 로고">
</p>

# 🌸 냥냥 일본어 (Nyang Nyang Japanese) - JLPT 단어장

**냥냥 일본어**는 JLPT(일본어 능력 시험) 합격을 목표로 하는 초보자부터 상급자까지, N1부터 N5까지의 필수 단어를 쉽고 체계적으로 암기할 수 있도록 도와주는 감성적인 Flutter 기반 어플리케이션입니다.

---

## ✨ 이번 업데이트의 주요 특징 (New Features)

기존 단어장 기능에 더해, 학습자의 감성을 자극하고 초보자 편의를 극대화하는 기능들이 대거 추가되었습니다.

### 1. 🎨 사계절 테마 시스템 (Seasonal Background)
*   **지능형 계절 감지**: 현재 날짜에 맞춰 일본의 사계절(봄🌸, 여름🌊, 가을🍁, 겨울❄️)을 담은 아름다운 배경과 데코레이션 아이콘이 자동으로 적용됩니다.
*   **테마 고정 기능**: 설정 페이지에서 자신이 가장 좋아하는 계절을 직접 선택하여 고정할 수 있습니다.

### 2. 🌙 다크 모드 (Midnight Theme)
*   밤에도 눈의 피로 없이 학습할 수 있는 **심야 테마**를 지원합니다.
*   깊은 네이비와 그레이 블루 그라데이션, 그리고 은은한 **달빛(`nights_stay`) 아이콘**으로 고급스러운 분위기를 연출합니다.

### 3. 📚 기초 다지기 (히라가나/가타카나 사전)
*   일본어의 시작인 문자를 **행(Row) 단위**로 깔끔하게 정리했습니다.
*   학습 후 즉시 확인 가능한 **'해당 행 집중 퀴즈'**와 **'전체 문항 퀴즈'** 기능을 제공합니다.

### 4. 🧠 정밀 실력 진단 테스트
*   N1~N5 전 범위를 아우르는 30문항으로 자신의 실력을 정확히 판정받고 추천 레벨을 부여받을 수 있습니다.
*   **문제 유형 다양화**: 뜻 고르기, 한자 고르기, 가나 고르기 등 다양한 유형을 제공합니다.

### 5. 🛠 사용자 경험(UX) 최적화
*   **잔상 없는 페이지 전환**: 책장을 넘기는 듯한 부드러운 슬라이드와 배경 고정 기술로 시각적 노이즈를 완전히 제거했습니다.
*   **대시보드 레이아웃**: 모든 핵심 기능을 스크롤 없이 한 화면에 큼직한 글씨로 담아낸 컴팩트한 메인 UI를 제공합니다.

---

## 📱 주요 기능

- **레벨별 단어 학습**: JLPT N1 ~ N5 단계별 필수 단어 제공
- **에빙하우스 복습 시스템 (SRS)**: 망각 곡선을 기반으로 최적화된 복습 알고리즘 적용
- **오늘의 단어**: 매일 10개씩 꾸준히 학습할 수 있는 맞춤형 세션
- **오답노트 & 북마크**: 틀린 단어 집중 학습 및 중요 단어 별도 관리
- **학습 통계 & 캘린더**: 나의 진도율과 연속 학습 일수를 시각적으로 확인

---

## 📸 Screenshots

| 메인 화면 | 단어 리스트 | 퀴즈 화면 |
| <img src="screenshots/home.png" width="200"> | <img src="screenshots/list.png" width="200"> | <img src="screenshots/quiz.png" width="200"> |

| 학습 통계 | 오답노트 | 실력 테스트 |
| <img src="screenshots/stats.png" width="200"> | <img src="screenshots/wrong.png" width="200"> | <img src="screenshots/test.png" width="200"> |

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Material 3)
- **Language**: [Dart](https://dart.dev/)
- **Database**: [Hive](https://pub.dev/packages/hive) (고성능 로컬 NoSQL 데이터베이스)
- **State Management**: [Provider](https://pub.dev/packages/provider), ValueListenable
- **Animations**: Custom PageTransitions (Smooth Slide & Fade)
- **Localization**: `Intl` (날짜 및 숫자 지역화)

---

## 🚀 시작하기

1. 저장소 클론: `git clone https://github.com/your-username/my_voca_japan_app.git`
2. 패키지 설치: `flutter pub get`
3. Hive 어댑터 생성: `dart run build_runner build`
4. 앱 실행: `flutter run`

---
*JLPT 합격을 응원합니다! 냥냥 일본어와 함께 즐겁게 공부하세요! 🇯🇵*
