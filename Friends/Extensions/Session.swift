import MatrixRustSDK

extension Session: Codable {
    
    private enum CodingKeys: CodingKey {
        case accessToken
        case refreshToken
        case userId
        case homeserverUrl
        case deviceId
        case oidcData
        case slidingSyncVersion
    }

    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            accessToken: try container.decode(String.self, forKey: CodingKeys.accessToken),
            refreshToken: try container.decode(String?.self, forKey: CodingKeys.refreshToken),
            userId: try container.decode(String.self, forKey: CodingKeys.userId),
            deviceId: try container.decode(String.self, forKey: CodingKeys.deviceId),
            homeserverUrl: try container.decode(String.self, forKey: CodingKeys.homeserverUrl),
            oidcData: try container.decode(String?.self, forKey: CodingKeys.oidcData),
            slidingSyncVersion: try container.decode(SlidingSyncVersion.self, forKey: CodingKeys.slidingSyncVersion)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.accessToken, forKey: CodingKeys.accessToken)
        try container.encode(self.refreshToken, forKey: CodingKeys.refreshToken)
        try container.encode(self.userId, forKey: CodingKeys.userId)
        try container.encode(self.deviceId, forKey: CodingKeys.deviceId)
        try container.encode(self.homeserverUrl, forKey: CodingKeys.homeserverUrl)
        try container.encode(self.oidcData, forKey: CodingKeys.oidcData)
        try container.encode(self.slidingSyncVersion, forKey: CodingKeys.slidingSyncVersion)
    }
}
