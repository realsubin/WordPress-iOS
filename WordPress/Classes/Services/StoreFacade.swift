import Foundation
import StoreKit

enum ProductRequestError: ErrorType {
    case MissingProduct
    case InvalidProductPrice
}

protocol StoreFacade {
    func getProductsWithIdentifiers(identifiers: Set<String>, success: Products -> Void, failure: ErrorType -> Void)
}

extension StoreFacade {
    func getPricesForPlans(plans: Plans, success: [String] -> Void, failure: ErrorType -> Void) {
        let identifiers = Set(plans.flatMap({ $0.productIdentifier }))
        getProductsWithIdentifiers(
            identifiers,
            success: { products in
                do {
                    let prices = try plans.map({ plan -> String in
                        return try priceForPlan(plan, products: products)
                    })
                    success(prices)
                } catch let error {
                    failure(error)
                }
            },
            failure: failure
        )
    }
}

class StoreKitFacade: StoreFacade {
    func getProductsWithIdentifiers(identifiers: Set<String>, success: Products -> Void, failure: ErrorType -> Void) {
        let request = SKProductsRequest(productIdentifiers: identifiers)
        let delegate = ProductRequestDelegate(onSuccess: success, onError: failure)
        request.delegate = delegate

        request.start()
    }
}

class MockStoreFacade: StoreFacade {
    /// Response delay in seconds
    let delay: Double

    init(delay: Double = 1.0) {
        self.delay = delay
    }

    let products = [
        MockProduct(
            localizedDescription: "1 year of WordPress.com Premium",
            localizedTitle: "WordPress.com Premium 1 year",
            price: NSDecimalNumber(float: 99.88),
            priceLocale: NSLocale(localeIdentifier: "en-US"),
            productIdentifier: "com.wordpress.test.premium.1year"
        ),
        MockProduct(
            localizedDescription: "1 year of WordPress.com Business",
            localizedTitle: "WordPress.com Business 1 year",
            price: NSDecimalNumber(float: 299.88),
            priceLocale: NSLocale(localeIdentifier: "en-US"),
            productIdentifier: "com.wordpress.test.business.1year"
        )
    ]

    func getProductsWithIdentifiers(identifiers: Set<String>, success: Products -> Void, failure: ErrorType -> Void) {
        let products = identifiers.map({ identifier in
            return self.products.filter({ $0.productIdentifier == identifier }).first
        })
        if !products.filter({ $0 == nil }).isEmpty {
            failure(ProductRequestError.MissingProduct)
        } else {
            let products = products.flatMap({ $0 })

            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
                dispatch_get_main_queue()) {
                    success(products)
            }
        }
    }
}

private class ProductRequestDelegate: NSObject, SKProductsRequestDelegate {
    typealias Success = Products -> Void
    typealias Failure = ErrorType -> Void
    
    let onSuccess: Success
    let onError: Failure
    
    init(onSuccess: Success, onError: Failure) {
        self.onSuccess = onSuccess
        self.onError = onError
        super.init()
    }
    
    @objc func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        onSuccess(response.products)
    }
    
    @objc func request(request: SKRequest, didFailWithError error: NSError) {
        onError(error)
    }
}

func priceForProduct(identifier: String, products: Products) throws -> String {
    guard let product = products.filter({ $0.productIdentifier == identifier }).first else {
        throw ProductRequestError.MissingProduct
    }
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.locale = product.priceLocale
    guard let price = formatter.stringFromNumber(product.price) else {
        throw ProductRequestError.InvalidProductPrice
    }
    return price
}

func priceForPlan(plan: Plan, products: Products) throws -> String {
    guard let identifier = plan.productIdentifier else {
        return ""
    }
    return try priceForProduct(identifier, products: products)
}
