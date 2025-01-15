
struct S3Error: Error {
    let message: String
    let description: String?
    let client: S3ClientWrapper?
    
    init(message: String, description: String? = nil, client: S3ClientWrapper? = nil) {
        self.message = message
        self.description = description
        self.client = client
    }
}
