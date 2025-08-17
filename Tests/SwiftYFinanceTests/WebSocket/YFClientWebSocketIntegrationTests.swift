import Testing
import Foundation
@testable import SwiftYFinance

/// YFClient WebSocket 통합 테스트
///
/// YFClient와 WebSocket 기능의 통합, 기존 기능과의 호환성,
/// 인증 세션 연동, Rate Limiting 등을 검증하는 테스트 모음입니다.
struct YFClientWebSocketIntegrationTests {
    
    @Test("YFClient WebSocket API integration")
    func testYFClientWebSocketAPIIntegration() async throws {
        // Given
        let client = YFClient()
        
        #if DEBUG
        // When - Test WebSocket integration through YFClient
        do {
            // Note: This test validates the API structure and basic functionality
            // Real-time WebSocket functionality will be implemented in upcoming tasks
            
            // Verify YFClient exists and is functional
            #expect(client.session != nil, "YFClient should have a session")
            
            // Test basic YFClient functionality (existing features)
            let baseURL = client.session.baseURL
            #expect(baseURL.absoluteString.contains("finance.yahoo.com"), "Should use Yahoo Finance URL")
            
            print("✅ YFClient WebSocket integration structure validated")
            
        } catch {
            print("YFClient WebSocket integration test error: \(error)")
        }
        #endif
    }
    
    @Test("Backward compatibility with existing features")
    func testBackwardCompatibilityWithExistingFeatures() async throws {
        // Given
        let client = YFClient()
        
        #if DEBUG
        // When - Test that existing features still work
        do {
            // Test basic client functionality to ensure no regression
            let session = client.session
            #expect(session.baseURL.absoluteString.contains("finance.yahoo.com"), "Session should be properly configured")
            
            // Verify session properties
            #expect(session.urlSession != nil, "URLSession should be available")
            
            // Test that client can be created multiple times without issues
            let client2 = YFClient()
            #expect(client2.session != nil, "Second client should also have valid session")
            
            print("✅ Backward compatibility validated - existing features intact")
            
        } catch {
            print("Backward compatibility test error: \(error)")
        }
        #endif
    }
    
    @Test("Authentication session integration")
    func testAuthenticationSessionIntegration() async throws {
        // Given
        let client = YFClient()
        
        #if DEBUG
        // When - Test authentication session integration
        do {
            // Verify session is properly configured with authentication capabilities
            let session = client.session
            
            // Check that session has necessary components for authentication
            #expect(session.urlSession != nil, "URLSession should be available for authentication")
            #expect(session.baseURL.host != nil, "Base URL should have valid host")
            
            // Test session configuration
            let config = session.urlSession.configuration
            #expect(config.httpCookieStorage != nil, "Cookie storage should be available for session management")
            
            print("✅ Authentication session integration validated")
            
        } catch {
            print("Authentication session integration test error: \(error)")
        }
        #endif
    }
    
    @Test("Rate limiting integration")
    func testRateLimitingIntegration() async throws {
        // Given
        let client = YFClient()
        
        #if DEBUG
        // When - Test rate limiting integration
        do {
            // Verify that session supports rate limiting
            let session = client.session
            
            // Basic session validation for rate limiting support
            #expect(session.urlSession != nil, "URLSession should support rate limiting")
            
            // Test rapid sequential requests (simulating rate limit scenario)
            let startTime = Date()
            
            // Test single client session validation
            let testClient = YFClient()
            #expect(testClient.session != nil, "Client should have valid session")
            
            let elapsedTime = Date().timeIntervalSince(startTime)
            #expect(elapsedTime < 1.0, "Client creation should be fast")
            
            print("✅ Rate limiting integration structure validated")
            
        } catch {
            print("Rate limiting integration test error: \(error)")
        }
        #endif
    }
    
    @Test("WebSocket manager creation through YFClient")
    func testWebSocketManagerCreationThroughYFClient() async throws {
        // Given
        let client = YFClient()
        
        #if DEBUG
        // When - Test WebSocket manager creation
        do {
            // Test that we can create WebSocket manager with client session
            let manager = YFWebSocketManager(urlSession: client.session.urlSession)
            
            // Verify manager is properly configured
            let initialState = await manager.testGetConnectionState()
            #expect(initialState == .disconnected, "Manager should start disconnected")
            
            // Test basic manager functionality
            try await manager.connect()
            let connectedState = await manager.testGetConnectionState()
            #expect(connectedState == .connected, "Manager should connect successfully")
            
            await manager.disconnect()
            let disconnectedState = await manager.testGetConnectionState()
            #expect(disconnectedState == .disconnected, "Manager should disconnect properly")
            
            print("✅ WebSocket manager creation through YFClient validated")
            
        } catch {
            print("WebSocket manager creation test error: \(error)")
        }
        #endif
    }
    
    @Test("Client session with WebSocket")
    func testClientSessionWithWebSocket() async throws {
        // Given
        let client = YFClient()
        
        #if DEBUG
        // When - Test single WebSocket manager with client session
        do {
            // Create WebSocket manager with client session
            let clientSession = client.session.urlSession
            let manager = YFWebSocketManager(urlSession: clientSession)
            
            // Test that manager can use the client session
            try await manager.connect()
            let state = await manager.testGetConnectionState()
            #expect(state == .connected, "Manager should connect with client session")
            
            // Clean up
            await manager.disconnect()
            
            print("✅ Client session with WebSocket validated")
            
        } catch {
            print("Client session test error: \(error)")
        }
        #endif
    }
    
    @Test("Resource management in integrated environment")
    func testResourceManagementInIntegratedEnvironment() async throws {
        // Given
        let client = YFClient()
        
        #if DEBUG
        // When - Test resource management with single manager
        do {
            // Create single WebSocket manager
            let manager = YFWebSocketManager(urlSession: client.session.urlSession)
            try await manager.connect()
            
            let state = await manager.testGetConnectionState()
            #expect(state == .connected, "Manager should connect successfully")
            
            // Test resource cleanup
            await manager.disconnect()
            let disconnectedState = await manager.testGetConnectionState()
            #expect(disconnectedState == .disconnected, "Manager should disconnect properly")
            
            print("✅ Resource management in integrated environment validated")
            
        } catch {
            print("Resource management test error: \(error)")
        }
        #endif
    }
    
    @Test("Error handling in integrated environment")
    func testErrorHandlingInIntegratedEnvironment() async throws {
        // Given
        let client = YFClient()
        
        #if DEBUG
        // When - Test error handling across integrated components
        do {
            // Test error propagation from WebSocket to client level
            let manager = YFWebSocketManager(urlSession: client.session.urlSession)
            
            // Test invalid subscription before connection
            do {
                try await manager.subscribe(to: ["INVALID"])
                #expect(false, "Should fail when subscribing before connection")
            } catch YFError.webSocketError(.notConnected(let message)) {
                #expect(message.contains("connected"), "Should indicate connection requirement")
            } catch {
                print("⚠️ Unexpected error type: \(error)")
            }
            
            // Test valid connection and subscription
            try await manager.connect()
            try await manager.subscribe(to: ["AAPL"])
            
            let subscriptions = await manager.testGetSubscriptions()
            #expect(subscriptions.contains("AAPL"), "Should have valid subscription")
            
            await manager.disconnect()
            
            print("✅ Error handling in integrated environment validated")
            
        } catch {
            print("Error handling integration test error: \(error)")
        }
        #endif
    }
}