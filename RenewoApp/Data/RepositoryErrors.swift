import Foundation

enum RepositoryError: Error, Equatable {
    case freeLimitReached
    case validationFailed(String)
}
