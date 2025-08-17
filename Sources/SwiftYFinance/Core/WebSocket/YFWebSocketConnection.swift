import Foundation

/// WebSocket 연결 관리 전용 Actor
///
/// Yahoo Finance WebSocket 서버와의 연결 생성, 관리, 해제를 담당합니다.
/// Single Responsibility Principle에 따라 연결 관련 기능만 제공합니다.
internal actor YFWebSocketConnection {
    
    // MARK: - Properties
    
    /// URLSession for WebSocket connections
    internal let urlSession: URLSession
    
    /// 현재 WebSocket task
    internal var webSocketTask: URLSessionWebSocketTask?
    
    // MARK: - Dependencies
    
    /// 상태 관리 Actor (외부 주입)
    private let stateManager: YFWebSocketInternalState
    
    // MARK: - Initialization
    
    /// WebSocket 연결 관리자 초기화
    ///
    /// - Parameters:
    ///   - urlSession: WebSocket 연결에 사용할 URLSession
    ///   - stateManager: 상태 관리를 담당하는 Actor
    internal init(urlSession: URLSession, stateManager: YFWebSocketInternalState) {
        self.urlSession = urlSession
        self.stateManager = stateManager
    }
    
    // MARK: - Connection Management
    
    /// 지정된 URL로 WebSocket 연결 시도
    ///
    /// - Parameter url: 연결할 WebSocket URL
    /// - Throws: `YFError.webSocketError` WebSocket 연결 관련 오류
    internal func connectToURL(_ url: URL) async throws {
        await changeConnectionState(to: .connecting, reason: "Connection attempt to \(url.host ?? "unknown")")
        
        #if DEBUG
        // 테스트용 잘못된 연결 모드
        if await stateManager.getTestInvalidConnectionMode() {
            await changeConnectionState(to: .failed, reason: "Test invalid connection mode enabled")
            throw YFError.webSocketError(.connectionFailed("Test invalid connection mode enabled"))
        }
        #endif
        
        do {
            // 타임아웃과 함께 연결 시도
            let currentTimeout = await stateManager.getConnectionTimeout()
            
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
            await stateManager.recordConnectionSuccess()
            
        } catch let error as YFError {
            await changeConnectionState(to: .disconnected, reason: "Connection failed: \(error)")
            await stateManager.incrementConsecutiveFailures()
            webSocketTask?.cancel()
            webSocketTask = nil
            
            // 에러 로깅
            await logError(error, context: "WebSocket connection to \(url.absoluteString)")
            throw error
        } catch {
            await changeConnectionState(to: .disconnected, reason: "Connection failed: \(error)")
            await stateManager.incrementConsecutiveFailures()
            webSocketTask?.cancel()
            webSocketTask = nil
            
            let yfError = YFError.webSocketError(.connectionFailed("Failed to connect to \(url.absoluteString): \(error.localizedDescription)"))
            // 에러 로깅
            await logError(yfError, context: "WebSocket connection to \(url.absoluteString)")
            throw yfError
        }
    }
    
    /// WebSocket 연결 해제
    ///
    /// 활성 WebSocket 연결을 정상적으로 종료합니다.
    internal func disconnect() async {
        await changeConnectionState(to: .disconnected, reason: "User requested disconnect")
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    /// WebSocket task 직접 설정 (테스트용)
    ///
    /// - Parameter task: 설정할 WebSocket task
    internal func setWebSocketTask(_ task: URLSessionWebSocketTask?) {
        webSocketTask = task
    }
    
    // MARK: - Private Methods
    
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
    
    /// 연결 상태 변경
    ///
    /// - Parameters:
    ///   - newState: 새로운 상태
    ///   - reason: 상태 변경 이유
    private func changeConnectionState(to newState: YFWebSocketConnectionState, reason: String) async {
        await stateManager.updateConnectionState(to: newState, reason: reason)
    }
    
    /// 에러 로깅
    ///
    /// - Parameters:
    ///   - error: 로깅할 에러
    ///   - context: 에러 발생 컨텍스트
    private func logError(_ error: Error, context: String) async {
        let currentState = await stateManager.getConnectionState()
        let failures = await stateManager.getConsecutiveFailures()
        await stateManager.addErrorLog(error, context: context, connectionState: currentState, consecutiveFailures: failures)
    }
}