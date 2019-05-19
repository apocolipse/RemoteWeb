//
//  RequestHandlers.swift
//  LIRC
//
//  Created by Christopher Simpson on 5/19/19.
//

import Foundation
import Swifter
import LIRC


// Request Handler Helpers helpers, Logging and Error handling
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
        var quer = ""
        if request.queryParams.count > 0 {
          quer = "?" + request.queryParams.map({ "\($0.0)=\($0.1)" }).joined(separator: "&")
        }
        print("\(date) \(host) \(proc)[\(pid)]: \(addr) - - Time Taken:\(time)  \"\(meth) \(path)\(quer) HTTP/1.1\" \(stat) \(len) \"\(org)\" \"\(hdrs)\"")
      }
    }
    return response
  }
}

// Request handlers

// Handler for handing all command send requests
let SendCommandHandler: (SendType) -> RequestHandler = { sendType in
  return TryingRequestHandler { request in
    guard let remoteParam = request.params[":remote"],
      let commandParam   = request.params[":command"] else { return .notFound }
    var s = sendType
    if case .once = sendType  {
      if let countString = request.queryParams.filter({$0.0 == "count" }).first?.1,
        let count = Int(countString) {
        s = .count(count)
      }
    }
    try lirc.remote(named: remoteParam).command(String(commandParam)).send(s)
    return .ok(.text("OK"))
  }
}

