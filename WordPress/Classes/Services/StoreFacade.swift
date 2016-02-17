import Foundation
import StoreKit

protocol StoreFacade {
    static func getProductsWithIdentifiers(identifiers: Set<String>, success: (Products -> Void), failure: (ErrorType -> Void))
}

class StoreKitFacade: StoreFacade {
    class ProductRequestDelegate: NSObject, SKProductsRequestDelegate {
        typealias Success = Products -> Void
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

    static func getProductsWithIdentifiers(identifiers: Set<String>, success: (Products -> Void), failure: (ErrorType -> Void)) {
        let request = SKProductsRequest(productIdentifiers: identifiers)
        let delegate = ProductRequestDelegate(onSuccess: success, onError: failure)
        request.delegate = delegate

        request.start()
    }
}
