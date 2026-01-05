# Mirai - CS Career & Learning Hub

<div align="center">
  <img src="assets/images/logo.png" alt="Mirai Logo" width="200">

  **A comprehensive Flutter app designed for Computer Science students and IT professionals**

  *Your single hub for jobs, internships, courses, roadmaps, and career opportunities*

  [![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev/multi-platform)
</div>

## 🌟 Overview

Mirai is a modern, feature-rich mobile application built with Flutter and Firebase that serves as a comprehensive platform for CS/IT students and professionals. The app provides a centralized location for discovering job opportunities, internships, educational resources, career roadmaps, and GSoC organizations.

### 🎯 Core Mission
- **Simplify** the job and internship search process for CS students
- **Centralize** learning resources and career guidance in one platform
- **Connect** students with opportunities that match their skills and interests
- **Accelerate** career growth through curated content and personalized recommendations

## ✨ Key Features

### 📱 **Modern User Experience**
- **Dark Theme Design** with premium UI/UX (AppTheme: #1C1C1E, #2C2C2E)
- **Bottom Navigation** with 5 main sections + **Sidebar Drawer**
- **Clean Architecture** without traditional AppBar for modern look
- **Responsive Design** optimized for mobile devices

### 🔐 **Authentication & Onboarding**
- **Google Sign-In** integration with Firebase Auth
- **Smart Onboarding** flow with location-based college selection
- **Profile Management** with graduating year, state, city, and college info
- **Automatic User Creation** with FCM token registration

### 💼 **Job & Internship Platform**
- **Real-time Listings** from Firestore with live updates
- **Advanced Filtering** by location, company, tags, and requirements
- **Smart Recommendations** based on user profile and preferences
- **Save & Share** functionality for opportunities
- **Apply Integration** with direct links to company application pages

### 🎓 **Learning Resources**
- **Course Catalog** with online learning opportunities
- **Career Roadmaps** for different tech specializations
- **GSoC Integration** with organization listings and opportunities
- **Guide Section** with development tutorials and best practices

### 🔔 **Push Notifications & Deep Linking**
- **FCM Integration** with foreground, background, and terminated state handling
- **Deep Linking** to 12+ different screens with parameter passing
- **Smart Routing** with fallback handling for graceful navigation
- **Local Notifications** for enhanced user engagement

### 📊 **Analytics & Performance**
- **Firebase Analytics** with comprehensive event tracking
- **Performance Optimizations** including image caching and smart loading
- **Offline Support** with Firestore persistence and unlimited cache
- **Error Handling** with user-friendly feedback

## 🏗️ Technical Architecture

### **Tech Stack**
```yaml
Frontend: Flutter 3.0+ (Dart)
Backend: Firebase (Firestore, Auth, Analytics, FCM)
State Management: Provider Pattern
Navigation: Flutter Navigation 2.0
Caching: CachedNetworkImage with optimized parameters
Notifications: firebase_messaging + flutter_local_notifications
```

## 📋 Sample Images

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/b264cd26-d7c1-4e84-a7dc-17dca63a52b2" width="180"/>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/e3666034-9c2b-4d3e-92af-b5cc840e1a20" width="180"/>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/53a302d6-8585-459f-b9cd-47a6bad7642e" width="180"/>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/3d7ac640-86cf-40d0-ae98-e5b66a458e19" width="180"/>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/8bb41b19-5708-493e-ac69-9b0f9aa2b42d" width="180"/>
    </td>
  </tr>
</table>

