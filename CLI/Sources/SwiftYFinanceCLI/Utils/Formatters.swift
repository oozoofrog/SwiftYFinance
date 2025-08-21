import Foundation

func formatPrice(_ price: Double) -> String {
    return String(format: "%.2f", price)
}

func formatPriceShort(_ price: Double) -> String {
    return String(format: "%6.2f", price)
}

func formatPercent(_ percent: Double) -> String {
    return String(format: "%.2f", percent)
}

func formatLargeNumber(_ number: Double) -> String {
    if number >= 1_000_000_000_000 {
        return String(format: "%.1fT", number / 1_000_000_000_000)
    } else if number >= 1_000_000_000 {
        return String(format: "%.1fB", number / 1_000_000_000)
    } else if number >= 1_000_000 {
        return String(format: "%.1fM", number / 1_000_000)
    } else if number >= 1_000 {
        return String(format: "%.1fK", number / 1_000)
    } else {
        return String(format: "%.0f", number)
    }
}

func formatVolume(_ volume: Int) -> String {
    return Double(volume).formatted(.number.notation(.compactName))
}

func formatVolumeShort(_ volume: Int) -> String {
    if volume >= 1_000_000 {
        return String(format: "%5.1fM", Double(volume) / 1_000_000)
    } else if volume >= 1_000 {
        return String(format: "%5.1fK", Double(volume) / 1_000)
    } else {
        return String(format: "%7d", volume)
    }
}

func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

func formatDateShort(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yy"
    return formatter.string(from: date)
}