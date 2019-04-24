# Fetch

![Bitrise](https://app.bitrise.io/app/c7d1932e4398ffc9/status.svg?token=2gddfiJReIY_-JaeahuRAg&branch=master)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Fetch is a resource based network abstraction based on [Alamofire](https://github.com/Alamofire/Alamofire) 

## Features

- [x] Define API using typed resources
- [x] Decode HTTP response body using Decodable
- [x] Encode HTTP request body using Encodable
- [x] Root keys: decode multiple wrapper container
- [x] Logging
- [x] Stubbing
  - [x] Simple respnose or error
  - [x] Random stub from array
  - [x] Cycle through stub array
- [x] Caching
  - [x] Multiple caching policies
  - [x] In-memory cache
  - [x] Disk cache

## Basic usage

First setup the `APIClient` using a `Config`. It's just one line.
Call it in the `application(_:didFinishLaunchingWithOptions:)` function.

```swift
APIClient.shared.setup(with: Config(baseURL: URL(string: "https://api.github.com")!))
```

Lets create a struct named `Organisation` with a few properties.
The model will be parsed from the network response. 

```swift
struct Organization: Decodable, Equatable {
    let id: Int
    let name: String
    let location: String
}
```

A `Resource` contains all necessary information to create a network request and parse the response.

```swift
let resource = Resource<Organization>(
    method: .get,
    path: "/orgs/allaboutapps")
```

Sending the request and parsing the response into the typed model `Organisation`:

```swift
resource.request { (result) in
    switch result {
    case .success(let networkResponse):
        print("Status code:", networkResponse.urlResponse.statusCode)
        print("Model:", networkResponse.model)
    case .failure(let apiError):
        print("Error:", apiError)
    }
}
```

## Advanced usage

### Stubbing

Fetch gives you a versatile set of possibilities to perform stubbing.

**Simulate a successful network request with a json response**

```swift
let stub = StubResponse(statusCode: 200, fileName: "success.json", delay: 2.0)
        
let resource = Resource<String>(
            path: "/test",
            shouldStub: true,
            stub: stub)
```
The above stub will return a 200 status code with the content from the success json file loaded from your app's bundle and will be delayed by two seconds.

**Simulate an unauthorized error**

```swift
let stub = StubResponse(statusCode: 401, fileName: "unauthorized.json", delay: 2.0)
        
let resource = Resource<String>(
            path: "/unauthorized",
            shouldStub: true,
            stub: stub)
```

Stubbing is not limited to json only, you can also provide raw data or provide an instance which conforms to the Encodable protocol.

**Stubbing with Encodable**

```swift
struct Person: Encodable {
    let name: String
    let age: Int
}
    
let peter = Person(name: "Peter", age: 18)

let stub = StubResponse(statusCode: 200, encodable: peter, delay: 2.0)
        
let resource = Resource<String>(
            path: "/peter",
            shouldStub: true,
            stub: stub)
```

**Alternating stubbing**

 ```swift
let successStub = StubResponse(statusCode: 200, fileName: "success.json", delay: 0.0)
let failureStub = StubResponse(statusCode: 404, fileName: "notFound.json", delay: 0.0)

let alternatingStub = AlternatingStub(stubs: [successStub, failureStub])
        
let resource = Resource<String>(
            path: "/peter",
            shouldStub: true,
            stub: alternatingStub)
```
Every time the resource is executed it will iterate over the given stubs an always return a different stub than before.

**Custom stubbing**

You can create a custom stub by conforming to the [Stub](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/Stub/Stub.swift) protocol.
```swift
struct CustomStub: Stub {
...
}
```

### Caching

The following cache types are implemented:
- [Memory](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/Cache/MemoryCache.swift)
- [Disk](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/Cache/DiskCache.swift)
- [Hybrid](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/Cache/HybridCache.swift)

**Setting up a cache**

```swift
let cache = MemoryCache(defaultExpiration: .seconds(3600))
        
let config = Config(
    baseURL: URL(string: "https://example.com")!,
    cache: cache,
    cachePolicy: .networkOnlyUpdateCache
   )
let client = APIClient(config: config)
```

**Note:** To make use of caching the model you load from a resource has to conform to Cacheable.

**Hybrid Cache**

The hybrid cache allows you to combine two separate caches, the cache types used are not limited.

**Custom cache implementations**

To implement a custom cache you have to create a class/struct which conforms to the [Cache](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/Cache/Cache.swift) protocol.

```swift
class SpecialCache: Cache {
...
}
```

**Caching Policies**

A Cache Policy defines the loading behaviour of a resource. You can set a policy directly on a resource when it is created, in the configuration of an APIClient or you can pass it as an argument to the fetch function of the resource.

**Note:** The policy defined in the resource is always preferred over the policy defined in the configuration.

**Load from cache otherwise from network**

This will first try to read the requested data from the cache, if the data is not available or expired the data will be loaded from the network.
```swift
let resource: Resource<X> = ...
resource.fetch(cachePolicy: .cacheFirstNetworkIfNotFoundOrExpired) { result, finishedLoading in 
...
}
```

**Load from network and update cache**

This will load the data from network and update the cache. The completion closure will only be called with the value from the network. 
```swift
let resource: Resource<X> = ...
resource.fetch(cachePolicy: .networkOnlyUpdateCache) { result, finishedLoading in 
...
}
```

**Load data from cache and always from network**

This will load data from the cache and load data from the network. You will get both values in the completion closure asynchronously. 

```swift
let resource: Resource<X> = ...
resource.fetch(cachePolicy: .cacheFirstNetworkAlways) { result, finishedLoading in 
...
}
```

For an overview of policies check out the implementation in [Cache.swift](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/Cache/Cache.swift)

## Carthage

Add the following line to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

```
github "allaboutapps/Fetch", ~> 1.0
```

Then run `carthage update`.

## Requirements

- iOS 11.0+
- Xcode 10.2+
- Swift 5+

## Contributing

* Create something awesome, make the code better, add some functionality,
  whatever (this is the hardest part).
* [Fork it](http://help.github.com/forking/)
* Create new branch to make your changes
* Commit all your changes to your branch
* Submit a [pull request](http://help.github.com/pull-requests/)

