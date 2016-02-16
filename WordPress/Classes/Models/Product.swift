import Foundation
import StoreKit

@objc
protocol Product {
    var localizedDescription: String { get }
    
    var localizedTitle: String { get }
    
    var price: NSDecimalNumber { get }
    
    var priceLocale: NSLocale { get }
    
    var productIdentifier: String { get }
}

extension SKProduct: Product {}

extension SKProduct {
    public override var description: String {
        return "<SKProduct: \(productIdentifier), title: \(localizedTitle)>"
    }
}

struct MockProduct {
    let localizedDescription: String
    let localizedTitle: String
    let price: NSDecimalNumber
    let priceLocale: NSLocale
    let productIdentifier: String
}
