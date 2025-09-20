# EnviveNew - Product Requirements Document

## Project Overview

**EnviveNew** is a gamified family management and personal productivity iOS/macOS application that combines screen time control, location tracking, task management, and social features to help families stay connected while encouraging healthy digital habits and real-world activities.

## Core Vision

Create a comprehensive family ecosystem app that transforms screen time management from restrictive to motivational by rewarding real-world activities with digital privileges, while maintaining family connections through location sharing and social interactions.

## Target Audience

### Primary Users
- **Parents**: Want to manage family screen time while encouraging positive behaviors
- **Teens/Young Adults**: Need motivation for real-world activities and connection with family/friends
- **Families**: Seeking tools for coordination and healthy digital habits

### Secondary Users
- **Schools**: Classroom management and activity tracking
- **Youth Organizations**: Activity coordination and engagement

## Current Feature Analysis

### 🎯 **Core Features (Implemented)**

#### 1. **Gamified Task Management**
- **Task Categories**: Exercise, Chores, Study, Social, Creative, Outdoor, Health, Custom
- **XP Reward System**: Tasks earn experience points based on difficulty/category
- **Task Verification**: Photo verification and location-based validation
- **Group Tasks**: Multi-participant activities with shared rewards
- **Custom Tasks**: User-created activities with flexible XP rewards

#### 2. **Advanced Screen Time Management**
- **Family Controls Integration**: Leverages iOS FamilyControls framework
- **Managed Settings**: App-specific restrictions and time limits
- **Earn-to-Use Model**: Complete tasks to earn screen time minutes
- **Session Management**: Active session tracking with time remaining
- **Smart Notifications**: Session ending warnings and daily reminders

#### 3. **Location Services & Tracking**
- **Real-time Location Sharing**: Friend/family location visibility
- **Activity Tracking**: GPS route recording for outdoor activities
- **Location-based Task Verification**: Confirm task completion at specific locations
- **Distance & Speed Tracking**: Comprehensive fitness metrics
- **Friend Location Map**: Visual map showing friend locations

#### 4. **Rich Notification System**
- **Task Completion Alerts**: Celebrate achievements with kudos system
- **Friend Request Management**: Accept/decline friend requests
- **Milestone Notifications**: XP milestones and achievement alerts
- **Location Sharing Alerts**: Friend location sharing notifications
- **Daily Goal Reminders**: Scheduled daily engagement prompts

#### 5. **Social Features**
- **Friend System**: Add friends, manage friend requests
- **Activity Feed**: Real-time friend activity updates with kudos
- **Leaderboard**: XP-based ranking system
- **Credibility Score**: Trust-based reputation system
- **Group Activities**: Collaborative task completion

#### 6. **Camera & Verification**
- **Dual Camera Support**: Front and back camera integration
- **Photo Verification**: Prove task completion with photos
- **Activity Documentation**: Visual proof of completed activities

### 🏗️ **Technical Architecture**

#### **Frameworks & Technologies**
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence
- **FamilyControls**: iOS screen time management
- **ManagedSettings**: App restriction controls
- **CoreLocation**: GPS and location services
- **MapKit**: Map integration and visualization
- **AVFoundation**: Camera and media capture
- **UserNotifications**: Rich push notification system
- **Combine**: Reactive programming patterns

#### **External Dependencies**
- **Supabase Swift SDK**: Backend-as-a-Service for data sync and user management

#### **Data Models**
- **User**: Profile, XP, friends, parental controls
- **TaskItem**: Activities with XP rewards, verification, location data
- **FriendActivity**: Social activity feed with kudos system
- **LocationTrackingPoint**: GPS tracking data for activities

---

## Feature Implementation Checklist

### 🚀 **Phase 1: Core Foundation (Completed)**
- [x] **Project Setup**
  - [x] Xcode project initialization
  - [x] SwiftUI app structure
  - [x] Core Data stack setup
  - [x] Supabase integration

- [x] **User Management**
  - [x] User model with XP system
  - [x] Profile management
  - [x] Credibility scoring system
  - [x] Parental control flags

- [x] **Task System Foundation**
  - [x] Task categories enum
  - [x] TaskItem model with XP rewards
  - [x] Basic task creation and completion
  - [x] Custom task support

### 🎮 **Phase 2: Gamification Core (Completed)**
- [x] **XP & Reward System**
  - [x] XP calculation logic
  - [x] XP balance tracking
  - [x] Total XP earned metrics
  - [x] XP-to-screen-time conversion

- [x] **Screen Time Integration**
  - [x] FamilyControls authorization
  - [x] App selection for restrictions
  - [x] Session management
  - [x] Time remaining tracking
  - [x] Earned minutes system

- [x] **Task Management UI**
  - [x] Task list view with categories
  - [x] Task creation interface
  - [x] Task completion workflow
  - [x] XP reward visualization

### 📍 **Phase 3: Location & Verification (Completed)**
- [x] **Location Services**
  - [x] Location permission handling
  - [x] GPS tracking for activities
  - [x] Location-based task verification
  - [x] Distance and speed calculation
  - [x] Route recording and playback

