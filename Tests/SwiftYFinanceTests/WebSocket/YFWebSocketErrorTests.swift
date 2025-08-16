import Testing
import Foundation
@testable import SwiftYFinance

struct YFWebSocketErrorTests {
    
    @Test("YFWebSocketError connection error cases")
    func testWebSocketConnectionErrors() {
        // Given & When & Then
        let invalidURL = YFError.webSocketError(.invalidURL("invalid://url"))
        let connectionFailed = YFError.webSocketError(.connectionFailed("Connection refused"))
        let authenticationFailed = YFError.webSocketError(.authenticationFailed("Invalid credentials"))
        
        // Verify error types
        if case .webSocketError(let wsError) = invalidURL,
           case .invalidURL(let message) = wsError {
            #expect(message == "invalid://url")
        } else {
            #expect(Bool(false), "Expected invalidURL error")
        }
        
        if case .webSocketError(let wsError) = connectionFailed,
           case .connectionFailed(let message) = wsError {
            #expect(message == "Connection refused")
        } else {
            #expect(Bool(false), "Expected connectionFailed error")
        }
        
        if case .webSocketError(let wsError) = authenticationFailed,
           case .authenticationFailed(let message) = wsError {
            #expect(message == "Invalid credentials")
        } else {
            #expect(Bool(false), "Expected authenticationFailed error")
        }
    }
    
    @Test("YFWebSocketError protocol and decoding errors")
    func testWebSocketProtocolErrors() {
        // Given & When & Then
        let protocolError = YFError.webSocketError(.protocolError("Invalid protocol"))
        let decodingError = YFError.webSocketError(.messageDecodingFailed("Failed to decode protobuf"))
        let subscriptionError = YFError.webSocketError(.subscriptionFailed("Invalid symbol"))
        
        // Verify error types
        if case .webSocketError(let wsError) = protocolError,
           case .protocolError(let message) = wsError {
            #expect(message == "Invalid protocol")
        } else {
            #expect(Bool(false), "Expected protocolError")
        }
        
        if case .webSocketError(let wsError) = decodingError,
           case .messageDecodingFailed(let message) = wsError {
            #expect(message == "Failed to decode protobuf")
        } else {
            #expect(Bool(false), "Expected messageDecodingFailed")
        }
        
        if case .webSocketError(let wsError) = subscriptionError,
           case .subscriptionFailed(let message) = wsError {
            #expect(message == "Invalid symbol")
        } else {
            #expect(Bool(false), "Expected subscriptionFailed")
        }
    }
    
    @Test("YFWebSocketError timeout and disconnection errors")
    func testWebSocketTimeoutErrors() {
        // Given & When & Then
        let timeoutError = YFError.webSocketError(.timeout("Connection timeout after 30s"))
        let disconnectedError = YFError.webSocketError(.unexpectedDisconnection("Server closed connection"))
        let reconnectionError = YFError.webSocketError(.reconnectionFailed("Max retries exceeded"))
        
        // Verify error types
        if case .webSocketError(let wsError) = timeoutError,
           case .timeout(let message) = wsError {
            #expect(message == "Connection timeout after 30s")
        } else {
            #expect(Bool(false), "Expected timeout error")
        }
        
        if case .webSocketError(let wsError) = disconnectedError,
           case .unexpectedDisconnection(let message) = wsError {
            #expect(message == "Server closed connection")
        } else {
            #expect(Bool(false), "Expected unexpectedDisconnection")
        }
        
        if case .webSocketError(let wsError) = reconnectionError,
           case .reconnectionFailed(let message) = wsError {
            #expect(message == "Max retries exceeded")
        } else {
            #expect(Bool(false), "Expected reconnectionFailed")
        }
    }
    
    @Test("YFWebSocketError equality and description")
    func testWebSocketErrorEquality() {
        // Given
        let error1 = YFError.webSocketError(.invalidURL("test"))
        let error2 = YFError.webSocketError(.invalidURL("test"))
        let error3 = YFError.webSocketError(.connectionFailed("test"))
        
        // When & Then
        #expect(error1 == error2)
        #expect(error1 != error3)
        
        // Test error descriptions are accessible
        let description = error1.localizedDescription
        #expect(!description.isEmpty)
    }
}