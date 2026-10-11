<p align="center">
  <img src="assets/images/logo.png" alt="H2Orbit logo" width="128">
</p>

# 💧 H2Orbit - Smart Water Tracker

**Stay hydrated, stay healthy.** H2Orbit is a hydration tracker for phones, the web and Windows that makes logging water a one-tap habit. It tracks your day with a live "water glass", gives tips that fit your day, adjusts your goal for hot weather, keeps streaks and shows how your habits change over time.

<p align="center">
  <img src="docs/screenshots/15-home-wide.png" alt="H2Orbit on a wide screen" width="560">
  &nbsp;&nbsp;
  <img src="docs/screenshots/04-home.png" alt="H2Orbit on a phone" width="200">
</p>

## 🎨 Logo and app icon

<p align="center">
  <img src="assets/images/logo.png" alt="H2Orbit logo (512 x 512)" width="200">
</p>

A water drop circled by an orbit: tracking every sip, day after day. Ocean teal and cyan. The same logo is the app icon on Android, iOS, the web and Windows.

## ✨ Features

- **One-tap logging** - water, juice, tea, coffee and milk presets, plus a custom amount. Every drink can be undone, and today's log lets you delete an entry (swipe or tap the ✕).
- **Live progress** - a glass that fills with animated waves inside a progress ring, with drunk / goal / to-go amounts.
- **Streaks** - a day counts when you reach your goal. Today never breaks your streak until the day is over.
- **Weather-aware goal** *(optional)* - on hot days the goal grows by 500-1000 ml, and the home screen says why.
- **Smart tips** - suggestions based on the time of day, how far behind or ahead you are, caffeine, the weather and your profile. They are rule-based and deterministic (not machine learning).
- **Analytics** - weekly bar chart with your goal line, a 30-day trend, best day, goal days, what you drink and when, data-driven insights, and eight achievement badges.
- **Reminders** - choose an interval and time window; reminders repeat daily without reopening the app. Optional celebration notifications for goals and milestones.
- **Accounts and privacy** - email sign-in, password reset, and account deletion that re-checks your password and removes all your data.
- **Offline friendly on phones** - logging works without a connection and syncs when you are back online (Firestore's offline cache is on by default on Android and iOS, not on the web).
- **Accessible and responsive** - labelled controls, respects "reduce motion", and adapts to the window: phones get the mobile layout, wide web and Windows windows get a side menu and a multi-column layout.

## 💻 Supported platforms

| Platform | Notes |
| --- | --- |
| Android | Full app, including reminders and offline logging |
| iOS | Full app, including reminders and offline logging |
| Web | Responsive: mobile layout on narrow windows, desktop layout on wide ones |
| Windows | Desktop layout with a side menu; reminders are not available |

Local reminders work on Android and iOS only; on the web and Windows the notification settings screen says so.

## 📸 Screenshots (mobile)

<table>
  <tr>
    <td align="center"><b>Welcome</b></td>
    <td align="center"><b>Sign in</b></td>
    <td align="center"><b>Create account</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/14-onboarding.png" alt="Onboarding" width="250"></td>
    <td><img src="docs/screenshots/01-sign-in.png" alt="Sign in" width="250"></td>
    <td><img src="docs/screenshots/02-register-account.png" alt="Registration, account step" width="250"></td>
  </tr>
  <tr>
    <td align="center"><b>Set your goal</b></td>
    <td align="center"><b>Home</b></td>
    <td align="center"><b>Tips and today's log</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/03-register-goal.png" alt="Registration, goal step" width="250"></td>
    <td><img src="docs/screenshots/04-home.png" alt="Home" width="250"></td>
    <td><img src="docs/screenshots/05-home-log.png" alt="Smart tips and today's log" width="250"></td>
  </tr>
  <tr>
    <td align="center"><b>Goal reached</b></td>
    <td align="center"><b>Menu</b></td>
    <td align="center"><b>Analytics</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/07-home-goal-reached.png" alt="Goal reached" width="250"></td>
    <td><img src="docs/screenshots/06-menu.png" alt="Menu" width="250"></td>
    <td><img src="docs/screenshots/08-analytics-overview.png" alt="Analytics overview" width="250"></td>
  </tr>
  <tr>
    <td align="center"><b>Achievements</b></td>
    <td align="center"><b>Week</b></td>
    <td align="center"><b>Trends</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/09-analytics-achievements.png" alt="Achievements" width="250"></td>
    <td><img src="docs/screenshots/10-analytics-week.png" alt="Weekly chart" width="250"></td>
    <td><img src="docs/screenshots/11-analytics-trends.png" alt="Trends" width="250"></td>
  </tr>
  <tr>
    <td align="center"><b>Profile</b></td>
    <td align="center"><b>Notifications</b></td>
    <td></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/12-profile.png" alt="Profile" width="250"></td>
    <td><img src="docs/screenshots/13-notifications.png" alt="Notification settings" width="250"></td>
    <td></td>
  </tr>
</table>

## 🖥️ On the web and Windows

On wide windows the slide-in menu is replaced by a side menu, and screens use several columns. Phones and narrow windows keep the mobile layout shown above.

<p align="center">
  <img src="docs/screenshots/15-home-wide.png" alt="Home on a wide screen" width="720">
</p>
<p align="center">
  <img src="docs/screenshots/16-analytics-wide.png" alt="Analytics on a wide screen" width="480">
  &nbsp;&nbsp;
  <img src="docs/screenshots/17-profile-wide.png" alt="Profile on a wide screen" width="480">
</p>

---

Built with 💥 by DarkWizardCK