- [x] **Photo Verification**
  - [x] Camera integration (front/back)
  - [x] Photo capture for task proof
  - [x] Image storage and display
  - [x] Verification workflow

- [x] **Map Integration**
  - [x] MapKit integration
  - [x] Friend location display
  - [x] Activity route visualization
  - [x] Location-based features

### 👥 **Phase 4: Social Features (Completed)**
- [x] **Friend System**
  - [x] Friend request system
  - [x] Friend list management
  - [x] Pending request handling
  - [x] Friend location sharing

- [x] **Activity Feed**
  - [x] Real-time friend activity updates
  - [x] Kudos system for activities
  - [x] Activity details with photos
  - [x] Social engagement features

- [x] **Notifications**
  - [x] Rich notification categories
  - [x] Interactive notification actions
  - [x] Friend request notifications
  - [x] Achievement notifications
  - [x] Daily reminder system

### 🔧 **Phase 5: Polish & Enhancement (Next Phase)**
- [ ] **Data Persistence & Sync**
  - [ ] Supabase backend integration
  - [ ] Real-time data synchronization
  - [ ] Offline mode support
  - [ ] Data backup and restore

- [ ] **Advanced Gamification**
  - [ ] Achievement system with badges
  - [ ] Streak tracking and rewards
  - [ ] Seasonal challenges and events
  - [ ] Leaderboard with different time periods
  - [ ] XP multipliers and bonuses

- [ ] **Enhanced Social Features**
  - [ ] Group challenges and competitions
  - [ ] Family vs family competitions
  - [ ] Chat/messaging system
  - [ ] Activity comments and reactions
  - [ ] Social sharing to external platforms

### 🎨 **Phase 6: User Experience & Design (Future)**
- [ ] **UI/UX Improvements**
  - [ ] Onboarding flow and tutorials
  - [ ] Dark mode support
  - [ ] Accessibility features
  - [ ] Haptic feedback integration
  - [ ] Animation and micro-interactions

- [ ] **Customization**
  - [ ] Theme and color customization
  - [ ] Avatar and profile customization
  - [ ] Custom notification sounds
  - [ ] Personalized reward preferences

- [ ] **Analytics & Insights**
  - [ ] Personal activity analytics
  - [ ] Family progress reports
  - [ ] Health and fitness insights
  - [ ] Screen time usage patterns

### 🔒 **Phase 7: Security & Privacy (Future)**
- [ ] **Privacy Controls**
  - [ ] Granular location sharing controls
  - [ ] Photo privacy settings
  - [ ] Activity visibility controls
  - [ ] Data export and deletion

- [ ] **Parental Controls**
  - [ ] Parent dashboard and oversight
  - [ ] Content filtering and moderation
  - [ ] Time limit enforcement
  - [ ] Activity approval workflows

### 🚀 **Phase 8: Platform & Distribution (Future)**
- [ ] **Multi-Platform Support**
  - [ ] macOS version optimization
  - [ ] iPad-specific features
  - [ ] Apple Watch companion app
  - [ ] Web dashboard for parents

- [ ] **App Store Preparation**
  - [ ] App Store metadata and screenshots
  - [ ] Privacy policy and terms of service
  - [ ] Beta testing program
  - [ ] Performance optimization
  - [ ] App Store review guidelines compliance

---

## Success Metrics

### **Engagement Metrics**
- Daily active users and session duration
- Task completion rates by category
- XP earned per user per day
- Friend interaction frequency

### **Behavioral Metrics**
- Screen time reduction vs. real-world activity increase
- Location-based activity participation
- Photo verification usage rates
- Social feature adoption

### **Technical Metrics**
- App performance and crash rates
- Location accuracy and battery impact
- Notification delivery and engagement
- Data sync reliability

---

## Risk Assessment

### **Technical Risks**
- **Battery Drain**: Location tracking and camera usage
- **Privacy Concerns**: Location sharing and photo storage
- **Performance**: Large data sets and real-time updates
- **Platform Dependency**: iOS-specific features limiting cross-platform potential

### **Product Risks**
- **User Adoption**: Complex feature set may overwhelm users
- **Parental Buy-in**: Parents may be skeptical of gamified screen time
- **Social Features**: Managing inappropriate content and interactions
- **Scalability**: Backend infrastructure for real-time features

### **Market Risks**
- **Competition**: Established players in screen time and family apps
- **Regulations**: Changing privacy laws affecting location and child data
- **Platform Changes**: iOS updates affecting FamilyControls framework

---

## Next Steps

1. **Complete Supabase Integration**: Implement real-time data sync
2. **Beta Testing Program**: Family and friend group testing
3. **Performance Optimization**: Location services and battery usage
4. **Privacy Audit**: Ensure compliance with child privacy regulations
5. **App Store Submission**: Prepare for public release

---

*This PRD serves as a living document that will evolve as EnviveNew develops and user feedback is incorporated.*