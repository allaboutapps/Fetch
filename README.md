# Fetch

![Bitrise](https://app.bitrise.io/app/c7d1932e4398ffc9/status.svg?token=2gddfiJReIY_-JaeahuRAg&branch=master)
![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat)

Fetch is a resource based network abstraction based on [Alamofire](https://github.com/Alamofire/Alamofire) 

## Features

- [x] Define API using typed resources
- [x] Decode HTTP response body using Decodable
- [x] Encode HTTP request body using Encodable
- [x] Root keys: decode multiple wrapper container
- [x] Logging
- [x] Stubbing
  - [x] Simple response or error
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

Lets create a struct named `Organization` with a few properties.
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

### Content parsing

Per default the configuration uses the JSONDecoder and JSONEncoder provided by the standard library but is not limited to it, both of these types have been extended to conform to [ResourceDecoderProtocol](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/Utilities/ResourceDecoderProtocol.swift) and [ResourceEncoderProtocol](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/Utilities/ResourceEncoderProtocol.swift) that allows you to define your own custom decoder/encoder. The Resource provides decoding and encoding closures that use the decoder and encoder defined in the configuration. If you want to implement a different behaviour for a resource you can provide a closure during the creation of a resource. 

**Payload unwrapping**

Sometimes there is content that is packed in an envelop and makes parsing difficult. In this case you can define so called "root keys". Root keys define a path to the content in the envelop you want to parse. This means that only the content defined with the root keys will be parsed.

**Example**

This is a response that should be parsed.
```json
{
  "data": {
    "people": [
        {
          "name": "Alex"
        },
        {
          "name": "Jeff"
        },
        {
          "name": "Tom"
        },
        {
          "name": "Xavier"
        }
    ]
  }
}
```

We only want the people which is an array of Person.
Instead of defining a structure that models the hierachy we define "root keys" on a resource to only get the array.
```swift

struct Person: Decodable {
    let name: String
}

let resource = Resource<[Person]>(
    path: "/people",
    rootKeys: ["data", "people"]
)
resource.request { result in
...
}
```

### Stubbing

Fetch gives you a versatile set of possibilities to perform stubbing.
To perform stubbing `shouldStub` on APIClients Config have to be enabled and a stub have to be registered for a resource.

**Simulate a successful network request with a json response**

```swift
let stub = StubResponse(statusCode: 200, fileName: "success.json", delay: 2.0)
        
let resource = Resource<Person>(path: "/test")
    
APIClient.shared.stubProvider.register(stub: stub, for: resource)
    
```
The above stub will return a 200 status code with the content from the success json file loaded from your app's bundle and will be delayed by two seconds.

**Simulate an unauthorized error**

```swift
let stub = StubResponse(statusCode: 401, fileName: "unauthorized.json", delay: 2.0)
        
let resource = Resource<Person>(path: "/unauthorized")
    
APIClient.shared.stubProvider.register(stub: stub, for: resource)
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
        
let resource = Resource<Person>(path: "/peter")
    
APIClient.shared.stubProvider.register(stub: stub, for: resource)
```

**Alternating stubbing**

 ```swift
let successStub = StubResponse(statusCode: 200, fileName: "success.json", delay: 0.0)
let failureStub = StubResponse(statusCode: 404, fileName: "notFound.json", delay: 0.0)

let alternatingStub = AlternatingStub(stubs: [successStub, failureStub])
        
let resource = Resource<Person>(path: "/peter")
    
APIClient.shared.stubProvider.register(stub: alternatingStub, for: resource)
```

Every time the resource is executed it will iterate over the given stubs and always return a different stub than before.

**Random stubbing**

The `RandomStub` works similar to the `AlternatingStub` but always returns a random stub from the array.

**Conditional stubbing**

Simulating behaviour based on specific conditions is something that can be realised with conditional stubbing.

**Example**

Simulate an endpoint that is protected by user authorization and return a success or an error based on the authorization state of your app

```swift
let conditionalStub = ClosureStub { () -> Stub in
let unauthorizedStub = StubResponse(statusCode: 401, data: Data(), delay: 2)
let okStub = StubResponse(statusCode: 200, data: Data(), delay: 2)
  return CredentialsController.shared.currentCredentials == nil ? unauthorizedStub : okStub
}

let resource = Resource(path: "/auth/secret")
    
APIClient.shared.stubProvider.register(stub: conditionalStub, for: resource)
```

**Custom stubbing**

You can create a custom stub by conforming to the [Stub](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/Stub/Stub.swift) protocol.
```swift
struct CustomStub: Stub {
...
}
```

**Custom StubProvider**

You can create a custom `StubProvider` by conforming to the [StubProvider](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/StubProvider/StubProvider.swift) protocol.
```swift
struct CustomStubProvider: StubProvider {
...
}
```
Init/Setup APIClient with custom stubProvider
```
let client = APIClient(config: Config(stubProvider: customStubProvider))
APIClient.shared.setup(with: Config(stubProvider: customStubProvider))
```

Or, replace default StubProvider on APIClient
```
APIClient.shared.setStubProvider(customStubProvider)
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
    cachePolicy: .networkOnlyUpdateCache)

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
resource.fetch(cachePolicy: .cacheFirstNetworkIfNotFoundOrExpired) { (result, finishedLoading) in 
    ...
}
```

**Load from network and update cache**

This will load the data from network and update the cache. The completion closure will only be called with the value from the network. 
```swift
let resource: Resource<Person> = ...
resource.fetch(cachePolicy: .networkOnlyUpdateCache) { (result, finishedLoading) in 
...
}
```

**Load data from cache and always from network**

This will load data from the cache and load data from the network. You will get both values in the completion closure asynchronously. 

```swift
let resource: Resource<Person> = ...
resource.fetch(cachePolicy: .cacheFirstNetworkAlways) { (result, finishedLoading) in 
    ...
}
```

For an overview of policies check out the implementation in [Cache.swift](https://github.com/allaboutapps/Fetch/blob/master/Fetch/Code/Cache/Cache.swift)

## Swift Package Manager

Use Xcode 11+:
Go to `Project > Swift Packages > +` and enter `git@github.com:allaboutapps/Fetch.git`

Or update your Package.swift file manually:

```swift
dependencies: [
    .package(url: "git@github.com:allaboutapps/Fetch.git", from: "1.0.9"),
    ....
],
targets: [
    .target(name: "YourApp", dependencies: ["Fetch"]),
]
```

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

