import Foundation
import StoreKit

protocol StoreFacade {
    static func productsWithIdentifiers(identifiers: Set<String>, completion: Result<[Product]> -> Void)
}

class StoreKitFacade: StoreFacade {
    class ProductRequestDelegate: NSObject, SKProductsRequestDelegate {
        typealias Success = [SKProduct] -> Void
        typealias Failure = ErrorType -> Void

        let onSuccess: Success
        let onError: Failure

        init(onSuccess: Success, onError: Failure) {
            self.onSuccess = onSuccess
            self.onError = onError
        }

        func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
            onSuccess(response.products)
        }

        func request(request: SKRequest, didFailWithError error: NSError) {
            onError(error)
        }
    }

    static func productsWithIdentifiers(identifiers: Set<String>, completion: Result<[Product]> -> Void) {
        let request = SKProductsRequest(productIdentifiers: identifiers)
        let delegate = ProductRequestDelegate(
            onSuccess: { products in
                completion(.Success(products))
            }, onError: { error in
                completion(.Failure(error))
        })
        request.delegate = delegate

        request.start()
    }
}
