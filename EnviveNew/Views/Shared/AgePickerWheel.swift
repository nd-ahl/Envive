import SwiftUI

// MARK: - Age Picker Wheel Component

/// Reusable age picker wheel component used throughout the app
struct AgePickerWheel: View {
    @Binding var selectedAge: Int
    let ageRange: ClosedRange<Int>
    let showLabel: Bool

    init(selectedAge: Binding<Int>, ageRange: ClosedRange<Int> = 5...17, showLabel: Bool = true) {
        self._selectedAge = selectedAge
        self.ageRange = ageRange
        self.showLabel = showLabel
    }

    var body: some View {
        VStack(spacing: 20) {
            // Age display (if label shown)
            if showLabel {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(selectedAge)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    Text("years old")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .offset(y: -8)
                }
                .animation(.spring(response: 0.3), value: selectedAge)
            }

            // Picker wheel
            Picker("Age", selection: $selectedAge) {
                ForEach(Array(ageRange), id: \.self) { age in
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
        }
    }
}

// MARK: - Preview

struct AgePickerWheel_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.purple.opacity(0.6)
                .ignoresSafeArea()

            AgePickerWheel(selectedAge: .constant(12))
        }
    }
}
