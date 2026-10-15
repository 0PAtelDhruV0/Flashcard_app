import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: DeckflowStore
    let finish: () -> Void
    @State private var step = 0
    @State private var language = "Spanish"
    @State private var goal = 15
    private let languages = ["English", "Spanish", "Japanese", "French", "Portuguese", "German", "Italian", "Korean", "Chinese", "Latin", "Russian", "Arabic", "Sanskrit", "Other"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if step > 0 {
                    Button { withAnimation { step -= 1 } } label: { Image(systemName: "arrow.left") }
                        .foregroundStyle(.white)
                }
                Spacer()
                Button("Skip") { complete() }
                    .font(.caption).foregroundStyle(DeckPalette.muted)
            }
            .padding(20)
            HStack(spacing: 5) {
                Capsule().fill(DeckPalette.blue).frame(width: 46, height: 3)
                Capsule().fill(step > 0 ? DeckPalette.blue : DeckPalette.elevated).frame(width: 46, height: 3)
            }
            .padding(.top, 14)
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 7) {
                        Text(step == 0 ? "What do you want to master?" : "How many cards will you learn daily?")
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                        Text(step == 0 ? "Pick a language to get started" : "Build a habit at your own pace")
                            .font(.subheadline).foregroundStyle(DeckPalette.muted)
                    }
                    if step == 0 {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96))], spacing: 10) {
                            ForEach(languages, id: \.self) { option in
                                Button { language = option } label: {
                                    MiniTag(title: option, icon: "character.bubble", active: language == option)
                                        .frame(maxWidth: .infinity)
                                }.buttonStyle(.plain)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            goalOption(minutes: 10, label: "Relaxed", icon: "leaf")
                            goalOption(minutes: 15, label: "Effective", icon: "flame")
                            goalOption(minutes: 20, label: "Accelerated", icon: "bolt")
                            goalOption(minutes: 30, label: "Super Accelerated", icon: "hare")
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.top, 42)
                .frame(maxWidth: 630)
                .frame(maxWidth: .infinity)
            }
            Button(step == 0 ? "Continue" : "Start learning") {
                if step == 0 { withAnimation(.easeInOut(duration: 0.25)) { step = 1 } }
                else { complete() }
            }
            .buttonStyle(PrimaryActionStyle())
            .frame(maxWidth: 630).padding(20)
        }
        .background(DeckPalette.screenGradient.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func goalOption(minutes: Int, label: String, icon: String) -> some View {
        Button { goal = minutes } label: {
            HStack {
                Image(systemName: icon).foregroundStyle(.white.opacity(0.8))
                    .frame(width: 32)
                Text(label).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(minutes) cards").font(.caption).foregroundStyle(DeckPalette.muted)
                if goal == minutes { Image(systemName: "checkmark.circle.fill").foregroundStyle(DeckPalette.blue) }
            }
            .padding(16).frame(maxWidth: .infinity)
            .background(DeckPalette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(goal == minutes ? DeckPalette.blue : DeckPalette.stroke))
        }
        .buttonStyle(.plain)
    }

    private func complete() {
        store.setGoal(goal); store.setLanguage(language); store.completeOnboarding(); finish()
    }
}