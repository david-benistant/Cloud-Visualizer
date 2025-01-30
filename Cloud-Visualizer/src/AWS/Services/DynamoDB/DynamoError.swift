struct DynamoError: Error {
    let message: String
    let description: String?
    let client: DynamoClientWrapper?

    init(message: String, description: String? = nil, client: DynamoClientWrapper? = nil) {
        self.message = message
        self.description = description
        self.client = client
    }
}
