import XCTest
import Alamofire
import Fetch

#if swift(>=5.5.2)

@available(macOS 12, iOS 13, tvOS 15, watchOS 8, *)
class AsyncTests: XCTestCase {
    
    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: true
        ))
    }
    
    func testSuccessfulStubbingOfDecodable() {
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test")
        
        let stub = StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.1)
        APIClient.shared.stubProvider.register(stub: stub, for: resource)
        
        Task {
            do {
                let result = try await resource.requestAsync()
                XCTAssertEqual(result.model.a, "a")
                expectation.fulfill()
            } catch {
                XCTFail("Request did not return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFailingRequest() {
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test")
        
        let stub = StubResponse(statusCode: 400, encodable: ModelA(a: "a"), delay: 0.1)
        APIClient.shared.stubProvider.register(stub: stub, for: resource)
        
        Task {
            do {
                let _ = try await resource.requestAsync()
                XCTFail("Request should not succeed")
            } catch {
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRequestTokenCanCancelRequest() {
        let expectation = self.expectation(description: "T")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test")
        
        let stub = StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.2)
                APIClient.shared.stubProvider.register(stub: stub, for: resource)
        
        let task = Task {
            do {
                _ = try await resource.requestAsync()
                XCTFail("Request should be cancelled")
            } catch is CancellationError {
                print("cancelled")
            } catch {
                XCTFail("Request should be cancelled")
            }
        }
        task.cancel()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + stub.delay + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
}

#endif
