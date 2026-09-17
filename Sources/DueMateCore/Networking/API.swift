import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public struct APIConfiguration: Sendable {
    public var baseURL: URL
    public var timeout: TimeInterval

    public init(baseURL: URL = URL(string: "https://www.pradeepjadhav.com/api/")!, timeout: TimeInterval = 30) {
        self.baseURL = baseURL
        self.timeout = timeout
    }

    public static let production = APIConfiguration()
}

public enum APIEndpoint: Sendable {
    case obligations
    case obligation(id: UUID)
    case occurrences
    case occurrence(id: UUID)
    case payments
    case payment(id: UUID)
    case categories
    case category(id: UUID)
    case settings
    case sync

    public var path: String {
        switch self {
        case .obligations: "obligations"
        case .obligation(let id): "obligations/\(id.uuidString)"
        case .occurrences: "occurrences"
        case .occurrence(let id): "occurrences/\(id.uuidString)"
        case .payments: "payments"
        case .payment(let id): "payments/\(id.uuidString)"
        case .categories: "categories"
        case .category(let id): "categories/\(id.uuidString)"
        case .settings: "settings"
        case .sync: "sync"
        }
    }

    public func url(configuration: APIConfiguration) -> URL {
        configuration.baseURL.appending(path: path)
    }
}

public struct ObligationDTO: Codable, Sendable {
    public var id: UUID
    public var title: String
    public var description: String?
    public var categoryId: UUID
    public var icon: String
    public var color: String
    public var amount: Money?
    public var amountKind: AmountKind
    public var recurrenceRule: RecurrenceRule
    public var startDate: CalendarDate
    public var endDate: CalendarDate?
    public var lifecycle: ObligationLifecycle
    public var providerName: String?
    public var accountReference: String?
    public var notes: String?
    public var emi: EMIDetails?
    public var creditCard: CreditCardDetails?
    public var createdAt: Date
    public var updatedAt: Date
}

public struct OccurrenceDTO: Codable, Sendable {
    public var id: UUID
    public var obligationId: UUID
    public var scheduledDate: CalendarDate
    public var status: OccurrenceStatus
    public var expectedAmount: Money?
    public var notes: String?
    public var installmentNumber: Int?
    public var createdAt: Date
    public var updatedAt: Date
}

public struct PaymentDTO: Codable, Sendable {
    public var id: UUID
    public var occurrenceId: UUID
    public var paidAt: Date
    public var amount: Money
    public var paymentMethod: PaymentMethod
    public var paymentApp: String?
    public var paymentBank: String?
    public var transactionReference: String?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
}

public struct CategoryDTO: Codable, Sendable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var color: String
    public var sortOrder: Int
    public var isSystem: Bool
    public var createdAt: Date
    public var updatedAt: Date
}

public struct SyncRequestDTO: Codable, Sendable {
    public var mutations: [SyncMutation]
}

public struct SyncResponseDTO: Codable, Sendable {
    public var obligations: [ObligationDTO]
    public var occurrences: [OccurrenceDTO]
    public var payments: [PaymentDTO]
    public var categories: [CategoryDTO]
}

