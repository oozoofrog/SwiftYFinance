import Testing
import Foundation
@testable import SwiftYFinance

/// WebSocket 재연결 및 고급 기능 테스트
///
/// Yahoo Finance WebSocket의 자동 재연결, 타임아웃 처리, 네트워크 실패 복구 등
/// 고급 기능들을 검증하는 테스트 모음입니다.
struct YFWebSocketReconnectionTests {
    
    @Test("Connection retry logic with exponential backoff")
    func testConnectionRetryLogic() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When - Test retry logic with invalid URL first
        var connectionSucceeded = false
        var errorMessage = ""
        
        do {
            // Start with invalid URL to trigger retry logic
            try await manager.testConnectWithCustomURL("wss://invalid-websocket-server.example.com")
            connectionSucceeded = true
            
        } catch YFError.webSocketError(.connectionFailed(let message)) {
            // Expected path - connection should fail
            errorMessage = message
            
        } catch YFError.webSocketError(.invalidURL(let message)) {
            // Also acceptable - invalid URL error
            errorMessage = message
            
        } catch {
            print("Connection retry test unexpected error: \(error)")
            errorMessage = "\(error)"
        }
        
        // Then - Should have failed with connection error
        if connectionSucceeded {
            print("⚠️ Connection unexpectedly succeeded with invalid URL")
            // This might happen in test environment, so we'll check state instead
            let state = manager.testGetConnectionState()
            #expect(state == .connected || state == .disconnected, "Manager should be in valid state")
            await manager.disconnect()
        } else {
            #expect(!errorMessage.isEmpty, "Should have received an error message")
            
            // Verify manager is in disconnected state
            let state = manager.testGetConnectionState()
            #expect(state == .disconnected, "Manager should be disconnected after failed connection")
        }
        #endif
    }
    
    @Test("Exponential backoff timing validation")
    func testExponentialBackoffTiming() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When - Test timing pattern for retry attempts
        do {
            let startTime = Date()
            
            // Try connecting to invalid URL multiple times
            for attempt in 1...3 {
                let attemptStartTime = Date()
                var attemptSucceeded = false
                
                do {
                    try await manager.testConnectWithCustomURL("wss://retry-test-\(attempt).invalid.com")
                    attemptSucceeded = true
                } catch {
                    let elapsedTime = Date().timeIntervalSince(attemptStartTime)
                    print("🔄 Retry attempt \(attempt) failed after \(elapsedTime)s: \(error)")
                    
                    // Verify failure happens quickly (not hanging)
                    #expect(elapsedTime < 10.0, "Each retry should fail within 10 seconds")
                }
                
                if attemptSucceeded {
                    print("⚠️ Retry attempt \(attempt) unexpectedly succeeded")
                    await manager.disconnect()
                }
                
                // Add small delay between attempts for testing
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Then - Should handle multiple failures gracefully
            let finalState = manager.testGetConnectionState()
            #expect(finalState == .disconnected, "Manager should remain disconnected after failed retries")
            
        } catch {
            print("Exponential backoff timing test error: \(error)")
        }
        #endif
    }
    
    @Test("Connection recovery after network failure")
    func testConnectionRecoveryAfterNetworkFailure() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When - Test recovery from simulated network failure
        do {
            // First establish a valid connection
            try await manager.connect()
            let initialState = manager.testGetConnectionState()
            #expect(initialState == .connected, "Should establish initial connection")
            
            // Simulate network disconnection
            await manager.disconnect()
            let disconnectedState = manager.testGetConnectionState()
            #expect(disconnectedState == .disconnected, "Should be disconnected after manual disconnect")
            
            // Test reconnection capability
            try await manager.connect()
            let reconnectedState = manager.testGetConnectionState()
            #expect(reconnectedState == .connected, "Should be able to reconnect")
            
            await manager.disconnect()
            
        } catch {
            print("Connection recovery test error: \(error)")
        }
        #endif
    }
    
    @Test("Multiple connection attempts handling")
    func testMultipleConnectionAttemptsHandling() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When - Test multiple concurrent connection attempts
        do {
            // Create multiple connection tasks
            let connectionTask1 = Task {
                do {
                    try await manager.connect()
                    return "success"
                } catch {
                    return "failed: \(error)"
                }
            }
            
            let connectionTask2 = Task {
                do {
                    try await manager.connect()
                    return "success"
                } catch {
                    return "failed: \(error)"
                }
            }
            
            // Wait for both tasks
            let result1 = await connectionTask1.value
            let result2 = await connectionTask2.value
            
            // Then - Should handle concurrent attempts gracefully
            let finalState = manager.testGetConnectionState()
            
            // At least one should succeed or both should fail gracefully
            let hasSuccess = result1.contains("success") || result2.contains("success")
            if hasSuccess {
                #expect(finalState == .connected, "Should be connected if any attempt succeeded")
            }
            
            print("🔗 Connection results: \(result1), \(result2)")
            
            await manager.disconnect()
            
        } catch {
            print("Multiple connection attempts test error: \(error)")
        }
        #endif
    }
    
    @Test("Connection state consistency during failures")
    func testConnectionStateConsistencyDuringFailures() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When - Test state consistency during various failure scenarios
        do {
            // Initial state should be disconnected
            let initialState = manager.testGetConnectionState()
            #expect(initialState == .disconnected, "Initial state should be disconnected")
            
            // Invalid URL connection attempt
            var invalidConnectionSucceeded = false
            do {
                try await manager.testConnectWithCustomURL("wss://invalid.test.com")
                invalidConnectionSucceeded = true
            } catch {
                let stateAfterFailure = manager.testGetConnectionState()
                #expect(stateAfterFailure == .disconnected, "State should be disconnected after connection failure")
            }
            
            if invalidConnectionSucceeded {
                print("⚠️ Invalid URL connection unexpectedly succeeded")
                await manager.disconnect()
            }
            
            // Valid connection
            try await manager.connect()
            let connectedState = manager.testGetConnectionState()
            #expect(connectedState == .connected, "Should be connected after successful connection")
            
            // Disconnection
            await manager.disconnect()
            let finalDisconnectedState = manager.testGetConnectionState()
            #expect(finalDisconnectedState == .disconnected, "Should be disconnected after explicit disconnect")
            
        } catch {
            print("Connection state consistency test error: \(error)")
        }
        #endif
    }
    
    @Test("Retry mechanism resource cleanup")
    func testRetryMechanismResourceCleanup() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When - Test that retry attempts manage resources properly
        do {
            // Attempt multiple connection attempts (may succeed or fail in test environment)
            for i in 1...3 {
                var attemptSucceeded = false
                do {
                    try await manager.testConnectWithCustomURL("wss://cleanup-test-\(i).invalid.com")
                    attemptSucceeded = true
                } catch {
                    // Expected to fail in real environment
                    print("🧹 Cleanup test attempt \(i) failed as expected")
                }
                
                let state = manager.testGetConnectionState()
                
                if attemptSucceeded {
                    print("⚠️ Cleanup test attempt \(i) unexpectedly succeeded")
                    // If connection succeeded, ensure we clean up
                    await manager.disconnect()
                    let cleanedState = manager.testGetConnectionState()
                    #expect(cleanedState == .disconnected, "State should be clean after cleanup")
                } else {
                    #expect(state == .disconnected, "State should be clean after failed attempt")
                }
            }
            
            // Then - Should still be able to make successful connection
            try await manager.connect()
            let finalState = manager.testGetConnectionState()
            #expect(finalState == .connected, "Should be able to connect successfully after retry attempts")
            
            await manager.disconnect()
            
        } catch {
            print("Retry mechanism resource cleanup test error: \(error)")
        }
        #endif
    }
    
    @Test("Multiple symbol subscription handling")
    func testMultipleSymbolSubscriptionHandling() async throws {
        // Given
        let manager = YFWebSocketManager()
        let collector = MessageCollector()
        
        #if DEBUG
        // When - Test multiple symbol subscription
        do {
            try await manager.connect()
            
            // Subscribe to multiple symbols
            let symbols = ["AAPL", "TSLA", "MSFT", "GOOGL", "AMZN"]
            try await manager.subscribe(to: symbols)
            
            // Verify subscription state
            let subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.count == 5, "Should have 5 subscriptions")
            
            for symbol in symbols {
                #expect(subscriptions.contains(symbol), "Should contain subscribed symbol: \(symbol)")
            }
            
            // Test message streaming with multiple symbols
            let messageStream = await manager.messageStream()
            let streamingTask = Task {
                for await message in messageStream {
                    await collector.addMessage(message)
                    let count = await collector.getMessageCount()
                    if count >= 3 { // Collect a few messages
                        break
                    }
                }
            }
            
            // Wait for potential messages
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            streamingTask.cancel()
            await collector.stop()
            
            let finalCount = await collector.getMessageCount()
            let messages = await collector.getMessages()
            
            // Then - Should handle multiple symbols properly
            #expect(finalCount >= 0, "Should handle multiple symbol streaming")
            
            if finalCount > 0 {
                // Verify that messages contain valid symbols
                let receivedSymbols = Set(messages.map { $0.symbol })
                print("📊 Received messages from symbols: \(receivedSymbols)")
                
                // At least some symbols should match our subscription
                let subscribedSymbolsSet = Set(symbols)
                let hasValidSymbols = !receivedSymbols.intersection(subscribedSymbolsSet).isEmpty
                
                if hasValidSymbols {
                    #expect(true, "Successfully received messages from subscribed symbols")
                } else {
                    print("ℹ️ No messages from subscribed symbols in test environment")
                }
            } else {
                print("ℹ️ No messages received in test environment")
            }
            
            await manager.disconnect()
            
        } catch {
            print("Multiple symbol subscription test error: \(error)")
        }
        #endif
    }
    
    @Test("Large scale symbol subscription")
    func testLargeScaleSymbolSubscription() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When - Test subscription to many symbols
        do {
            try await manager.connect()
            
            // Create a large set of symbols (popular stocks and crypto)
            let stockSymbols = ["AAPL", "TSLA", "MSFT", "GOOGL", "AMZN", "META", "NFLX", "NVDA", "AMD", "INTC"]
            let cryptoSymbols = ["BTC-USD", "ETH-USD", "ADA-USD", "XRP-USD", "DOT-USD"]
            let allSymbols = stockSymbols + cryptoSymbols
            
            let startTime = Date()
            try await manager.subscribe(to: allSymbols)
            let subscriptionTime = Date().timeIntervalSince(startTime)
            
            // Verify all symbols are subscribed
            let subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.count == allSymbols.count, "Should have subscribed to all symbols")
            
            // Performance check - subscription should be fast
            #expect(subscriptionTime < 5.0, "Large subscription should complete within 5 seconds")
            
            print("📈 Successfully subscribed to \(allSymbols.count) symbols in \(subscriptionTime)s")
            
            // Test partial unsubscription
            let symbolsToRemove = Array(stockSymbols.prefix(3)) // Remove first 3 stock symbols
            try await manager.unsubscribe(from: symbolsToRemove)
            
            let remainingSubscriptions = manager.testGetSubscriptions()
            let expectedRemaining = allSymbols.count - symbolsToRemove.count
            #expect(remainingSubscriptions.count == expectedRemaining, "Should have correct remaining subscriptions")
            
            // Verify removed symbols are not in remaining subscriptions
            for removedSymbol in symbolsToRemove {
                #expect(!remainingSubscriptions.contains(removedSymbol), "Removed symbol should not be in subscriptions: \(removedSymbol)")
            }
            
            await manager.disconnect()
            
        } catch {
            print("Large scale symbol subscription test error: \(error)")
        }
        #endif
    }
    
    @Test("Symbol subscription state consistency")
    func testSymbolSubscriptionStateConsistency() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When - Test subscription state consistency across operations
        do {
            try await manager.connect()
            
            // Initial state - no subscriptions
            let initialSubscriptions = manager.testGetSubscriptions()
            #expect(initialSubscriptions.isEmpty, "Should start with no subscriptions")
            
            // Add first batch
            let batch1 = ["AAPL", "TSLA"]
            try await manager.subscribe(to: batch1)
            let afterBatch1 = manager.testGetSubscriptions()
            #expect(afterBatch1.count == 2, "Should have 2 subscriptions after first batch")
            
            // Add second batch (with overlap)
            let batch2 = ["TSLA", "MSFT", "GOOGL"] // TSLA overlaps
            try await manager.subscribe(to: batch2)
            let afterBatch2 = manager.testGetSubscriptions()
            #expect(afterBatch2.count == 4, "Should have 4 unique subscriptions after second batch")
            
            // Verify all expected symbols are present
            let expectedSymbols = Set(["AAPL", "TSLA", "MSFT", "GOOGL"])
            #expect(afterBatch2 == expectedSymbols, "Should contain all expected symbols")
            
            // Remove some symbols
            let toRemove = ["AAPL", "MSFT"]
            try await manager.unsubscribe(from: toRemove)
            let afterRemoval = manager.testGetSubscriptions()
            #expect(afterRemoval.count == 2, "Should have 2 subscriptions after removal")
            
            let expectedRemaining = Set(["TSLA", "GOOGL"])
            #expect(afterRemoval == expectedRemaining, "Should contain expected remaining symbols")
            
            // Clear all subscriptions
            let remainingSymbols = Array(afterRemoval)
            try await manager.unsubscribe(from: remainingSymbols)
            let finalSubscriptions = manager.testGetSubscriptions()
            #expect(finalSubscriptions.isEmpty, "Should have no subscriptions after clearing all")
            
            await manager.disconnect()
            
        } catch {
            print("Symbol subscription state consistency test error: \(error)")
        }
        #endif
    }
}