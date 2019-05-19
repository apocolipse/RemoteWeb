import Foundation
import LIRC

// JSON helpers for collections for responses
extension Dictionary {
  var json: String {
    let invalidJson = "Not a valid JSON"
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
      return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
    } catch {
      return invalidJson
    }
  }
  func dict2json() -> String {
    return json
  }
}
extension Array {
  var json: String {
    let invalidJson = "Not a valid JSON"
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
      return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
    } catch {
      return invalidJson
    }
  }
}

// Info For logging
struct Info {
  static let hostname: String = {
    var hostnamebytes = [Int8](repeating: 0, count: 1024)
    gethostname(&hostnamebytes, 1024)
    return String(cString: hostnamebytes)
  }()
}

// LIRC specific extensions for RemoteWeb, based on configuration
extension Remote {
  var label: String {
    return RemoteConfig.remoteLabels[name] ?? name
  }
}

extension Remote.Command {
  var label: String {
    return RemoteConfig.commandLabels[parentName]?[name] ?? name
  }
  
  var repeats: Bool {
    return RemoteConfig.repeaters[parentName]?[name] ?? false
  }
}

