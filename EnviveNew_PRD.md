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

#### 7. **Parent-Child Relationship System (NEW - Implemented)**
- **User Type System**: Users designated as either 'parent' or 'child'
- **Relationship Invitations**: Parents can invite children by email/phone
- **Acceptance Workflow**: Children can accept/reject parent relationships
- **Multiple Relationships**: Children can have multiple parents, parents can have multiple children
- **Data Validation**: Ensures children cannot be parents of other users
- **Row-Level Security**: Database policies ensure proper access control

### 🏗️ **Technical Architecture**

#### **Frameworks & Technologies**
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence
- **FamilyControls**: iOS screen time management and authorization
- **ManagedSettings**: App restriction controls and enforcement
- **DeviceActivity**: Activity monitoring and scheduling framework
- **CoreLocation**: GPS and location services
- **MapKit**: Map integration and visualization
- **AVFoundation**: Camera and media capture
- **UserNotifications**: Rich push notification system
- **Combine**: Reactive programming patterns

#### **External Dependencies**
- **Supabase Swift SDK**: Backend-as-a-Service for data sync and user management

#### **Data Models**
- **User**: Profile, XP, friends, parental controls, user type (parent/child)
- **UserRelationship**: Parent-child relationships with invitation/acceptance system
- **TaskItem**: Activities with XP rewards, verification, location data
- **FriendActivity**: Social activity feed with kudos system
- **LocationTrackingPoint**: GPS tracking data for activities
- **ScreenTimeActivity**: Screen time sessions, earned minutes, usage tracking

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

### 🔧 **Phase 5: Database & User Management (Current Priority)**
- [x] **Parent-Child Relationship System**
  - [x] Enhanced users table with type field and parent-child support
  - [x] User relationship table with invitation/acceptance workflow
  - [x] Database constraints preventing children from being parents
  - [x] Row-level security policies for proper access control
  - [ ] **Account Creation & Onboarding Flow**
    - [ ] User type selection during registration (parent vs child)
    - [ ] Parent invitation system UI
    - [ ] Child acceptance/rejection UI
    - [ ] Profile completion workflow

- [ ] **Test User Management System**
  - [ ] Development user switcher for testing parent/child workflows
  - [ ] Test data seeding and management
  - [ ] Parent-child relationship testing interface
  - [ ] Mock authentication for development testing

- [x] **Modern Screen Time API Implementation (COMPLETED)**
  - [x] DeviceActivity framework integration (`ActivityScheduler.swift`)
  - [x] DeviceActivityMonitor extension creation (`EnviveNewDeviceActivityMonitor.swift`)
  - [x] Advanced app scheduling and time limits (session-based management)
  - [x] Usage threshold monitoring and events (implemented in monitor)
  - [x] Enhanced XP-to-screen-time conversion system (`ScreenTimeRewardManager.swift`)
  - [x] Parent oversight and control features (`ParentControlView.swift`, `ChildScreenTimeView.swift`)
  - [x] Integrated parent-child interface (`IntegratedScreenTimeView.swift`)

- [ ] **Screen Time Testing & Validation**
  - [ ] Hardcoded Safari 2-minute time limit test (no Supabase dependency)
  - [ ] Physical device testing (Simulator not supported for Screen Time APIs)
  - [ ] FamilyControls authorization flow validation
  - [ ] Session start/stop functionality verification
  - [ ] App blocking/unblocking behavior testing
  - [ ] DeviceActivity Monitor extension debugging and logging

- [ ] **Data Persistence & Sync**
  - [x] Supabase backend database schema
  - [ ] Real-time data synchronization between app and database
  - [ ] User authentication integration
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

## Technical Implementation References

### **Screen Time API Implementation Guide**

A comprehensive implementation guide for upgrading EnviveNew's screen time management to use Apple's modern Screen Time APIs has been created: `ScreenTime_API_Implementation_Guide.md`

**Key Implementation Areas:**
- **DeviceActivity Framework**: Background monitoring and scheduling
- **Enhanced ManagedSettings**: Advanced restriction capabilities
- **DeviceActivityMonitor Extension**: Background activity processing
- **XP Integration**: Seamless reward system with screen time earning
- **Advanced Scheduling**: Timer-based and usage threshold monitoring

**Migration Strategy:**
1. **Phase 1**: Parallel implementation alongside existing system
2. **Phase 2**: Enhanced features using new capabilities
3. **Phase 3**: Full migration with user data preservation

**Requirements:**
- Apple Developer Program membership
- Special entitlement request (`com.apple.developer.family-controls`)
- iOS 15.0+ (iOS 16.0+ for advanced features)
- Physical device testing (Simulator not supported)

See the complete implementation guide for detailed code examples, setup instructions, and integration patterns.

---

## Immediate Development Priorities

### **Phase 5A: User System Completion (Current Sprint)**
1. **Account Creation Flow Implementation**
   - User type selection UI (parent vs child)
   - Registration workflow with proper user type assignment
   - Profile completion and validation

2. **Parent-Child Relationship UI**
   - Parent invitation system (search by email/phone)
   - Child notification and acceptance interface
   - Relationship management dashboard

3. **Development Testing Infrastructure**
   - Test user management system for easy parent/child switching
   - Mock data seeding for development
   - Authentication bypass for testing

### **Phase 5B: Enhanced Screen Time Integration**
4. **Modern Screen Time APIs**: Upgrade to DeviceActivity framework with parent oversight
5. **Parent Control Dashboard**: Screen time management for children
6. **Family Screen Time Policies**: Custom rules and restrictions per child

### **Phase 5C: Production Readiness**
7. **Complete Supabase Integration**: Real-time data sync with authentication
8. **Beta Testing Program**: Family group testing with actual parent-child relationships
9. **Performance Optimization**: Location services and battery usage
10. **Privacy Audit**: Ensure compliance with child privacy regulations

## Test User Setup Requirements

### **Current Test Users (Development Database)**
- **Parent Test User**: `parent@test.com` (ID: `00000000-0000-0000-0000-000000000001`)
- **Child Test User**: `child@test.com` (ID: `00000000-0000-0000-0000-000000000002`)
- **Test Relationship**: Pending invitation created between parent and child

### **Development Testing Workflow**
1. **Create User Switcher**: Debug menu to switch between parent/child test users
2. **Test Relationship Flow**:
   - Parent sends invitation to child
   - Child receives and accepts/rejects invitation
   - Verify relationship appears in both user interfaces
3. **Test Screen Time Management**: Parent sets limits for child, child earns time through tasks
4. **Test Family Features**: Location sharing, task assignment, progress monitoring

### **Required Implementation Tasks**
- [ ] User type selection during onboarding
- [ ] Parent invitation system (email/phone lookup)
- [ ] Child acceptance/rejection workflow
- [ ] Development user switcher interface
- [ ] Parent dashboard with child oversight
- [ ] Child interface showing parent-assigned tasks/limits

---

*This PRD serves as a living document that will evolve as EnviveNew develops and user feedback is incorporated.*