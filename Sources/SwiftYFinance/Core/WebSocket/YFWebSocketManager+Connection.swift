import Foundation

// MARK: - Connection Management

extension YFWebSocketManager {
    
    /// 지정된 URL로 WebSocket 연결 시도
    ///
    /// - Parameter url: 연결할 WebSocket URL
    /// - Throws: `YFError.webSocketError` WebSocket 연결 관련 오류
    internal func connectToURL(_ url: URL) async throws {
        await changeConnectionState(to: .connecting, reason: "Connection attempt to \(url.host ?? "unknown")")
        
        #if DEBUG
        // 테스트용 잘못된 연결 모드
        if await testInvalidConnectionMode {
            await changeConnectionState(to: .failed, reason: "Test invalid connection mode enabled")
            throw YFError.webSocketError(.connectionFailed("Test invalid connection mode enabled"))
        }
        #endif
        
        do {
            // 타임아웃과 함께 연결 시도
            let currentTimeout = await connectionTimeout
            
            // 연결과 타임아웃 중 먼저 완료되는 것을 기다림
            // Race condition: 타임아웃과 연결 시도를 동시에 실행
            let result = await withTaskGroup(of: Result<Void, Error>.self) { group in
                // 타임아웃 태스크 추가
                group.addTask {
                    do {
                        try await Task.sleep(nanoseconds: UInt64(currentTimeout * 1_000_000_000))
                        return .failure(YFError.webSocketError(.connectionTimeout("Connection timeout after \(currentTimeout) seconds")))
                    } catch {
                        return .failure(error)  // Task cancelled
                    }
                }
                
                // 연결 태스크 추가
                group.addTask {
                    do {
                        try await self.performConnection(to: url)
                        return .success(())
                    } catch {
                        return .failure(error)
                    }
                }
                
                // 첫 번째 완료된 태스크의 결과를 가져옴
                guard let firstResult = await group.next() else {
                    return Result<Void, Error>.failure(YFError.webSocketError(.connectionFailed("No task completed")))
                }
                
                // 나머지 태스크 취소
                group.cancelAll()
                
                // WebSocket task도 명시적으로 취소 (타임아웃의 경우)
                if case .failure(let error) = firstResult {
                    if case YFError.webSocketError(.connectionTimeout) = error {
                        self.webSocketTask?.cancel()
                        self.webSocketTask = nil
                    }
                }
                
                return firstResult
            }
            
            // 결과 처리
            switch result {
            case .success:
                // 연결 성공
                break
            case .failure(let error):
                throw error
            }
            
            await changeConnectionState(to: .connected, reason: "WebSocket connection established")
            
            // 연결 성공 기록
            await recordConnectionSuccess()
            
            // 메시지 스트림이 활성화되어 있다면 메시지 수신 시작
            if messageContinuation != nil {
                Task {
                    await startMessageListening()
                }
            }
        } catch let error as YFError {
            await changeConnectionState(to: .disconnected, reason: "Connection failed: \(error)")
            await internalState.incrementConsecutiveFailures()
            webSocketTask?.cancel()
            webSocketTask = nil
            
            // 에러 로깅
            await logError(error, context: "WebSocket connection to \(url.absoluteString)")
            throw error
        } catch {
            await changeConnectionState(to: .disconnected, reason: "Connection failed: \(error)")
            await internalState.incrementConsecutiveFailures()
            webSocketTask?.cancel()
            webSocketTask = nil
            
            let yfError = YFError.webSocketError(.connectionFailed("Failed to connect to \(url.absoluteString): \(error.localizedDescription)"))
            // 에러 로깅
            await logError(yfError, context: "WebSocket connection to \(url.absoluteString)")
            throw yfError
        }
    }
    
    /// WebSocket 연결 수행 (Actor-safe)
    ///
    /// - Parameter url: 연결할 URL
    /// - Throws: 연결 관련 오류
    private func performConnection(to url: URL) async throws {
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        if let task = webSocketTask {
            let testMessage = URLSessionWebSocketTask.Message.string("")
            try await task.send(testMessage)
        }
    }
}