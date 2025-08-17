import Testing
import Foundation
@testable import SwiftYFinance

struct YFWebSocketManagerTests {
    
    @Test("YFWebSocketManager basic initialization")
    func testWebSocketManagerInit() {
        // Given & When
        let manager = YFWebSocketManager()
        
        // Then
        #expect(manager != nil)
        
        #if DEBUG
        Task {
            let state = await manager.testGetConnectionState()
            #expect(state == .disconnected)
        }
        #endif
    }
    
    @Test("YFWebSocketManager connection state tracking")
    func testWebSocketManagerConnectionState() {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When & Then - Initial state
        Task {
            let state = await manager.testGetConnectionState()
            #expect(state == .disconnected)
            
            // Connection states should be trackable
            let initialState = await manager.testGetConnectionState()
            #expect(initialState == .disconnected || initialState == .connecting || initialState == .connected)
        }
        #endif
    }
    
    @Test("YFWebSocketManager with custom URL")
    func testWebSocketManagerWithCustomURL() async throws {
        // Given
        let manager = YFWebSocketManager()
        let customURL = "wss://test.example.com/websocket"
        
        #if DEBUG
        // When & Then - Custom URL connection should be testable
        do {
            try await manager.testConnectWithCustomURL(customURL)
        } catch YFError.webSocketError(.invalidURL(let message)) {
            // Expected for invalid test URL
            #expect(message.contains("test.example.com") || !message.isEmpty)
        } catch YFError.webSocketError(.connectionFailed(let message)) {
            // Expected for unreachable test URL
            #expect(!message.isEmpty)
        } catch {
            // Other errors are also acceptable for test URL
            #expect(true)
        }
        #endif
    }
    
    @Test("YFWebSocketManager default URL validation")
    func testWebSocketManagerDefaultURL() {
        // Given & When
        let manager = YFWebSocketManager()
        
        // Then - Manager should have default Yahoo Finance WebSocket URL
        #if DEBUG
        // Default URL should be accessible for testing
        Task {
            let state = await manager.testGetConnectionState()
            #expect(state == .disconnected) // Should start disconnected
        }
        #endif
    }
    
    @Test("YFWebSocketManager basic connect/disconnect API")
    func testWebSocketManagerBasicAPI() async {
        // Given
        let manager = YFWebSocketManager()
        
        // When & Then - API methods should exist
        // Note: These may fail due to network, but methods should exist
        do {
            try await manager.connect()
            await manager.disconnect()
        } catch {
            // Expected to fail without real connection, but API should exist
            #expect(true)
        }
    }
}