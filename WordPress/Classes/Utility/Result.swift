import Foundation

enum Result<T> {
    case Success(T)
    case Failure(ErrorType)

    func map<U>(transform: T -> U) -> Result<U> {
        switch self {
        case .Success(let value):
                return .Success(transform(value))
        case .Failure(let err):
            return .Failure(err)
        }
    }

    func flatMap<U>(transform: T -> Result<U>) -> Result<U> {
        switch self {
        case .Success(let value):
            return transform(value)
        case .Failure(let error):
            return .Failure(error)
        }
    }
}

extension Result: CustomStringConvertible {
    var description: String {
        switch self {
        case .Success(let value):
            return "Success: \(value)"
        case .Failure(let error):
            return "Failure: \(error)"
        }
    }
}
