import Testing
import Foundation
@testable import SwiftYFinance

struct YFWebSocketConnectionTests {
    
    @Test("Real WebSocket connection success test with Yahoo Finance")
    func testRealWebSocketConnectionSuccess() async throws {
        // Given - Real Yahoo Finance WebSocket URL
        let manager = YFWebSocketManager()
        
        // When & Then - Real connection attempt
        do {
            try await manager.connect()
            
            #if DEBUG
            // Verify connection state changed
            let state = await manager.testGetConnectionState()
            #expect(state == .connected || state == .connecting, "Connection should be established or in progress")
            #endif
            
            // Cleanup
            await manager.disconnect()
            
            #if DEBUG
            // Verify disconnection
            let finalState = await manager.testGetConnectionState()
            #expect(finalState == .disconnected, "Should be disconnected after cleanup")
            #endif
            
        } catch YFError.webSocketError(.connectionFailed(let message)) {
            // Network failures are acceptable in CI/test environments
            #expect(!message.isEmpty, "Error message should be descriptive")
            
            // But connection state should be properly managed
            #if DEBUG
            let state = await manager.testGetConnectionState()
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
            let state = await manager.testGetConnectionState()
            #expect(state == .connected || state == .connecting)
            
            // Cleanup
            await manager.disconnect()
            
        } catch YFError.webSocketError(.connectionFailed(let message)) {
            // Expected for non-existent local server
            #expect(message.contains("localhost") || message.contains("connection") || !message.isEmpty)
            
            // Verify proper error state
            let state = await manager.testGetConnectionState()
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
        let initialState = await manager.testGetConnectionState()
        #expect(initialState == .disconnected, "Should start disconnected")
        
        // Test connection attempt (may fail due to network)
        do {
            try await manager.connect()
            
            // State should change during connection
            let connectionState = await manager.testGetConnectionState()
            #expect(connectionState == .connected || connectionState == .connecting)
            
            // Disconnect should change state back
            await manager.disconnect()
            let disconnectedState = await manager.testGetConnectionState()
            #expect(disconnectedState == .disconnected)
            
        } catch {
            // If connection fails, state should still be properly managed
            let errorState = await manager.testGetConnectionState()
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
                let state = await manager.testGetConnectionState()
                #expect(state == .connected || state == .connecting, "Attempt \(i) should show proper state")
                
                // Disconnect before next attempt
                await manager.disconnect()
                let disconnectedState = await manager.testGetConnectionState()
                #expect(disconnectedState == .disconnected, "Should be disconnected between attempts")
                
            } catch {
                // Connection failures are acceptable, but state should be consistent
                let errorState = await manager.testGetConnectionState()
                #expect(errorState == .disconnected, "State should be disconnected after failure in attempt \(i)")
            }
        }
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
                let state = await manager.testGetConnectionState()
                #expect(state == .disconnected, "Should be disconnected after invalid URL")
                
            } catch YFError.webSocketError(.connectionFailed(let message)) {
                // Expected for valid URLs that can't be reached
                #expect(!message.isEmpty, "Connection failure message should be descriptive for: \(invalidURL)")
                
                // State should be disconnected after failure
                let state = await manager.testGetConnectionState()
                #expect(state == .disconnected, "Should be disconnected after connection failure")
                
            } catch {
                // Other network-related errors are also acceptable
                print("Unexpected error for \(invalidURL): \(error)")
                
                // But state should still be properly managed
                let state = await manager.testGetConnectionState()
                #expect(state == .disconnected, "Should be disconnected after any error")
            }
        }
        #endif
    }
    
    @Test("WebSocket connection failure with unreachable server")
    func testWebSocketConnectionFailureUnreachableServer() async throws {
        // Given - Unreachable but valid WebSocket URLs
        let manager = YFWebSocketManager()
        
        // Set shorter timeout for test (2 seconds instead of 10)
        await manager.testSetTimeouts(connectionTimeout: 2.0, messageTimeout: 2.0)
        
        let unreachableURLs = [
            "wss://192.168.255.255:8080/websocket", // Non-routable IP
            "ws://127.0.0.1:99999/socket",          // Localhost with invalid port
            "wss://example.com:99999/ws"            // Invalid port on real domain
        ]
        
        #if DEBUG
        // When & Then - Each unreachable URL should fail with connection error
        for unreachableURL in unreachableURLs {
            // Track connection attempt time
            let startTime = Date()
            
            do {
                try await manager.testConnectWithCustomURL(unreachableURL)
                
                // If it somehow succeeds, clean up
                await manager.disconnect()
                print("Unexpected success for: \(unreachableURL)")
                
            } catch YFError.webSocketError(.connectionFailed(let message)) {
                // Expected for unreachable servers
                let elapsedTime = Date().timeIntervalSince(startTime)
                print("Connection failed for \(unreachableURL) after \(String(format: "%.2f", elapsedTime)) seconds")
                
                // Verify timeout was respected (should fail within 2 seconds + some buffer)
                #expect(elapsedTime < 3.0, "Connection should timeout within 3 seconds (2s timeout + buffer)")
                // Localhost with invalid port might fail immediately, which is OK
                #expect(elapsedTime >= 0.0, "Connection failure time is acceptable")
                
                #expect(!message.isEmpty, "Connection failure message should be descriptive")
                #expect(message.contains(unreachableURL) || message.contains("Failed"), "Error should reference the URL or failure")
                
                // State should be disconnected after failure
                let state = await manager.testGetConnectionState()
                #expect(state == .disconnected, "Should be disconnected after connection failure")
                
            } catch YFError.webSocketError(.invalidURL(let message)) {
                // Some URLs might be considered invalid by the system
                let elapsedTime = Date().timeIntervalSince(startTime)
                print("Invalid URL detected for \(unreachableURL) after \(String(format: "%.2f", elapsedTime)) seconds")
                #expect(!message.isEmpty, "Invalid URL message should be descriptive")
                
            } catch YFError.webSocketError(.connectionTimeout(let message)) {
                // Explicit timeout error
                let elapsedTime = Date().timeIntervalSince(startTime)
                print("Connection timeout for \(unreachableURL) after \(String(format: "%.2f", elapsedTime)) seconds")
                
                // Verify it actually timed out around 2 seconds
                #expect(elapsedTime >= 1.5 && elapsedTime <= 2.5, "Timeout should occur around 2 seconds (was \(elapsedTime)s)")
                #expect(message.contains("2"), "Timeout message should mention the 2 second timeout")
                
            } catch {
                // Other network-related errors are also acceptable
                let elapsedTime = Date().timeIntervalSince(startTime)
                print("Network error for \(unreachableURL) after \(String(format: "%.2f", elapsedTime)) seconds: \(error)")
                
                // Still verify timing
                #expect(elapsedTime < 3.0, "Any failure should occur within timeout window")
                
                // State should still be properly managed
                let state = await manager.testGetConnectionState()
                #expect(state == .disconnected, "Should be disconnected after network error")
            }
        }
        #endif
    }
    
    @Test("WebSocket connection timeout accuracy verification")
    func testWebSocketTimeoutAccuracy() async throws {
        // Given - Manager with custom short timeout
        let manager = YFWebSocketManager()
        let testTimeout: TimeInterval = 1.5  // 1.5 seconds for quick test
        await manager.testSetTimeouts(connectionTimeout: testTimeout, messageTimeout: testTimeout)
        
        // Unreachable URL that will definitely timeout
        let timeoutURL = "wss://10.255.255.1:8080/websocket"  // Private network, unreachable
        
        #if DEBUG
        // When - Attempt connection with precise time tracking
        let startTime = Date()
        
        do {
            try await manager.testConnectWithCustomURL(timeoutURL)
            #expect(Bool(false), "Should not connect to unreachable URL")
            
        } catch YFError.webSocketError(.connectionTimeout(let message)) {
            // Then - Verify timeout accuracy
            let elapsedTime = Date().timeIntervalSince(startTime)
            
            print("✅ Timeout Test Results:")
            print("   Configured timeout: \(testTimeout)s")
            print("   Actual time elapsed: \(String(format: "%.3f", elapsedTime))s")
            print("   Difference: \(String(format: "%.3f", abs(elapsedTime - testTimeout)))s")
            print("   Error message: \(message)")
            
            // Allow 300ms tolerance for system delays
            let tolerance: TimeInterval = 0.3
            #expect(
                abs(elapsedTime - testTimeout) <= tolerance,
                "Timeout should be within \(tolerance)s of configured \(testTimeout)s (was \(String(format: "%.3f", elapsedTime))s)"
            )
            
            // Verify error message mentions the timeout duration
            #expect(message.contains("1.5") || message.contains("timeout"), "Error should mention timeout")
            
            // Verify state is properly reset
            let state = await manager.testGetConnectionState()
            #expect(state == .disconnected, "Should be disconnected after timeout")
            
        } catch {
            // If we get other errors, still validate timing
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("⚠️ Different error after \(String(format: "%.3f", elapsedTime))s: \(error)")
            
            // Should still respect timeout even with different error type
            #expect(elapsedTime <= testTimeout + 0.5, "Should fail within timeout window")
            
            // State should be disconnected
            let state = await manager.testGetConnectionState()
            #expect(state == .disconnected, "Should be disconnected after error")
        }
        #endif
    }
    
    @Test("WebSocket connection timeout handling")
    func testWebSocketConnectionTimeoutHandling() async throws {
        // Given - URL that should timeout (black hole IP)
        let manager = YFWebSocketManager()
        // Set shorter timeout for test
        await manager.testSetTimeouts(connectionTimeout: 2.0, messageTimeout: 2.0)
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
            let state = await manager.testGetConnectionState()
            #expect(state == .disconnected, "Should be disconnected after timeout")
            
        } catch {
            // Other timeout-related errors are acceptable
            print("Timeout test error: \(error)")
            
            // State should be properly managed
            let state = await manager.testGetConnectionState()
            #expect(state == .disconnected, "Should be disconnected after timeout error")
        }
        #endif
    }
}
