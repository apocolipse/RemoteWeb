import Foundation
import Swifter
import Dispatch
import LIRC

let server = HttpServer()
var cachedRemotes: String = ""
let commandQueue = DispatchQueue.global(qos: .background)
let loggingQueue = DispatchQueue.global(qos: .background)

let lirc = LIRC(socketPath: RemoteConfig.socketPath)

typealias HTTPMiddleware = ((HttpRequest) -> HttpResponse)
typealias ThrowableHTTPMiddleware = ((HttpRequest) throws -> HttpResponse)

let TryingRequestHandler: (@escaping ThrowableHTTPMiddleware) -> HTTPMiddleware = { requestHandler in
  return {
    do {
      return try requestHandler($0)
    } catch let error {
      return .badRequest(.text(error.localizedDescription))
    }
  }
}

let LoggingRequestHandler: (@escaping HTTPMiddleware) -> HTTPMiddleware = { requestHandler in
  return { request in
    print("Gets here")
    let startTime = Date()
    let response = requestHandler(request)
    let stopTime = Date()
    defer {
      loggingQueue.async {
        let pinfo = ProcessInfo.processInfo
        let df = (DateFormatter())
        df.dateFormat = "MMM dd HH:mm:ss"
        
        let date = df.string(from: startTime)
        let host = Info.hostname
        let proc = pinfo.processName
        let pid  = pinfo.processIdentifier
        let addr = request.address ?? "127.0.0.1"
        let time = stopTime.timeIntervalSince(startTime)
        let meth = request.method
        let path = request.path
        let stat = response.statusCode
        let len  = response.headers()["Content-Length"] ?? "0"
        let org  = request.headers["origin"] ?? "\"-\""
        let hdrs = request.headers["user-agent"] ?? ""

        print("\(date) \(host) \(proc)[\(pid)]: \(addr) - - Time Taken:\(time)  \"\(meth) \(path) HTTP/1.1\" \(stat) \(len) \"\(org)\" \"\(hdrs)\"")
      }
    }
    return response
  }
}


server.GET["/remotes.json"] = LoggingRequestHandler { request in
  if cachedRemotes != "" && cachedRemotes != "{}" {
    return .ok(.text(cachedRemotes))
  }
  var json: [String: [String]] = [:]
  if lirc.allRemotes.count == 0 {
    do {
      try lirc.refreshRemotes()
    } catch let error {
      print("Error fetching remotes \(error)")
    }
  }
  lirc.allRemotes.forEach { remote in
    json[remote.name] = remote.commands.map { $0.name }
  }
  cachedRemotes = json.json
  return .ok(.text(json.json))
}

server.GET["/refresh"] = LoggingRequestHandler { request in
  commandQueue.async { try? lirc.refreshRemotes() }
  cachedRemotes = ""
  return .movedPermanently("/")
}

server.GET["/remotes/:remote"] = LoggingRequestHandler { request in
  guard let param = request.params[":remote"],
        param.contains(".json"),
        let remote = param.split(separator: ".").first,
        let r = lirc.remote(named: String(remote)) else { return .notFound }
  return .ok(.text(r.commands.map({ $0.name }).json))
}

server.POST["/remotes/:remote/:command"] = LoggingRequestHandler(TryingRequestHandler { request in
  guard let remoteParam = request.params[":remote"],
        let commandParam   = request.params[":command"],
        let remote = lirc.remote(named: remoteParam),
        let command = remote.command(String(commandParam))  else { return .notFound }
  
  try command.send(.once)
  return .ok(.text("OK"))
})

server.POST["/remotes/:remote/:command/send_start"] = LoggingRequestHandler(TryingRequestHandler { request in
  guard let remoteParam = request.params[":remote"],
        let commandParam   = request.params[":command"],
        let remote = lirc.remote(named: remoteParam),
        let command = remote.command(String(commandParam))  else { return .notFound }

  try command.send(.start)
  return .ok(.text("OK"))
})

server.POST["/remotes/:remote/:command/send_stop"] = LoggingRequestHandler(TryingRequestHandler { request in
  guard let remoteParam = request.params[":remote"],
        let commandParam   = request.params[":command"],
        let remote = lirc.remote(named: remoteParam),
        let command = remote.command(String(commandParam))  else { return .notFound }

  try command.send(.stop)
  return .ok(.text("OK"))
})

server.GET["/macros.json"] = LoggingRequestHandler { request in
  return .ok(.text(RemoteConfig.macros.json))
}

server.POST["/macros/:macro"] = LoggingRequestHandler(TryingRequestHandler { request in
  guard let macroParam = request.params[":macro"],
        let macro = RemoteConfig.macros[macroParam] else { return .notFound }
  for step in macro {
    if step[0] == "delay" {
      usleep((UInt32(step[1]) ?? 1) * 1000)
    } else {
      try lirc.remote(named: step[0])?.command(step[1])?.send()
    }
  }
  
  return .ok(.text("OK"))
})


server.GET["/"] = LoggingRequestHandler(RemoteTemplates.index(with: lirc.allRemotes))

server["js/compiled/:path"]  = LoggingRequestHandler(shareFilesFromDirectory("/home/pi/RemoteWeb/compiled")) // TODO: FIXME)
server["css/compiled/:path"] = LoggingRequestHandler(shareFilesFromDirectory("/home/pi/RemoteWeb/compiled")) // TODO: FIXME


print("Hello, world!")

let semaphore = DispatchSemaphore(value: 0)
do {
  try server.start(9999, forceIPv4: RemoteConfig.ServerConfig.forceIPv4, priority: .background)
 print("Server started on 9999")
  semaphore.wait()
} catch let error{
  print("Server start error: \(error)")
  semaphore.signal()
}

