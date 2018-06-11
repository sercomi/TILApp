import FluentMySQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentMySQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "vapor"
    let databaseName: String
    let databasePort: Int
    if (env == .testing) {
        databaseName = "vapor-test"
        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 3307
        } else {
            databasePort = 3307
        }
    } else {
        databaseName = Environment.get("DATABASE_DB") ?? "vapor"
        databasePort = 3306
    }
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    
    let databaseConfig = MySQLDatabaseConfig(hostname: hostname, port: databasePort, username: username, password: password, database: databaseName)
    let database = MySQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .mysql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: Category.self, database: .mysql)
    migrations.add(model: Acronym.self, database: .mysql)
    migrations.add(model: AcronymCategoryPivot.self, database: .mysql)
    services.register(migrations)
    
    // Configure the rest of your application here
    var commandConfig = CommandConfig.default()
    commandConfig.use(RevertCommand.self, as: "revert")
    services.register(commandConfig)

}
