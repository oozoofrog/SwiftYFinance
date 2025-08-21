import Foundation

/// JSON 출력을 위한 헬퍼 함수
///
/// 원본 JSON 데이터를 보기 좋게 포맷하여 출력합니다.
///
/// - Parameter data: 원본 JSON 데이터
/// - Returns: 포맷된 JSON 문자열
func formatJSONOutput(_ data: Data) -> String {
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? "Invalid JSON"
    } catch {
        // JSON 파싱이 실패하면 원본 문자열 반환
        return String(data: data, encoding: .utf8) ?? "Invalid data"
    }
}

/// JSON 형식으로 에러를 출력합니다
///
/// - Parameters:
///   - message: 에러 메시지
///   - error: 발생한 에러
func printJSONError(_ message: String, error: Error) {
    let errorDict: [String: Any] = [
        "error": true,
        "message": message,
        "details": error.localizedDescription,
        "type": String(describing: type(of: error))
    ]
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: errorDict, options: [.prettyPrinted])
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        } else {
            print("{\"error\": true, \"message\": \"\(message)\", \"details\": \"\(error.localizedDescription)\"}")
        }
    } catch {
        print("{\"error\": true, \"message\": \"\(message)\", \"details\": \"\(error.localizedDescription)\"}")
    }
}