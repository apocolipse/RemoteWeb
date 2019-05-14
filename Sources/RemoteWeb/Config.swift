import Foundation


struct RemoteConfig {
  /// Path to Configuration File.
  static var configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".lirc_web_config.json") {
    didSet {
      config = loadConfig()
    }
  }
  
  private static func loadConfig() -> [String: Any] {
    do {
      let data = try Data(contentsOf: configPath, options: .mappedIfSafe)
      let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
      if let jsonResult = jsonResult as? Dictionary<String, Any> {
        return jsonResult
      } else {
        print("Error loading \(configPath), invalid")
      }
    } catch let error {
      print("Error loading \(configPath), \(error.localizedDescription)")
    }
    return [:]
  }
  
  fileprivate static var config: [String: Any] = {
    return loadConfig()
  }()
  
  struct ServerConfig {
    static var port: in_port_t {
      return UInt16(((RemoteConfig.config["server"] as? [String: Any])?["port"] as? Int) ?? 3000)
    }
    static var forceIPv4: Bool {
      return ((RemoteConfig.config["server"] as? [String: Any])?["forceIPv4"] as? Bool) ?? false
    }
    static var ssl: Bool {
      return ((RemoteConfig.config["server"] as? [String: Any])?["ssl"] as? Bool) ?? false
    }
    static var sslCert: String {
      return ((RemoteConfig.config["server"] as? [String: Any])?["ssl_cert"] as? String) ?? ""
    }
    static var sslKey: String {
      return ((RemoteConfig.config["server"] as? [String: Any])?["ssl_key"] as? String) ?? ""
    }
    static var sslPort: in_port_t {
      return UInt16(((RemoteConfig.config["server"] as? [String: Any])?["ssl_port"] as? Int) ?? 3001)
    }
  }
  
  static var serverConfig: [String: Any] {
    return config["server"] as? [String: Any] ?? [:]
  }
  
  
  static var remoteLabels: [String: String] {
    return config["remoteLabels"] as? [String: String] ?? [:]
  }
  
  static var commandLabels: [String: [String: String]] {
    return config["commandLabels"] as? [String: [String: String]] ?? [:]
  }
  
  static var macros: [String: [[String]]] {
    return config["macros"] as? [String: [[String]]] ?? [:]
  }
  
  static var repeaters: [String: [String: Bool]] {
    return config["repeaters"] as? [String: [String: Bool]] ?? [:]
  }
  
  // TODO: Multiple sockets, TCP sockets
  static var socketPath: String {
    return config["socket"] as? String ?? "/var/run/lirc/lircd"
  }
}


