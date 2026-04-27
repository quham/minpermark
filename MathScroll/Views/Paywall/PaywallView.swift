import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PaywallStore.self) private var paywall
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            Text("Keep your streak").font(.mathTitle)
            Text("Unlock unlimited questions and app blocking.")
                .font(.mathBody).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ForEach(paywall.products, id: \.id) { product in
                Button {
                    Task { _ = try? await paywall.purchase(product) }
                } label: {
                    GlassCard {
                        VStack(alignment: .leading) {
                            Text(product.displayName).font(.mathBody.weight(.semibold))
                            Text(product.displayPrice).font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
            }

            Button("Restore purchases") { Task { await paywall.restore() } }
                .font(.caption)
        }
        .padding()
        .task { await paywall.loadProducts() }
    }
}
