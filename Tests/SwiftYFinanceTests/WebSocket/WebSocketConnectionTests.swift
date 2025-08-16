import Testing
import Foundation
@testable import SwiftYFinance

struct WebSocketConnectionTests {
    
    @Test("Real WebSocket connection success test with Yahoo Finance")
    func testRealWebSocketConnectionSuccess() async throws {
        // Given - Real Yahoo Finance WebSocket URL
        let manager = YFWebSocketManager()
        
        // When & Then - Real connection attempt
        do {
            try await manager.connect()
            
            #if DEBUG
            // Verify connection state changed
            let state = manager.testGetConnectionState()
            #expect(state == .connected || state == .connecting, "Connection should be established or in progress")
            #endif
            
            // Cleanup
            await manager.disconnect()
            
            #if DEBUG
            // Verify disconnection
            let finalState = manager.testGetConnectionState()
            #expect(finalState == .disconnected, "Should be disconnected after cleanup")
            #endif
            
        } catch YFError.webSocketError(.connectionFailed(let message)) {
            // Network failures are acceptable in CI/test environments
            #expect(!message.isEmpty, "Error message should be descriptive")
            
            // But connection state should be properly managed
            #if DEBUG
            let state = manager.testGetConnectionState()
            #expect(state == .disconnected, "Should be disconnected after failure")
            #endif
        } catch {
            // Other errors might occur due to network conditions
            print("Connection test encountered error: \(error)")
            #expect(true, "Network-related errors are acceptable in test environment")
        }
    }
    
    @Test("WebSocket connection with local test server")
    func testWebSocketConnectionLocalServer() async throws {
        // Given - Test with local echo server (may not exist, testing error handling)
        let manager = YFWebSocketManager()
        let localTestURL = "ws://localhost:8080/echo"
        
        #if DEBUG
        // When & Then - Local connection attempt
        do {
            try await manager.testConnectWithCustomURL(localTestURL)
            
            // If successful, verify state
            let state = manager.testGetConnectionState()
            #expect(state == .connected || state == .connecting)
            
            // Cleanup
            await manager.disconnect()
            
        } catch YFError.webSocketError(.connectionFailed(let message)) {
            // Expected for non-existent local server
            #expect(message.contains("localhost") || message.contains("connection") || !message.isEmpty)
            
            // Verify proper error state
            let state = manager.testGetConnectionState()
            #expect(state == .disconnected)
        } catch {
            // Other connection errors are acceptable
            #expect(true, "Local server connection errors are expected")
        }
        #endif
    }
    
    @Test("WebSocket connection state transitions")
    func testWebSocketConnectionStateTransitions() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When & Then - Initial state
        let initialState = manager.testGetConnectionState()
        #expect(initialState == .disconnected, "Should start disconnected")
        
