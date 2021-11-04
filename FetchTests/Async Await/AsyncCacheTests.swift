@testable
import Fetch
import XCTest

#if swift(>=5.5.2)

@available(macOS 12, iOS 13, tvOS 15, watchOS 8, *)
class AsyncCacheTests: XCTestCase {
    
    private(set) var client: APIClient!
    private var cache: Cache!
    
    override func setUp() {
        super.setUp()
        cache = createCache()
        client = createAPIClient()
    }
    
    func createCache() -> Cache {
        return MemoryCache(defaultExpiration: .seconds(10.0))
    }
    
    func createAPIClient() -> APIClient {
        let config = Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            cache: cache,
            shouldStub: true
        )
        
        return APIClient(config: config)
    }
    
    func testCacheWithFirstValue() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .cacheFirstNetworkAlways,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "123"), encoder: client.config.encoder, delay: 0.1))
        
        try! resource.cache?.set(ModelA(a: "123"), for: resource)
        
        let expectation = self.expectation(description: "")
        Task {
            
            do {
                let (result, isFinished) = try await resource.fetchAsync(cachePolicy: nil)
                XCTAssertEqual(isFinished, false)
                
                switch result {
                case let .cache(value, _):
                    XCTAssert(value == ModelA(a: "123"), "first value should be from cache")
                case  .network:
                    XCTFail("should never return network response")

                }
                expectation.fulfill()
            } catch {
                XCTFail("should suceed")
            }
            
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCacheWithFinishedValue() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .cacheFirstNetworkAlways,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "123"), encoder: client.config.encoder, delay: 0.1))
        
        try! resource.cache?.set(ModelA(a: "123"), for: resource)
        
        let expectation = self.expectation(description: "")
        Task {
            
            do {
                let (result, isFinished) = try await resource.fetchAsync(behaviour: .waitForFinishedValue)
                XCTAssertEqual(isFinished, true)
                
                switch result {
                case .cache:
                    XCTFail("should wait for network")
                case let .network(_, updated):
                    XCTAssertEqual(updated, false)
                    
                }
                expectation.fulfill()
            } catch {
                XCTFail("should suceed")
            }
            
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCacheWithAsyncSequence() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .cacheFirstNetworkAlways,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "123"), encoder: client.config.encoder, delay: 0.1))
        
        try! resource.cache?.set(ModelA(a: "1234"), for: resource)
        
        let expectation = self.expectation(description: "")
        Task {
            
            do {
                var results = [ModelA]()
                for try await result in resource.fetchAsyncSequence() {
                    results.append(result.model)
                }
                XCTAssert(results.count == 2, "Should send exactly 2 values")
                XCTAssertEqual(results[0].a, "1234", "first result should be from cache")
                XCTAssertEqual(results[1].a, "123", "first result should be from network")
                expectation.fulfill()
            } catch {
                XCTFail("should suceed")
            }
            
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}

#endif
