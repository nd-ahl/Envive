# Parent Photo Display Fix

## Problem

When a child completed a task and uploaded a photo, the parent could not see the photo in the Task Review view. The photo section had a TODO comment and was showing a placeholder rectangle instead of the actual photo.

## Root Cause

In `/EnviveNew/Views/Parent/TaskReviewView.swift` (line 110), there was a TODO comment:

```swift
// TODO: Load actual image from photoURL
Rectangle()
    .fill(Color.gray.opacity(0.3))
    .frame(height: 200)
    .cornerRadius(8)
    .overlay(
        Text("📸 Photo")
            .foregroundColor(.secondary)
    )
```

The photo was being saved correctly by the child using `CameraManager`, but the parent's TaskReviewView wasn't loading it.

## Solution

Updated TaskReviewView to:
1. Access the `CameraManager` to load saved photos
2. Use the task ID to retrieve the photo
3. Display the photo in BeReal style (4:5 aspect ratio)
4. Show the combined image with both back and front cameras

## Implementation Details

### Added State Variables

```swift
struct TaskReviewView: View {
    @StateObject private var viewModel: TaskReviewViewModel
    @StateObject private var model = EnhancedScreenTimeModel()  // For CameraManager access
    @State private var showMainAsBack = true
    @Environment(\.dismiss) var dismiss
    // ...
}
```

### Updated Photo Evidence Section

Replaced the placeholder with actual photo loading:

```swift
private var photoEvidenceSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Label("Photo Evidence", systemImage: "camera.fill")
            .font(.headline)

        // Load photos for this task
        if let savedPhoto = model.cameraManager.getLatestPhotoForTask(viewModel.assignment.id),
           let backImage = model.cameraManager.loadPhoto(savedPhoto: savedPhoto) {

            // BeReal-style photo display with 4:5 ratio (matching Child and Social tab)
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = width * 1.25 // 4:5 ratio

                ZStack {
                    // Main photo (back camera showing completed task)
                    Image(uiImage: backImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                        .cornerRadius(20)

                    // Note: Front camera overlay is baked into the combined image
                    // that was saved by the child, so we don't need to add it separately
                }
            }
            .aspectRatio(4/5, contentMode: .fit)

            Text("✅ Photo proof submitted by child")
                .font(.caption)
                .foregroundColor(.green)
        } else {
            // No photo found - show placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .cornerRadius(8)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No photo submitted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
}
```

## How It Works

1. **Child Side (Task Completion)**:
   - Child takes photo with dual camera
   - CameraViewController captures back and front cameras
   - ChildTaskDetailView creates combined BeReal-style image
   - Image saved via `CameraManager.savePhoto()` with task ID
   - Task submitted for parent approval

2. **Parent Side (Task Review)**:
   - Parent navigates to pending approval task
   - TaskReviewView loads
   - `model.cameraManager.getLatestPhotoForTask(taskId)` retrieves photo
   - `model.cameraManager.loadPhoto(savedPhoto:)` loads UIImage
   - Photo displayed in 4:5 BeReal style
   - Parent sees combined image with both cameras and watermark

## Photo Flow Diagram

```
Child Task Detail
    ↓
Takes Photo (Dual Camera)
    ↓
Creates Combined Image
    ↓
CameraManager.savePhoto(image, taskId: assignment.id)
    ↓
Saved to FileManager
    - Directory: Documents/EnvivePhotos/
    - Filename: photo_<timestamp>.jpg
    - Metadata: savedPhotos.json (includes taskId)
    ↓
Task Completed & Submitted
    ↓
Parent Dashboard (Pending Approvals)
    ↓
TaskReviewView Loads
    ↓
CameraManager.getLatestPhotoForTask(taskId)
    ↓
CameraManager.loadPhoto(savedPhoto:)
    ↓
✅ Photo Displayed to Parent
```

## Photo Storage Structure

### Files
```
Documents/
├── EnvivePhotos/
│   ├── photo_1234567890.123.jpg  <- Combined BeReal image
│   ├── photo_1234567891.456.jpg
│   └── ...
└── savedPhotos.json  <- Metadata with task IDs
```

### Metadata (savedPhotos.json)
```json
[
  {
    "id": "uuid-1",
    "fileName": "photo_1234567890.123.jpg",
    "timestamp": "2025-01-15T10:30:00Z",
    "taskTitle": "Take out the trash",
    "taskId": "task-uuid-123"
  }
]
```