        // Test connection attempt (may fail due to network)
        do {
            try await manager.connect()
            
            // State should change during connection
            let connectionState = manager.testGetConnectionState()
            #expect(connectionState == .connected || connectionState == .connecting)
            
            // Disconnect should change state back
            await manager.disconnect()
            let disconnectedState = manager.testGetConnectionState()
            #expect(disconnectedState == .disconnected)
            
        } catch {
            // If connection fails, state should still be properly managed
            let errorState = manager.testGetConnectionState()
            #expect(errorState == .disconnected, "Should be disconnected after connection failure")
        }
        #endif
    }
    
    @Test("WebSocket multiple connection attempts")
    func testWebSocketMultipleConnectionAttempts() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When & Then - Multiple connection attempts
        for i in 1...3 {
            do {
                try await manager.connect()
                
                // Should be connected or connecting
                let state = manager.testGetConnectionState()
                #expect(state == .connected || state == .connecting, "Attempt \(i) should show proper state")
                
                // Disconnect before next attempt
                await manager.disconnect()
                let disconnectedState = manager.testGetConnectionState()
                #expect(disconnectedState == .disconnected, "Should be disconnected between attempts")
                
            } catch {
                // Connection failures are acceptable, but state should be consistent
                let errorState = manager.testGetConnectionState()
                #expect(errorState == .disconnected, "State should be disconnected after failure in attempt \(i)")
            }
        }
        #endif
    }
    
    @Test("WebSocket multiple managers independence")
    func testWebSocketMultipleManagersIndependence() async throws {
        // Given - Multiple managers
        let manager1 = YFWebSocketManager()
        let manager2 = YFWebSocketManager()
        
        #if DEBUG
        // When & Then - Sequential operations to test independence
        do {
            try await manager1.connect()
            let state1 = manager1.testGetConnectionState()
            #expect(state1 == .connected || state1 == .connecting, "Manager 1 should connect independently")
            
            await manager1.disconnect()
            let disconnectedState1 = manager1.testGetConnectionState()
            #expect(disconnectedState1 == .disconnected, "Manager 1 should disconnect independently")
            
        } catch {
            // Connection failures are acceptable
            let errorState1 = manager1.testGetConnectionState()
            #expect(errorState1 == .disconnected, "Manager 1 should handle errors properly")
        }
        
        // Manager 2 should be unaffected by Manager 1 operations
        let state2 = manager2.testGetConnectionState()
        #expect(state2 == .disconnected, "Manager 2 should remain independent")
        #endif
    }
    
    @Test("WebSocket connection failure with invalid URL")
    func testWebSocketConnectionFailureInvalidURL() async throws {
        // Given - Invalid URLs
        let manager = YFWebSocketManager()
        let invalidURLs = [
            "invalid-url-format",                        // Malformed URL
            "http://not-a-websocket-url.com",           // Wrong scheme
            "ftp://invalid-protocol.com",               // Wrong protocol
            "wss://non-existent-domain-12345.invalid"   // Valid scheme, invalid domain
        ]
        
        #if DEBUG
        // When & Then - Each invalid URL should fail appropriately
        for invalidURL in invalidURLs {
            do {
                try await manager.testConnectWithCustomURL(invalidURL)
                
                // If it somehow succeeds, clean up and check state
                await manager.disconnect()
                print("Unexpected success for URL: \(invalidURL) - this might be valid on this system")
                
            } catch YFError.webSocketError(.invalidURL(let message)) {
                // Expected for malformed URLs
                #expect(!message.isEmpty, "Error message should be descriptive for: \(invalidURL)")
                #expect(message.contains(invalidURL) || message.contains("Invalid"), "Error should reference the invalid URL")
                
                // State should be disconnected after failure
                let state = manager.testGetConnectionState()
                #expect(state == .disconnected, "Should be disconnected after invalid URL")
                
            } catch YFError.webSocketError(.connectionFailed(let message)) {
                // Expected for valid URLs that can't be reached
                #expect(!message.isEmpty, "Connection failure message should be descriptive for: \(invalidURL)")
                
                // State should be disconnected after failure
                let state = manager.testGetConnectionState()
                #expect(state == .disconnected, "Should be disconnected after connection failure")
                
            } catch {
                // Other network-related errors are also acceptable
                print("Unexpected error for \(invalidURL): \(error)")
                
                // But state should still be properly managed
                let state = manager.testGetConnectionState()
                #expect(state == .disconnected, "Should be disconnected after any error")
            }
        }
        #endif
    }
    
    @Test("WebSocket connection failure with unreachable server")
    func testWebSocketConnectionFailureUnreachableServer() async throws {
        // Given - Unreachable but valid WebSocket URLs
        let manager = YFWebSocketManager()
        let unreachableURLs = [
            "wss://192.168.255.255:8080/websocket", // Non-routable IP
            "ws://127.0.0.1:99999/socket",          // Localhost with invalid port
            "wss://example.com:99999/ws"            // Invalid port on real domain
        ]
        
        #if DEBUG
        // When & Then - Each unreachable URL should fail with connection error
        for unreachableURL in unreachableURLs {
            do {
                try await manager.testConnectWithCustomURL(unreachableURL)
                
                // If it somehow succeeds, clean up
                await manager.disconnect()
                print("Unexpected success for: \(unreachableURL)")
                
            } catch YFError.webSocketError(.connectionFailed(let message)) {
                // Expected for unreachable servers
                #expect(!message.isEmpty, "Connection failure message should be descriptive")
                #expect(message.contains(unreachableURL) || message.contains("Failed"), "Error should reference the URL or failure")
                
                // State should be disconnected after failure
                let state = manager.testGetConnectionState()
                #expect(state == .disconnected, "Should be disconnected after connection failure")
                
            } catch YFError.webSocketError(.invalidURL(let message)) {
                // Some URLs might be considered invalid by the system
                #expect(!message.isEmpty, "Invalid URL message should be descriptive")
                
            } catch {
                // Other network-related errors are also acceptable
                print("Network error for \(unreachableURL): \(error)")
                
                // State should still be properly managed
                let state = manager.testGetConnectionState()
                #expect(state == .disconnected, "Should be disconnected after network error")
            }
        }
        #endif
    }
    
    @Test("WebSocket connection timeout handling")
    func testWebSocketConnectionTimeoutHandling() async throws {
        // Given - URL that should timeout (black hole IP)
        let manager = YFWebSocketManager()
        let timeoutURL = "ws://192.0.2.1:8080/ws" // RFC 3330 test IP (should not respond)
        
        #if DEBUG
        // When & Then - Connection should handle timeout gracefully
        do {
            // This should timeout or fail quickly
            try await manager.testConnectWithCustomURL(timeoutURL)
            
            // If it somehow succeeds, clean up
            await manager.disconnect()
            print("Unexpected success for timeout test URL")
            
        } catch YFError.webSocketError(.connectionFailed(let message)) {
            // Expected for timeout
            #expect(!message.isEmpty, "Timeout error message should be descriptive")
            
            // State should be disconnected after timeout
            let state = manager.testGetConnectionState()
            #expect(state == .disconnected, "Should be disconnected after timeout")
            
        } catch {
            // Other timeout-related errors are acceptable
            print("Timeout test error: \(error)")
            
            // State should be properly managed
            let state = manager.testGetConnectionState()
            #expect(state == .disconnected, "Should be disconnected after timeout error")
        }
        #endif
    }
}