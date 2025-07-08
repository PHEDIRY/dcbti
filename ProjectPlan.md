---
title: "Development Plan for dCBT-i Mobile App"
description: "Detailed outline of purpose, features, technologies, and action items."
update date: "2025-07-02"
author: "Ed Yang"
---

1. Purpose and Scope

Goal: Deliver accessible, high-quality digital Cognitive Behaviour Therapy for insomnia (dCBT-i) in Taiwan.
Target Users: People in Taiwan suffering from insomnia.
Core Problem: Low accessibility to evidence-based insomnia therapies.

2. Functionality & Features

mainly online-only
MVP (First Launch)

Sleep Diary: Daily entries, sleep/wake time tracking, sleep quality rating.
Assessments: Insomnia Severity Index (ISI), Pittsburgh Sleep Quality Index (PSQI), depression/anxiety screenings.
User Authentication: Secure login/sign-up via Firebase Auth.

Secondary Features (Post-MVP)

Educational Modules: CBT-i modules (sleep hygiene, stimulus control, relaxation training, cognitive restructuring).
Sleep Data Analysis: Automatic calculation and visualization of sleep metrics.
Push Notifications: Reminders for diary entries, assessments, educational content. (customizable)
Payments: Integration for subscription/premium access (available at MVP); Taiwanese customer friendly

3️. Platforms & Technology

Platform: Flutter + Dart (latest Android & iOS versions).
Backend: Firebase (Authentication, Firestore database, Cloud Messaging, Analytics, Functions).
Version Control: GitHub.
Development OS: Windows

4. UX/UI Design
Try to use Apple's Human Interface Guidelines, let's make something sleek, sexy, modern, and easy to use, with nice animations too if we can.
Really modern and sexy sleek minimal apple style MacOS style UI design, make it sexy, sleek. Animations, UI. Modern, amazing STEVE JOBS LEVEL lets GO! Always reaffirm to me that we are doing it using Apple Guidelines and how we used them in this design.

No prototype. Start from scratch using Apple's and Android's guidelines

Language: Traditional Chinese

5. Data & Backend

Remote data storage (Firestore).
Essential backend services:
Authentication (Firebase Auth): email/password
Database (Firestore)
Analytics (Firebase Analytics)
Push Notifications (Firebase Cloud Messaging)
Payments (Stripe via Firebase Extensions)

6. Development Approach

Waterfall Model:
Planning & Design
Implementation
Integration & Testing
Deployment
Maintenance (weekly updates)
GitHub for version control.
Potential CI/CD: GitHub Actions or Codemagic (help me )

7. Testing & QA

Preferred: Integration Testing, User Acceptance Testing (UAT).
Automate testing (Flutter's integration_test package).
AI-Help Needed: Generate automated integration test scripts.

8. Deployment & Distribution

Review Apple App Store & Google Play Store guidelines ASAP.
Plan weekly updates post-launch.

9. Performance & Analytics

Firebase Analytics for user engagement.
Firebase Crashlytics and Performance Monitoring recommended.

10. Legal & Security

Comply with Taiwan PDPA.
Data Security: Firebase Security Rules, data encryption.
Privacy Policy and Terms of Service clearly presented in-app.

11. Maintenance & Support

Weekly updates post-launch.
Continuous customer feedback implementation via AI-driven coding.

12. Monetization

Subscription model with advertisements
Freemium (basic features are free, advanced features are paid)

Modular Task Chunks for dCBT-i Mobile App Development
1. Project Setup & Tooling (done)
Initialize Flutter project (with null safety, iOS/Android support) (done)
Set up GitHub repository and .gitignore (done)

Configure CI/CD (GitHub Actions or Codemagic)
Set up project structure for modularity (feature folders, shared, core, etc.)

2. Core Infrastructure
Integrate Firebase into Flutter (Auth, Firestore, Messaging, Analytics)
Set up environment configuration (dev/prod, secrets management)
Implement localization (Traditional Chinese support)

3. Authentication Module
Email/password sign-up, login, logout
Password reset flow
Authentication state management (provider, bloc, or riverpod)
User profile basic setup

4. Sleep Diary Module
Data models for diary entries (done)
UI for daily entry (done)
- date of the entry
- what time did you get into bed?
- quality rating
- how long did it take you to fall asleep?
- how many times did you wake up, not counting your final awakening?
- for each time you woke up (if happened), what time did you wake up?
- for each time you woke up (if happened), did you get out of bed? if yes, for how long?
- for each time you woke up (if happened), how long did you stay in bed?
- what time was your final awakening?
- what time did you get out of bed for the day?
- during the previous day (between sleeping periods) did you consume caffeine (coffee, tea, energy drinks)? if yes, at what time?
- during the previous day (between sleeping periods) did you consume alcohol? if yes, at what time?
- during the previous day (between sleeping periods) did you take sleep medicines? if yes, at what time?
- during the previous day (between sleeping periods) did you smoke? if yes, at what time?
- during the previous day (between sleeping periods) did you exercise? if yes, at what time?
- during the previous day (between sleeping periods) when did you have your last meal or night snacks?
- select all tags that were relevant to your sleep: daytime activities (exercise, nap longer than 30 min, sunlight within 30 min of waking, yoga, caffeine after 12pm), bedtime activities (stretching, meditation, reading, eat within 3 hours of bed, journaling, alcohol within 3 hours of bed, shower, worked late, socialized late, screen time within 1 hour of bed, CAPA therapy), bedtime substances (sleeping pills, melatonin, supplements/herbs, CBD/THC, nicotine/tobacco, other medications), sleep distrubance (stress/racing thoughts, nightmares, light, noises, temperature, snoring, woke for bathroom, kids/partner/pets, travel/jet lag, pain/illness/injury)
CRUD operations with Firestore (done)
List/history view of diary entries (do this)

5. Assessment Module
Data models for ISI, PSQI, depression/anxiety
UI for each assessment (questionnaire forms)
Submission and result storage in Firestore
Assessment history and result visualization

6. Push Notifications Module
Integrate Firebase Cloud Messaging
Implement notification scheduling (customizable times)
UI for notification preferences/settings

7. Educational Modules (Post-MVP, but structure early)
Modular content delivery (CBT-i lessons, articles)
UI for module navigation and content display
Progress tracking

8. Sleep Data Analysis Module
Data aggregation and calculation logic
Visualization widgets (charts, graphs)
Insights and feedback UI

9. Gamification Module
Badge and streak logic
UI for achievements and progress
Notification triggers for milestones

10. Payments Module
Integrate Stripe via Firebase Extensions
UI for subscription management and purchase flow
Handle payment status and access control

11. Legal & Compliance Module
In-app Privacy Policy and Terms of Service screens
Implement Firebase Security Rules
Data encryption and secure storage practices

12. Analytics & Performance
Integrate Firebase Analytics events
Set up Crashlytics and Performance Monitoring

13. Testing & QA
Write integration and widget tests (using integration_test)
Set up test data and mock services
User Acceptance Testing scripts

14. Deployment & Distribution
Prepare app for App Store and Play Store (icons, splash, metadata)
Build and test release versions
Submit for review

15. Maintenance & Feedback
Weekly update workflow
In-app feedback collection (optional, for future)