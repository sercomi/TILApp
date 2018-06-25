import Foundation
import Vapor
import FluentMySQL
import Authentication

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var password: String
    
    init(name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }

    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String

        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

extension User: MySQLUUIDModel {}
extension User: Content {}
extension User: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)

            try builder.addIndex(to: \.username, isUnique: true)
        }
    }
}
extension User: Parameter {}
extension User.Public: Content {}

extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.userID)
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}


extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}

extension User: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \User.username
    static let passwordKey: PasswordKey = \User.password
}

extension User: TokenAuthenticatable {
    typealias TokenType = Token    
}

struct AdminUser: Migration {
    typealias Database = MySQLDatabase
    
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        let password = try? BCrypt.hash("password")
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }
        let user = User(
            name: "Admin",
            username: "admin",
            password: hashedPassword)
        return user.save(on: connection).transform(to: ())
    }
    
    static func revert(on connection: MySQLConnection) -> Future<Void> {
        return .done(on: connection)
    }
}

extension User: PasswordAuthenticatable {}

extension User: SessionAuthenticatable {}
