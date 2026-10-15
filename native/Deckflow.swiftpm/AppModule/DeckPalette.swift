import SwiftUI

// Dark, subtle gradients and native controls inspired by the supplied recording.
enum DeckPalette {
    static let background = Color(red: 0.065, green: 0.070, blue: 0.092)
    static let surface = Color(red: 0.125, green: 0.132, blue: 0.16)
    static let elevated = Color(red: 0.17, green: 0.175, blue: 0.207)
    static let blue = Color(red: 0.27, green: 0.32, blue: 1.0)
    static let violet = Color(red: 0.47, green: 0.32, blue: 0.95)
    static let muted = Color(red: 0.64, green: 0.66, blue: 0.73)
    static let stroke = Color.white.opacity(0.075)
    static let screenGradient = LinearGradient(
        colors: [Color(red: 0.12, green: 0.095, blue: 0.19),
                 Color(red: 0.065, green: 0.078, blue: 0.115), background],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cardGradient = LinearGradient(colors: [blue, violet], startPoint: .leading, endPoint: .trailing)
}

struct NativePanel<Content: View>: View {
    let content: Content
    init(@ViewBuilder _ content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .background(DeckPalette.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(DeckPalette.stroke))
    }
}

struct PrimaryActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity).frame(minHeight: 48)
            .foregroundStyle(.white)
            .background(DeckPalette.cardGradient, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .opacity(configuration.isPressed ? 0.83 : 1)
    }
}

struct MiniTag: View {
    let title: String
    var icon: String? = nil
    var active = false
    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 12)) }
            Text(title).font(.system(size: 12, weight: active ? .semibold : .medium))
        }
        .foregroundStyle(active ? .white : .white.opacity(0.77))
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(active ? DeckPalette.blue.opacity(0.35) : DeckPalette.elevated,
                    in: Capsule())
        .overlay(Capsule().strokeBorder(active ? DeckPalette.blue.opacity(0.6) : DeckPalette.stroke))
    }
}

struct DeckThumbnail: View {
    var symbol: String
    var size: CGFloat = 56
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.4, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(LinearGradient(colors: [DeckPalette.violet.opacity(0.9), DeckPalette.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: size * 0.30))
            .overlay(RoundedRectangle(cornerRadius: size * 0.30).strokeBorder(.white.opacity(0.13)))
    }
}

struct SectionCaption: View {
    var title: String
    var accessory: String?
    var body: some View {
        HStack {
            Text(title).font(.system(size: 18, weight: .bold))
            Spacer()
            if let accessory { Text(accessory).font(.caption).foregroundStyle(DeckPalette.muted) }
        }
        .foregroundStyle(.white)
    }
}