## What Parent Sees

The parent now sees the **combined BeReal-style image** that includes:

1. **Main Image**: Back camera photo showing the completed task
2. **Overlay**: Front camera photo in top-right corner (child's face)
3. **Watermark**: ENVIVE branding + task title + timestamp (bottom-right)
4. **Border**: White rounded border around front camera overlay
5. **Aspect Ratio**: 4:5 (Instagram/BeReal style)

This is the **same combined image** that the child created when they tapped "Complete Task".

## Visual Example

```
Parent Task Review Screen

┌─────────────────────────────────────┐
│   Photo Evidence                    │
│                                     │
│   ┌─────────────────────────────┐  │
│   │                   ┌───────┐ │  │
│   │  Completed Task   │ Child │ │  │ <- Front camera overlay
│   │  (Back Camera)    │ Face  │ │  │
│   │                   └───────┘ │  │
│   │                             │  │
│   │         ENVIVE Watermark    │  │ <- Bottom-right
│   └─────────────────────────────┘  │
│                                     │
│   ✅ Photo proof submitted by child │
│                                     │
│   [APPROVE]  [EDIT & APPROVE]       │
│   [DECLINE]                         │
└─────────────────────────────────────┘
```

## Key Features

✅ **Photo Loads Automatically** - Uses task ID to find the right photo
✅ **BeReal Style Display** - 4:5 aspect ratio, rounded corners
✅ **Combined Image** - Both cameras visible in one photo
✅ **Watermark Visible** - Shows authenticity and timestamp
✅ **Fallback UI** - Shows "No photo submitted" if photo not found
✅ **Consistent Design** - Matches Child task detail and Social tab

## Files Modified

1. `/EnviveNew/Views/Parent/TaskReviewView.swift`
   - Added `@StateObject private var model = EnhancedScreenTimeModel()`
   - Added `@State private var showMainAsBack = true`
   - Replaced `photoEvidenceSection(photoURL:)` with computed property
   - Implemented actual photo loading using CameraManager
   - BeReal-style display with 4:5 aspect ratio
   - Added fallback for when no photo exists

## Build Status

✅ **BUILD SUCCEEDED** - Ready for testing on physical device

## Testing Checklist

### End-to-End Flow

**Child Side:**
- [ ] Child sees assigned task
- [ ] Child taps "Start Task"
- [ ] Child taps "Take Photo Proof"
- [ ] Camera captures back and front
- [ ] Child taps "Use Photo"
- [ ] Camera dismisses automatically
- [ ] Photos appear in task detail (BeReal style)
- [ ] Child can swap back/front photos
- [ ] Child taps "Complete Task"
- [ ] Task submits successfully

**Parent Side:**
- [ ] Switch to parent mode
- [ ] See task in "Pending Approvals"
- [ ] Tap task to review
- [ ] **Photo Evidence section appears**
- [ ] **Photo loads and displays correctly**
- [ ] **Combined image shows both cameras**
- [ ] **Watermark visible**
- [ ] **4:5 aspect ratio**
- [ ] "Photo proof submitted by child" text shows
- [ ] Can approve or decline task

### Photo Display Verification

- [ ] Photo shows completed task (back camera)
- [ ] Front camera overlay visible in top-right
- [ ] White border around overlay
- [ ] Watermark shows: ENVIVE + task title + timestamp
- [ ] Photo fills container properly
- [ ] No stretching or distortion
- [ ] Rounded corners (20px radius)
- [ ] Matches Child and Social tab appearance

### Edge Cases

- [ ] Task with no photo shows "No photo submitted"
- [ ] Task with invalid photo ID shows fallback
- [ ] Multiple photos for same task loads latest
- [ ] Photo loads after app restart
- [ ] Photo survives mode switching

## Benefits

**For Parents:**
- Can now see proof of completed tasks
- Visual verification before approval
- Both cameras visible (anti-fraud)
- Professional BeReal-style presentation

**For System:**
- Consistent photo display across all views
- Reliable photo loading using task IDs
- Graceful fallback when photos missing
- Single source of truth (CameraManager)

## Future Enhancements

When migrating to Firebase:
- Upload combined images to Firebase Storage
- Store photo URLs in Firestore task documents
- Real-time photo loading from cloud
- Offline caching for previously viewed photos
- Photo quality optimization for network transfer
- Progressive loading (thumbnail → full size)
