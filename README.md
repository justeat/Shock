# Shock

[![Build Status](https://travis-ci.org/justeat/Shock.svg?branch=master)](https://travis-ci.org/justeat/Shock)
[![Version](https://img.shields.io/cocoapods/v/Shock.svg?style=flat)](http://cocoapods.org/pods/Shock)
[![License](https://img.shields.io/cocoapods/l/Shock.svg?style=flat)](http://cocoapods.org/pods/Shock)
[![Platform](https://img.shields.io/cocoapods/p/Shock.svg?style=flat)](http://cocoapods.org/pods/Shock)

A HTTP mocking framework written in Swift.

- [Just Eat Tech blog](https://tech.just-eat.com/2019/03/05/shock-better-automation-testing-for-ios/)

## Summary

* 😎 **Painless API mocking**: Shock lets you quickly and painlessly provide mock responses for web requests made by your apps.

* 🧪 **Isolated mocking**: When used with UI tests, Shock runs its server within the UI test process and stores all its responses within the UI tests target - so there is no need to pollute your app target with lots of test data and logic.

* ⭐️ **Shock now supports parallel UI testing!**: Shock can run isolated servers in parallel test processes. See below for more details!

* 🔌 **Shock can now host a basic socket**: In addition to an HTTP server, Shock can also host a socket server for a variety of testing tasks. See below for more details!

## Installation

### cocoapods

Add the following to your podfile:

```ruby
pod 'Shock', '~> x.y.z'
```

You can find the latest version on [cocoapods.org](http://cocoapods.org/pods/Shock)

### SPM

Copy the URL for this repo, and add the package in your project settings.

## Mocking HTTP Requests

Shock aims to provide a simple interface for setting up your mocks.

Take the example below:

```swift
class HappyPathTests: XCTestCase {

    var mockServer: MockServer!

    override func setUp() {
        super.setUp()
        mockServer = MockServer(port: 6789, bundle: Bundle(for: type(of: self)))
        mockServer.start()
    }

    override func tearDown() {
        mockServer.stop()
        super.tearDown()
    }

    func testExample() {

        let route: MockHTTPRoute = .simple(
            method: .get,
            urlPath: "/my/api/endpoint",
            code: 200,
            filename: "my-test-data.json"
        )

        mockServer.setup(route: route)

        /* ... Your test code ... */
    }
}
```

Bear in mind that you will need to replace your API endpoint hostname with 'localhost' and the port you specify in the setup method during test runs.

e.g. ```https://localhost:6789/my/api/endpoint```

In the case or UI tests, this is most quickly accomplished by passing a launch argument to your app that indicates which endpoint to use. For example:

```swift
let isRunningUITests = ProcessInfo.processInfo.arguments.contains("UITests")
if isRunningUITests {
    apiConfiguration.setHostname("http://localhost:6789/")
}
```

## Route types

Shock provides different types of mock routes for different circumstances.

### Simple Route

A simple mock is the preferred way of defining a mock route. It responds with
the contents of a JSON file in the test bundle, provided as a filename to the
mock declaration like so:

```swift
let route: MockHTTPRoute = .simple(
    method: .get,
    urlPath: "/my/api/endpoint",
    code: 200,
    filename: "my-test-data.json"
)
```

### Custom Route

A custom mock allows further customisation of your route definition including
the addition of query string parameters and HTTP headers.

This gives you more control over the finer details of the requests you want your
mock to handle.

Custom routes will try to strictly match your query and header definitions so
ensure that you add custom routes for all variations of these values.

```swift
let route = MockHTTPRoute = .custom(
    method: .get,
    urlPath: "/my/api/endpoint",
    query: ["queryKey": "queryValue"],
    headers: ["X-Custom-Header": "custom-header-value"],
    code: 200,
    filename: "my-test-data.json"
)
```

### Redirect Route

Sometimes we simply want our mock to redirect to another URL. The redirect mock
allows you to return a 301 redirect to another URL or endpoint.

```swift
let route: MockHTTPRoute = .redirect(
    .redirect(urlPath: "/source", destination: "/destination")
)
```

### Templated Route

A templated mock allows you to build a mock response for a request at runtime.
It uses [Mustache](https://mustache.github.io/) to allow values to be built in
to your responses when you setup your mocks.

For example, you might want a response to contain an array of items that is
variable size based on the requirements of the test.

Check out the `/template` route in the Shock Route Tester example app for a
more comprehensive example.

```swift
let route = MockHTTPRoute = .template(
    method: .get,
    urlPath: "/template",
    code: 200,
    filename: "my-templated-data.json",
    data: [
        "list": ["Item #1", "Item #2"],
        "text": "text"
    ])
)
```

### Collection

A collection route contains an array of other mock routes. It is simply a
container for storing and organising routes for different tests. In general,
if your test uses more than one route

Collection routes are added recursively, so a given collection route can be
included in another collection route safely.

```swift
let firstRoute: MockHTTPRoute = .simple(method: .get, urlPath: "/route1", code: 200, filename: "data1.json")
let secondRoute: MockHTTPRoute = .simple(method: .get, urlPath: "/route2", code: 200, filename: "data2.json")
let collectionRoute: MockHTTPRoute = .collection(routes: [ firstRoute, secondRoute ])
```

### Timeout Route

A timeout route is useful for testing client timeout code paths.
It simply waits a configurable amount of seconds (defaulting to 120 seconds).
**Note** if you do specify your own timeout, please make sure it exceeds your
client's timeout.

```swift
let route: MockHTTPRoute = .timeout(method: .get, urlPath: "/timeouttest")
```
```swift
let route: MockHTTPRoute = .timeout(method: .get, urlPath: "/timeouttest", timeoutInSeconds: 5)
```

### Force all calls to be mocked

In some case you might prefer to have all the calls to be mocked so that the tests can reliably run without internet connection. You can force this behaviour like so:

```
server.shouldSendNotFoundForMissingRoutes = true
```

This will send a 404 status code with an empty response body for any unrecognised paths.

## Middleware

Shock now support middleware! Middleware lets you use custom logic to handle a given request.

* 🤝 Middleware can be used with or without mock routes.
* ⛓ Middleware is chainable with the first middleware added receiving the context first,
passing it to the next, and so on

### ClosureMiddleware

The simplest way to use middleware is to add an instance of ClosureMiddleware to the server. For example:

```swift
let myMiddleware = ClosureMiddleware { request, response, next in
  if request.headers["X-Question"] == "Can I have a cup of tea?" {
      response.headers["X-Answer"] = "Yes, you can!"
  }
}
mockServer.add(middleware: myMiddleware)
```

The above will look for a request header named `X-Question` and, if it is present with the
expected value, it will send back an answer in the 'X-Answer' response header.

### Using Mock Routes and Middleware Together

Mock routes and middleware work fine together but there are a few things worth bearing in mind:

1. Mock routes is managed by are managed by a single middleware
2. This middleware will be added to the existing stack of middlewares _when the first mock route is added to the server_.

For middleware such as the example above, the order of middleware won't matter. However, if you
are making changes to a part of the response that was already set by the mock routes middleware,
you may get unexpected results!

## Socket Server

Shock can now host a socket server in addition to the HTTP server. This is useful for cases where you need to mock 
HTTP requests and a socket server. The Socket server uses familiar terminology to the HTTP server, so it has inherited
the term "route" to refer to a type of socket data handler. The API is similar to the HTTP API in that you need to create a 
`MockServerRoute`, call `setupSocket` with the route and when server `start` is called a socket will be setup with
your route (assuming at least one route is registered). 

If no `MockServerRoute`s are setup, the socket server is not started.

### Prerequisites

The socket server can only be hosted in addition to the HTTP server, as such Shock will need a port range of 
at least two ports, using the `init` method that takes a range. 

```swift
let range: ClosedRange<Int> = 10000...10010
let server = MockServer(portRange: range, bundle: ...)
```

### Available routes

There is only one route currently available for the socket server and that is `logStashEcho`. This route will setup a socket
that accepts messages being logged to [Logstash](https://www.elastic.co/logstash) and echo them back as strings.

Here is an example of using `logStashEcho` with our [JustTrack](https://github.com/justeat/JustTrack) framework.

```swift
import JustLog
import Shock

let server = MockServer(portRange: 9090...9099, bundle: ...)
let route = MockSocketRoute.logStashEcho { (log) in
    print("Received \(log)"
}
server.setupSocket(route: route)
server.start()

let logger = Logger.shared
logger.logstashHost = "localhost"
logger.logstashPort = UInt16(server.selectedSocketPort)
logger.enableLogstashLogging = true
logger.allowUntrustedServer = true
logger.setup()

logger.info("Hello world!")
```

It's worth noting that Shock is an untrusted server, so the `logger.allowUntrustedServer = true` is necessary.

## Shock Route Tester

<p align="center">
    <img src="./assets/example-app.png" alt="Example app screenshot" />
<p>

The Shock Route Tester example app lets you try out the different route types.
Edit the `MyRoutes.swift` file to add your own and test them in the app.

## License

Shock is available under Apache License 2.0.  See the LICENSE file for more info.
