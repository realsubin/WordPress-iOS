import Foundation
import RxSwift
import StoreKit

protocol StoreFacade {
    static func productsWithIdentifiers(identifiers: Set<String>) -> Observable<[Product]>
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

    class ProductRequestDisposable: Disposable {
        let request: SKProductsRequest
        let delegate: ProductRequestDelegate

        init(request: SKProductsRequest, delegate: ProductRequestDelegate) {
            self.request = request
            self.delegate = delegate
        }

        func dispose() {
            request.cancel()
        }
    }

    static func productsWithIdentifiers(identifiers: Set<String>) -> Observable<[Product]> {
        return Observable.create { observer in
            let request = SKProductsRequest(productIdentifiers: identifiers)
            let delegate = ProductRequestDelegate(
                onSuccess: { products in
                    observer.onNext(products)
                }, onError: { error in
                    observer.onError(error)
            })
            request.delegate = delegate

            request.start()

            return ProductRequestDisposable(request: request, delegate: delegate)
        }
    }
}