public enum DTOMapper {
    public static func obligation(_ dto: ObligationDTO) -> Obligation {
        Obligation(
            id: dto.id,
            title: dto.title,
            summary: dto.description,
            categoryId: dto.categoryId,
            icon: dto.icon,
            colorToken: dto.color,
            amount: dto.amount,
            amountKind: dto.amountKind,
            recurrenceRule: dto.recurrenceRule,
            startDate: dto.startDate,
            endDate: dto.endDate,
            lifecycle: dto.lifecycle,
            providerName: dto.providerName,
            accountReference: dto.accountReference,
            notes: dto.notes,
            emi: dto.emi,
            creditCard: dto.creditCard,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    public static func dto(_ obligation: Obligation) -> ObligationDTO {
        ObligationDTO(
            id: obligation.id,
            title: obligation.title,
            description: obligation.summary,
            categoryId: obligation.categoryId,
            icon: obligation.icon,
            color: obligation.colorToken,
            amount: obligation.amount,
            amountKind: obligation.amountKind,
            recurrenceRule: obligation.recurrenceRule,
            startDate: obligation.startDate,
            endDate: obligation.endDate,
            lifecycle: obligation.lifecycle,
            providerName: obligation.providerName,
            accountReference: obligation.accountReference,
            notes: obligation.notes,
            emi: obligation.emi,
            creditCard: obligation.creditCard,
            createdAt: obligation.createdAt,
            updatedAt: obligation.updatedAt
        )
    }

    public static func occurrence(_ dto: OccurrenceDTO) -> Occurrence {
        Occurrence(
            id: dto.id,
            obligationId: dto.obligationId,
            scheduledDate: dto.scheduledDate,
            status: dto.status,
            expectedAmount: dto.expectedAmount,
            notes: dto.notes,
            installmentNumber: dto.installmentNumber,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    public static func payment(_ dto: PaymentDTO) -> Payment {
        Payment(
            id: dto.id,
            occurrenceId: dto.occurrenceId,
            paidAt: dto.paidAt,
            amount: dto.amount,
            paymentMethod: dto.paymentMethod,
            paymentApp: dto.paymentApp,
            paymentBank: dto.paymentBank,
            transactionReference: dto.transactionReference,
            notes: dto.notes,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    public static func category(_ dto: CategoryDTO) -> ObligationCategory {
        ObligationCategory(
            id: dto.id,
            name: dto.name,
            icon: dto.icon,
            colorToken: dto.color,
            sortOrder: dto.sortOrder,
            isSystem: dto.isSystem,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }
}

public protocol APIClientProtocol: Sendable {
    func fetchObligations() async throws -> [ObligationDTO]
    func createObligation(_ dto: ObligationDTO) async throws -> ObligationDTO
    func updateObligation(_ dto: ObligationDTO) async throws -> ObligationDTO
    func deleteObligation(id: UUID) async throws
    func fetchOccurrences() async throws -> [OccurrenceDTO]
    func updateOccurrence(_ dto: OccurrenceDTO) async throws -> OccurrenceDTO
    func fetchPayments() async throws -> [PaymentDTO]
    func createPayment(_ dto: PaymentDTO) async throws -> PaymentDTO
    func updatePayment(_ dto: PaymentDTO) async throws -> PaymentDTO
    func deletePayment(id: UUID) async throws
    func fetchCategories() async throws -> [CategoryDTO]
    func sync(_ request: SyncRequestDTO) async throws -> SyncResponseDTO
}

public enum APIClientError: Error, LocalizedError, Sendable {
    case notImplemented
    case http(status: Int)
    case decoding
    case transport(String)
    case unauthorized

    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            "Cloud sync isn't available yet. Your data is saved on this iPhone."
        case .http(let status):
            "Couldn't reach DueMate services (\(status)). Please try again."
        case .decoding:
            "The server returned data this version of DueMate doesn't understand."
        case .transport:
            "You're offline. Changes will sync when you're back online."
        case .unauthorized:
            "Your session expired. Please sign in again."
        }
    }
}

public struct MockAPIClient: APIClientProtocol {
    public init() {}

    public func fetchObligations() async throws -> [ObligationDTO] { [] }
    public func createObligation(_ dto: ObligationDTO) async throws -> ObligationDTO { dto }
    public func updateObligation(_ dto: ObligationDTO) async throws -> ObligationDTO { dto }
    public func deleteObligation(id: UUID) async throws {}
    public func fetchOccurrences() async throws -> [OccurrenceDTO] { [] }
    public func updateOccurrence(_ dto: OccurrenceDTO) async throws -> OccurrenceDTO { dto }
    public func fetchPayments() async throws -> [PaymentDTO] { [] }
    public func createPayment(_ dto: PaymentDTO) async throws -> PaymentDTO { dto }
    public func updatePayment(_ dto: PaymentDTO) async throws -> PaymentDTO { dto }
    public func deletePayment(id: UUID) async throws {}
    public func fetchCategories() async throws -> [CategoryDTO] { [] }
    public func sync(_ request: SyncRequestDTO) async throws -> SyncResponseDTO {
        SyncResponseDTO(obligations: [], occurrences: [], payments: [], categories: [])
    }
}

public protocol AuthenticationService: Sendable {
    var currentToken: String? { get async }
    func login(username: String, password: String) async throws
    func logout() async
    func refresh() async throws
}

public actor MockAuthenticationService: AuthenticationService {
    public private(set) var currentToken: String?

    public init() {}

    public func login(username: String, password: String) async throws {
        currentToken = "mock-token"
    }

    public func logout() async {
        currentToken = nil
    }

    public func refresh() async throws {}
}

public actor LiveAPIClient: APIClientProtocol {
    private let configuration: APIConfiguration
    private let session: URLSession
    private let auth: any AuthenticationService

    public init(
        configuration: APIConfiguration = .production,
        session: URLSession = .shared,
        auth: any AuthenticationService
    ) {
        self.configuration = configuration
        self.session = session
        self.auth = auth
    }

    public func fetchObligations() async throws -> [ObligationDTO] {
        try await request([ObligationDTO].self, .get, .obligations)
    }

    public func createObligation(_ dto: ObligationDTO) async throws -> ObligationDTO {
        try await request(ObligationDTO.self, .post, .obligations, body: dto)
    }

    public func updateObligation(_ dto: ObligationDTO) async throws -> ObligationDTO {
        try await request(ObligationDTO.self, .patch, .obligation(id: dto.id), body: dto)
    }

    public func deleteObligation(id: UUID) async throws {
        try await requestEmpty(.delete, .obligation(id: id))
    }

    public func fetchOccurrences() async throws -> [OccurrenceDTO] {
        try await request([OccurrenceDTO].self, .get, .occurrences)
    }

    public func updateOccurrence(_ dto: OccurrenceDTO) async throws -> OccurrenceDTO {
        try await request(OccurrenceDTO.self, .patch, .occurrence(id: dto.id), body: dto)
    }

    public func fetchPayments() async throws -> [PaymentDTO] {
        try await request([PaymentDTO].self, .get, .payments)
    }

    public func createPayment(_ dto: PaymentDTO) async throws -> PaymentDTO {
        try await request(PaymentDTO.self, .post, .payments, body: dto)
    }

    public func updatePayment(_ dto: PaymentDTO) async throws -> PaymentDTO {
        try await request(PaymentDTO.self, .patch, .payment(id: dto.id), body: dto)
    }

    public func deletePayment(id: UUID) async throws {
        try await requestEmpty(.delete, .payment(id: id))
    }

    public func fetchCategories() async throws -> [CategoryDTO] {
        try await request([CategoryDTO].self, .get, .categories)
    }

    public func sync(_ requestBody: SyncRequestDTO) async throws -> SyncResponseDTO {
        try await request(SyncResponseDTO.self, .post, .sync, body: requestBody)
    }

    private func request<T: Decodable, B: Encodable>(
        _ type: T.Type,
        _ method: HTTPMethod,
        _ endpoint: APIEndpoint,
        body: B
    ) async throws -> T {
        let data = try JSONEncoder.dueMate.encode(body)
        return try await perform(type, method, endpoint, body: data)
    }

    private func request<T: Decodable>(
        _ type: T.Type,
        _ method: HTTPMethod,
        _ endpoint: APIEndpoint
    ) async throws -> T {
        try await perform(type, method, endpoint, body: nil)
    }

    private func requestEmpty(_ method: HTTPMethod, _ endpoint: APIEndpoint) async throws {
        var request = URLRequest(url: endpoint.url(configuration: configuration), timeoutInterval: configuration.timeout)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = await auth.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let response: URLResponse
        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw APIClientError.transport(error.localizedDescription)
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw APIClientError.unauthorized }
        guard (200..<300).contains(status) else { throw APIClientError.http(status: status) }
    }

    private func perform<T: Decodable>(
        _ type: T.Type,
        _ method: HTTPMethod,
        _ endpoint: APIEndpoint,
        body: Data?
    ) async throws -> T {
        var request = URLRequest(url: endpoint.url(configuration: configuration), timeoutInterval: configuration.timeout)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token = await auth.currentToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIClientError.transport(error.localizedDescription)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw APIClientError.unauthorized }
        guard (200..<300).contains(status) else { throw APIClientError.http(status: status) }
        do {
            return try JSONDecoder.dueMate.decode(T.self, from: data)
        } catch {
            throw APIClientError.decoding
        }
    }
}

public actor SyncService {
    private let store: DueMateStore
    private let api: any APIClientProtocol

    public init(store: DueMateStore, api: any APIClientProtocol) {
        self.store = store
        self.api = api
    }

    public func synchronize() async -> SyncStatus {
        let snapshot = await store.current()
        guard !snapshot.pendingMutations.isEmpty else { return .synced }
        do {
            let response = try await api.sync(SyncRequestDTO(mutations: snapshot.pendingMutations))
            let remote = Snapshot(
                categories: response.categories.map(DTOMapper.category),
                obligations: response.obligations.map(DTOMapper.obligation),
                occurrences: response.occurrences.map(DTOMapper.occurrence),
                payments: response.payments.map(DTOMapper.payment)
            )
            try await store.mergeServerSnapshot(remote)
            try await store.replacePendingMutations([])
            return .synced
        } catch let error as APIClientError {
            switch error {
            case .transport: return .offline
            default: return .failed
            }
        } catch {
            return .failed
        }
    }
}
