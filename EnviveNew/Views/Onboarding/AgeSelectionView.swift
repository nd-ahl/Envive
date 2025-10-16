import SwiftUI

// MARK: - Age Selection View

/// Allows users to select their age with a scrolling picker
struct AgeSelectionView: View {
    let userRole: UserRole
    let onComplete: (Int) -> Void

    @State private var selectedAge: Int = 25
    @State private var showContent = false

    // Age ranges based on role
    private var ageRange: [Int] {
        switch userRole {
        case .parent:
            return Array(18...99)
        case .child:
            return Array(5...17)
        }
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.7),
                    Color.purple.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Content
                VStack(spacing: 40) {
                    // Header
                    headerSection

                    // Picker section
                    pickerSection

                    // Helper text
                    helperText
                }

                Spacer()

                // Continue button
                continueButton
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            // Set default age based on role
            selectedAge = userRole == .parent ? 35 : 12

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            Text(userRole == .parent ? "🎂" : "🎈")
                .font(.system(size: 70))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("How old are you?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text(userRole == .parent ? "This helps us personalize your experience" : "Just so we know how to set things up!")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Picker Section

    private var pickerSection: some View {
        VStack(spacing: 20) {
            // Age display
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(selectedAge)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())

                Text(userRole == .parent ? "years old" : "years")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .offset(y: -8)
            }
            .animation(.spring(response: 0.3), value: selectedAge)

            // Picker wheel
            Picker("Age", selection: $selectedAge) {
                ForEach(ageRange, id: \.self) { age in
                    Text("\(age)")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .tag(age)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .padding(.horizontal, -16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 50)
            )
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Helper Text

    private var helperText: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text("Your age is private and secure")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: {
            onComplete(selectedAge)
        }) {
            HStack(spacing: 10) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
            }
            .foregroundColor(Color.blue.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
    }
}

// MARK: - Preview

struct AgeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AgeSelectionView(userRole: .parent, onComplete: { _ in })
            AgeSelectionView(userRole: .child, onComplete: { _ in })
        }
    }
}
