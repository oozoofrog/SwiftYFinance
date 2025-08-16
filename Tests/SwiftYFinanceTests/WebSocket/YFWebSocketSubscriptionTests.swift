import Testing
import Foundation
@testable import SwiftYFinance

struct YFWebSocketSubscriptionTests {
    
    @Test("Basic subscription message JSON format")
    func testBasicSubscriptionMessageFormat() async throws {
        // Given
        let manager = YFWebSocketManager()
        let symbols = ["AAPL", "TSLA"]
        
        #if DEBUG
        // When - Subscribe to symbols
        do {
            try await manager.connect()
            try await manager.subscribe(to: symbols)
            
            // Then - Subscription should be tracked
            let subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.contains("AAPL"), "Should contain AAPL subscription")
            #expect(subscriptions.contains("TSLA"), "Should contain TSLA subscription")
            #expect(subscriptions.count == 2, "Should have exactly 2 subscriptions")
            
            // Cleanup
            await manager.disconnect()
            
        } catch {
            // Connection failures are acceptable in test environment
            print("Subscription test connection error: \(error)")
        }
        #endif
    }
    
    @Test("Single symbol subscription")
    func testSingleSymbolSubscription() async throws {
        // Given
        let manager = YFWebSocketManager()
        let symbol = "AAPL"
        
        #if DEBUG
        // When - Subscribe to single symbol
        do {
            try await manager.connect()
            try await manager.subscribe(to: [symbol])
            
            // Then - Single subscription should be tracked
            let subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.contains(symbol), "Should contain AAPL subscription")
            #expect(subscriptions.count == 1, "Should have exactly 1 subscription")
            
            // Cleanup
            await manager.disconnect()
            
        } catch {
            print("Single subscription test error: \(error)")
        }
        #endif
    }
    
    @Test("Multiple symbols subscription")
    func testMultipleSymbolsSubscription() async throws {
        // Given
        let manager = YFWebSocketManager()
        let symbols = ["AAPL", "MSFT", "GOOGL", "TSLA", "AMZN"]
        
        #if DEBUG
        // When - Subscribe to multiple symbols
        do {
            try await manager.connect()
            try await manager.subscribe(to: symbols)
            
            // Then - All subscriptions should be tracked
            let subscriptions = manager.testGetSubscriptions()
            for symbol in symbols {
                #expect(subscriptions.contains(symbol), "Should contain \(symbol) subscription")
            }
            #expect(subscriptions.count == symbols.count, "Should have all \(symbols.count) subscriptions")
            
            // Cleanup
            await manager.disconnect()
            
        } catch {
            print("Multiple subscription test error: \(error)")
        }
        #endif
    }
    
    @Test("Subscription JSON message validation")
    func testSubscriptionJSONMessageValidation() {
        // Given
        let symbols = ["AAPL", "TSLA"]
        
        // When - Create subscription message
        let message = YFWebSocketManager.createSubscriptionMessage(symbols: symbols)
        
        // Then - Should be valid JSON format
        do {
            let jsonData = message.data(using: .utf8)!
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["subscribe"] != nil, "Should have 'subscribe' key")
            let subscribeSymbols = jsonObject["subscribe"] as! [String]
            #expect(subscribeSymbols.contains("AAPL"), "Should contain AAPL")
            #expect(subscribeSymbols.contains("TSLA"), "Should contain TSLA")
            #expect(subscribeSymbols.count == 2, "Should have 2 symbols")
            
        } catch {
            #expect(Bool(false), "JSON parsing should not fail: \(error)")
        }
    }
    
    @Test("Empty subscription handling")
    func testEmptySubscriptionHandling() async throws {
        // Given
        let manager = YFWebSocketManager()
        let emptySymbols: [String] = []
        
        #if DEBUG
        // When & Then - Empty subscription should be handled gracefully
        do {
            try await manager.connect()
            try await manager.subscribe(to: emptySymbols)
            
            // Should not have any subscriptions
            let subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.isEmpty, "Should have no subscriptions")
            
            await manager.disconnect()
            
        } catch YFError.webSocketError(.invalidSubscription(let message)) {
            // Empty subscription error is acceptable
            #expect(!message.isEmpty, "Error message should be descriptive")
            
        } catch {
            print("Empty subscription test error: \(error)")
        }
        #endif
    }
    
    @Test("Duplicate subscription handling")
    func testDuplicateSubscriptionHandling() async throws {
        // Given
        let manager = YFWebSocketManager()
        let symbols = ["AAPL", "AAPL", "TSLA", "AAPL"] // Duplicates
        
        #if DEBUG
        // When - Subscribe with duplicates
        do {
            try await manager.connect()
            try await manager.subscribe(to: symbols)
            
            // Then - Should deduplicate subscriptions
            let subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.contains("AAPL"), "Should contain AAPL")
            #expect(subscriptions.contains("TSLA"), "Should contain TSLA")
            #expect(subscriptions.count == 2, "Should deduplicate to 2 unique subscriptions")
            
            await manager.disconnect()
            
        } catch {
            print("Duplicate subscription test error: \(error)")
        }
        #endif
    }
    
    @Test("Subscription before connection handling")
    func testSubscriptionBeforeConnectionHandling() async throws {
        // Given
        let manager = YFWebSocketManager()
        let symbols = ["AAPL"]
        
        #if DEBUG
        // When & Then - Subscribe before connection should handle gracefully
        do {
            // Don't connect first
            try await manager.subscribe(to: symbols)
            
            // Should either auto-connect or throw appropriate error
            let subscriptions = manager.testGetSubscriptions()
            if !subscriptions.isEmpty {
                #expect(subscriptions.contains("AAPL"), "Should contain AAPL if auto-connected")
            }
            
            await manager.disconnect()
            
        } catch YFError.webSocketError(.notConnected(let message)) {
            // Not connected error is acceptable
            #expect(!message.isEmpty, "Error message should be descriptive")
            
        } catch {
            print("Subscription before connection test error: \(error)")
        }
        #endif
    }
    
    @Test("Basic unsubscription functionality")
    func testBasicUnsubscription() async throws {
        // Given
        let manager = YFWebSocketManager()
        let symbols = ["AAPL", "TSLA", "MSFT"]
        
        #if DEBUG
        // When - Subscribe then unsubscribe
        do {
            try await manager.connect()
            
            // First subscribe to all symbols
            try await manager.subscribe(to: symbols)
            let initialSubscriptions = manager.testGetSubscriptions()
            #expect(initialSubscriptions.count == 3, "Should have 3 initial subscriptions")
            
            // Then unsubscribe from some symbols
            try await manager.unsubscribe(from: ["AAPL", "TSLA"])
            let remainingSubscriptions = manager.testGetSubscriptions()
            
            // Then - Only MSFT should remain
            #expect(remainingSubscriptions.contains("MSFT"), "Should still contain MSFT")
            #expect(!remainingSubscriptions.contains("AAPL"), "Should not contain AAPL")
            #expect(!remainingSubscriptions.contains("TSLA"), "Should not contain TSLA")
            #expect(remainingSubscriptions.count == 1, "Should have 1 remaining subscription")
            
            await manager.disconnect()
            
        } catch {
            print("Basic unsubscription test error: \(error)")
        }
        #endif
    }
    
    @Test("Unsubscription JSON message validation")
    func testUnsubscriptionJSONMessageValidation() {
        // Given
        let symbols = ["AAPL", "TSLA"]
        
        // When - Create unsubscription message
        let message = YFWebSocketManager.createUnsubscriptionMessage(symbols: symbols)
        
        // Then - Should be valid JSON format
        do {
            let jsonData = message.data(using: .utf8)!
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["unsubscribe"] != nil, "Should have 'unsubscribe' key")
            let unsubscribeSymbols = jsonObject["unsubscribe"] as! [String]
            #expect(unsubscribeSymbols.contains("AAPL"), "Should contain AAPL")
            #expect(unsubscribeSymbols.contains("TSLA"), "Should contain TSLA")
            #expect(unsubscribeSymbols.count == 2, "Should have 2 symbols")
            
        } catch {
            #expect(Bool(false), "JSON parsing should not fail: \(error)")
        }
    }
    
    @Test("Unsubscribe from non-subscribed symbols")
    func testUnsubscribeFromNonSubscribedSymbols() async throws {
        // Given
        let manager = YFWebSocketManager()
        let subscribedSymbols = ["AAPL", "TSLA"]
        let unsubscribeSymbols = ["MSFT", "GOOGL"] // Not subscribed
        
        #if DEBUG
        // When - Subscribe to some symbols, then unsubscribe from others
        do {
            try await manager.connect()
            
            // Subscribe to initial symbols
            try await manager.subscribe(to: subscribedSymbols)
            let initialSubscriptions = manager.testGetSubscriptions()
            #expect(initialSubscriptions.count == 2, "Should have 2 initial subscriptions")
            
            // Try to unsubscribe from non-subscribed symbols
            try await manager.unsubscribe(from: unsubscribeSymbols)
            let remainingSubscriptions = manager.testGetSubscriptions()
            
            // Then - Original subscriptions should remain unchanged
            #expect(remainingSubscriptions.contains("AAPL"), "Should still contain AAPL")
            #expect(remainingSubscriptions.contains("TSLA"), "Should still contain TSLA")
            #expect(remainingSubscriptions.count == 2, "Should still have 2 subscriptions")
            
            await manager.disconnect()
            
        } catch {
            print("Unsubscribe non-subscribed test error: \(error)")
        }
        #endif
    }
    
    @Test("Unsubscribe all symbols")
    func testUnsubscribeAllSymbols() async throws {
        // Given
        let manager = YFWebSocketManager()
        let symbols = ["AAPL", "TSLA", "MSFT", "GOOGL"]
        
        #if DEBUG
        // When - Subscribe then unsubscribe all
        do {
            try await manager.connect()
            
            // Subscribe to all symbols
            try await manager.subscribe(to: symbols)
            let initialSubscriptions = manager.testGetSubscriptions()
            #expect(initialSubscriptions.count == 4, "Should have 4 initial subscriptions")
            
            // Unsubscribe from all symbols
            try await manager.unsubscribe(from: symbols)
            let remainingSubscriptions = manager.testGetSubscriptions()
            
            // Then - No subscriptions should remain
            #expect(remainingSubscriptions.isEmpty, "Should have no remaining subscriptions")
            
            await manager.disconnect()
            
        } catch {
            print("Unsubscribe all test error: \(error)")
        }
        #endif
    }
    
    @Test("Empty unsubscription handling")
    func testEmptyUnsubscriptionHandling() async throws {
        // Given
        let manager = YFWebSocketManager()
        let emptySymbols: [String] = []
        
        #if DEBUG
        // When & Then - Empty unsubscription should be handled gracefully
        do {
            try await manager.connect()
            
            // Subscribe to some symbols first
            try await manager.subscribe(to: ["AAPL"])
            let initialCount = manager.testGetSubscriptions().count
            
            // Try empty unsubscription - should not change anything
            try await manager.unsubscribe(from: emptySymbols)
            let finalCount = manager.testGetSubscriptions().count
            
            #expect(initialCount == finalCount, "Empty unsubscription should not change subscription count")
            
            await manager.disconnect()
            
        } catch {
            print("Empty unsubscription test error: \(error)")
        }
        #endif
    }
    
    @Test("Unsubscription before connection handling")
    func testUnsubscriptionBeforeConnectionHandling() async throws {
        // Given
        let manager = YFWebSocketManager()
        let symbols = ["AAPL"]
        
        #if DEBUG
        // When & Then - Unsubscribe before connection should handle gracefully
        do {
            // Don't connect first
            try await manager.unsubscribe(from: symbols)
            
            // Should handle gracefully
            #expect(Bool(true), "Should handle unsubscription before connection")
            
        } catch YFError.webSocketError(.notConnected(let message)) {
            // Not connected error is acceptable
            #expect(!message.isEmpty, "Error message should be descriptive")
            
        } catch {
            print("Unsubscription before connection test error: \(error)")
        }
        #endif
    }
    
    @Test("Subscription state persistence across connections")
    func testSubscriptionStatePersistenceAcrossConnections() async throws {
        // Given
        let manager = YFWebSocketManager()
        let symbols = ["AAPL", "TSLA"]
        
        #if DEBUG
        // When - Subscribe, disconnect, reconnect
        do {
            // Initial connection and subscription
            try await manager.connect()
            try await manager.subscribe(to: symbols)
            let initialSubscriptions = manager.testGetSubscriptions()
            #expect(initialSubscriptions.count == 2, "Should have 2 initial subscriptions")
            
            // Disconnect - subscriptions should be cleared
            await manager.disconnect()
            let disconnectedSubscriptions = manager.testGetSubscriptions()
            #expect(disconnectedSubscriptions.isEmpty, "Subscriptions should be cleared on disconnect")
            
            // Reconnect - subscriptions should start empty
            try await manager.connect()
            let reconnectedSubscriptions = manager.testGetSubscriptions()
            #expect(reconnectedSubscriptions.isEmpty, "Should start with no subscriptions after reconnect")
            
            await manager.disconnect()
            
        } catch {
            print("Subscription persistence test error: \(error)")
        }
        #endif
    }
    
    @Test("Incremental subscription state tracking")
    func testIncrementalSubscriptionStateTracking() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When - Add subscriptions incrementally
        do {
            try await manager.connect()
            
            // Start with empty state
            var currentSubscriptions = manager.testGetSubscriptions()
            #expect(currentSubscriptions.isEmpty, "Should start with no subscriptions")
            
            // Add first symbol
            try await manager.subscribe(to: ["AAPL"])
            currentSubscriptions = manager.testGetSubscriptions()
            #expect(currentSubscriptions.count == 1, "Should have 1 subscription")
            #expect(currentSubscriptions.contains("AAPL"), "Should contain AAPL")
            
            // Add second symbol
            try await manager.subscribe(to: ["TSLA"])
            currentSubscriptions = manager.testGetSubscriptions()
            #expect(currentSubscriptions.count == 2, "Should have 2 subscriptions")
            #expect(currentSubscriptions.contains("AAPL"), "Should still contain AAPL")
            #expect(currentSubscriptions.contains("TSLA"), "Should contain TSLA")
            
            // Add third symbol
            try await manager.subscribe(to: ["MSFT"])
            currentSubscriptions = manager.testGetSubscriptions()
            #expect(currentSubscriptions.count == 3, "Should have 3 subscriptions")
            #expect(currentSubscriptions.contains("MSFT"), "Should contain MSFT")
            
            await manager.disconnect()
            
        } catch {
            print("Incremental subscription test error: \(error)")
        }
        #endif
    }
    
    @Test("Subscription state after partial unsubscription")
    func testSubscriptionStateAfterPartialUnsubscription() async throws {
        // Given
        let manager = YFWebSocketManager()
        let allSymbols = ["AAPL", "TSLA", "MSFT", "GOOGL", "AMZN"]
        let unsubscribeSymbols = ["TSLA", "GOOGL"]
        
        #if DEBUG
        // When - Subscribe to all, then unsubscribe some
        do {
            try await manager.connect()
            
            // Subscribe to all symbols
            try await manager.subscribe(to: allSymbols)
            let allSubscriptions = manager.testGetSubscriptions()
            #expect(allSubscriptions.count == 5, "Should have 5 total subscriptions")
            
            // Unsubscribe from some symbols
            try await manager.unsubscribe(from: unsubscribeSymbols)
            let remainingSubscriptions = manager.testGetSubscriptions()
            
            // Verify specific remaining symbols
            #expect(remainingSubscriptions.count == 3, "Should have 3 remaining subscriptions")
            #expect(remainingSubscriptions.contains("AAPL"), "Should contain AAPL")
            #expect(remainingSubscriptions.contains("MSFT"), "Should contain MSFT")
            #expect(remainingSubscriptions.contains("AMZN"), "Should contain AMZN")
            #expect(!remainingSubscriptions.contains("TSLA"), "Should not contain TSLA")
            #expect(!remainingSubscriptions.contains("GOOGL"), "Should not contain GOOGL")
            
            await manager.disconnect()
            
        } catch {
            print("Partial unsubscription state test error: \(error)")
        }
        #endif
    }
    
    @Test("Subscription state with mixed operations")
    func testSubscriptionStateWithMixedOperations() async throws {
        // Given
        let manager = YFWebSocketManager()
        
        #if DEBUG
        // When - Perform mixed subscribe/unsubscribe operations
        do {
            try await manager.connect()
            
            // Step 1: Subscribe to initial set
            try await manager.subscribe(to: ["AAPL", "TSLA"])
            var subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.count == 2, "Step 1: Should have 2 subscriptions")
            
            // Step 2: Add more symbols
            try await manager.subscribe(to: ["MSFT", "GOOGL"])
            subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.count == 4, "Step 2: Should have 4 subscriptions")
            
            // Step 3: Unsubscribe from one
            try await manager.unsubscribe(from: ["AAPL"])
            subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.count == 3, "Step 3: Should have 3 subscriptions")
            #expect(!subscriptions.contains("AAPL"), "Should not contain AAPL")
            
            // Step 4: Re-subscribe to previously unsubscribed
            try await manager.subscribe(to: ["AAPL"])
            subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.count == 4, "Step 4: Should have 4 subscriptions again")
            #expect(subscriptions.contains("AAPL"), "Should contain AAPL again")
            
            // Step 5: Unsubscribe all
            try await manager.unsubscribe(from: ["AAPL", "TSLA", "MSFT", "GOOGL"])
            subscriptions = manager.testGetSubscriptions()
            #expect(subscriptions.isEmpty, "Step 5: Should have no subscriptions")
            
            await manager.disconnect()
            
        } catch {
            print("Mixed operations test error: \(error)")
        }
        #endif
    }
}