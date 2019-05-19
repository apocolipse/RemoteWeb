import Foundation
import LIRC
import Swifter

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

// Swifter helpers, Logging and Error handling
typealias RequestHandler = ((HttpRequest) -> HttpResponse)
typealias ThrowableRequestHandler = ((HttpRequest) throws -> HttpResponse)

let TryingRequestHandler: (@escaping ThrowableRequestHandler) -> RequestHandler = { requestHandler in
  return {
    do { return try requestHandler($0) }
    catch let error { return .badRequest(.text("\(error)")) }
  }
}


let loggingQueue = DispatchQueue.global(qos: .background)

let LoggingRequestHandler: (@escaping RequestHandler) -> RequestHandler = { requestHandler in
  return { request in
    let startTime = Date()
    let response = requestHandler(request)
    let stopTime = Date()
    defer {
      loggingQueue.async {
        let (pinfo, df) = (ProcessInfo.processInfo, DateFormatter())
        df.dateFormat = "MMM dd HH:mm:ss"
        
        let (date, host, proc, pid)  = (df.string(from: startTime), Info.hostname, pinfo.processName, pinfo.processIdentifier)
        let (addr, time, meth) = (request.address ?? "127.0.0.1", stopTime.timeIntervalSince(startTime), request.method)
        let (path, stat, len)  = (request.path, response.statusCode, response.headers()["Content-Length"] ?? "0")
        let (org, hdrs)  = (request.headers["origin"] ?? "\"-\"", request.headers["user-agent"] ?? "")
        
        print("\(date) \(host) \(proc)[\(pid)]: \(addr) - - Time Taken:\(time)  \"\(meth) \(path) HTTP/1.1\" \(stat) \(len) \"\(org)\" \"\(hdrs)\"")
      }
    }
    return response
  }
}
