# 💜 VIVA

### **Virtual Intelligent Vitality Assistant**

> **Every Choice Shapes Your Health.**

VIVA is an AI-powered Health Decision Support System that helps users make smarter daily health decisions. Rather than simply tracking calories, workouts, or expenses, VIVA analyzes multiple aspects of a user's lifestyle—including nutrition, physical activity, health-related spending, and personal goals—to provide personalized recommendations and actionable insights.

---

# 📖 About the Project

Modern fitness applications provide users with large amounts of health data, but they often leave the interpretation and decision-making to the user. VIVA bridges this gap by transforming collected data into intelligent recommendations that guide users toward healthier daily choices.

The application is designed as both a mobile health companion and a research-driven Decision Support System (DSS), introducing a framework that evaluates daily decisions instead of simply recording activities.

---

# 🎯 Objectives

* Help users make informed health decisions.
* Promote healthier eating habits.
* Encourage consistent physical activity.
* Improve nutrition awareness.
* Monitor health-related spending.
* Generate personalized recommendations using AI.
* Support long-term healthy lifestyle habits.

---

# ✨ Core Features

## 🧠 Decision Engine

The heart of VIVA.

Instead of only displaying statistics, the Decision Engine evaluates user behavior and recommends the next best action based on:

* Personal Goals
* Nutrition
* Physical Activity
* Budget
* Daily Habits
* Previous Decisions
* Progress Trends

---

## 📷 Nutrition Facts Scanner

* Scan Nutrition Facts labels
* Barcode scanning
* OCR text recognition
* Instant nutrition analysis
* Decision Score generation
* Personalized recommendations

---

## 🍽 Nutrition Tracking

* Daily meals
* Calories
* Protein
* Carbohydrates
* Fat
* Sugar
* Sodium
* Water intake

---

## 🏋 Workout Tracking

* Strength training
* Cardio
* Walking
* Running
* Cycling
* Custom workouts

---

## 💰 Health Expense Tracking

Track expenses related to:

* Groceries
* Supplements
* Protein
* Vitamins
* Gym Membership
* Healthy Meals

---

## 🛒 Grocery Planner

* Grocery checklist
* Healthy alternatives
* Pantry management
* Budget planning

---

## 🤖 AI Recommendations

Examples:

* Eat more protein today.
* Reduce sodium intake.
* Stay within today's budget.
* Drink more water.
* Complete a short walk.
* Suggested healthier alternatives.

---

## 📊 Analytics

* Daily Summary
* Weekly Report
* Monthly Progress
* Decision Trends
* Goal Progress
* Nutrition Overview

---

# 🏆 Proposed Research Contribution

Unlike conventional fitness applications, VIVA introduces three proposed evaluation models:

### Decision Score (DS)

Measures how beneficial a user's current decision is based on multiple lifestyle factors.

---

### Goal Alignment Score (GAS)

Measures how closely daily actions support the user's health goals.

---

### Health Investment Index (HII)

Evaluates how effectively health-related spending contributes toward achieving health objectives.

---

# 📱 Mobile Application Flow

```text
Splash Screen
      │
      ▼
Onboarding
      │
      ▼
Login / Register
      │
      ▼
Health Assessment
      │
      ▼
Goal Setup
      │
      ▼
Home Dashboard
      │
      ├──────────────┐
      ▼              ▼
Scan Food        Log Meal
      │              │
      ▼              ▼
Decision Engine Analysis
      │
      ▼
Recommendation
      │
      ▼
Decision Score
      │
      ▼
Save Activity
      │
      ▼
Progress Dashboard
```

---

# 🛠 Technology Stack

## Mobile

* Flutter
* Dart
* Riverpod
* GoRouter
* Dio
* Flutter Secure Storage
* SharedPreferences / Hive
* fl_chart

## Backend

* Next.js
* TypeScript
* Prisma ORM
* PostgreSQL
* REST API

## AI

* OpenAI API *(planned)*
* Google Gemini API *(alternative)*

## Services

* Firebase Authentication *(optional)*
* Firebase Cloud Messaging
* Firebase Storage

## Image Processing

* Google ML Kit OCR
* Mobile Scanner
* Barcode Scanner

---

# 📂 Project Structure

```text
viva/
│
├── mobile/
│   ├── lib/
│   ├── assets/
│   ├── widgets/
│   ├── features/
│   ├── core/
│   └── services/
│
├── backend/
│   ├── app/
│   ├── prisma/
│   ├── lib/
│   ├── routes/
│   └── middleware/
│
├── docs/
├── design/
└── README.md
```

---

# 🚀 Future Features

* AI Meal Planner
* AI Grocery Planner
* AI Health Coach
* Receipt Scanner
* Restaurant Menu Scanner
* Wearable Integration
* Apple Health Integration
* Google Fit Integration
* Smart Notifications
* Community Challenges
* Research Analytics Dashboard

---

# 🎨 Design Philosophy

VIVA is designed around **Decision Support**, not just data tracking.

Instead of overwhelming users with charts and numbers, every interaction should help answer one simple question:

> **"What's the best decision I can make right now?"**

---

# 👨‍💻 Development Team

**Project Name**

**VIVA – Virtual Intelligent Vitality Assistant**

Developed as a Computer Science Capstone Project focused on intelligent health decision support through nutrition, activity, spending, and AI-driven recommendations.

---

## 📜 License

This project is intended for academic and research purposes. Licensing may be updated as development progresses.

---

<p align="center">
  <strong>💜 VIVA</strong><br>
  <em>Every Choice Shapes Your Health.</em>
</p>
