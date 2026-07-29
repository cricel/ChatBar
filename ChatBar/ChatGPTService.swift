//
//  ChatGPTService.swift
//  ChatBar
//
//  Created by cricel on 2/21/26.
//

import Foundation

actor ChatGPTService {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    /// System prompt that gives the AI a consistent personality and style.
    private let systemPrompt = """
    You are a university professor. Keep your answers concise and formal. Write in a natural, human way—use plain language and avoid flowery or overly elaborate wording. Get to the point without unnecessary flourish.

    Output only the requested content. Do not add any preamble, labels, or meta-commentary (e.g. no "Here's my response:", "Reply:", "Reworded version:", or similar). Reply with the content itself only.

    Provide exactly one version your single best answer. Do not offer multiple options or alternatives for the user to choose from.
    """
    
    /// Streams assistant tokens as they arrive from the OpenAI Chat Completions API.
    func streamMessage(
        _ content: String,
        apiKey: String,
        model: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await self.performStream(
                        content: content,
                        apiKey: apiKey,
                        model: model,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    private func performStream(
        content: String,
        apiKey: String,
        model: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard !apiKey.isEmpty else {
            throw ChatGPTError.missingAPIKey
        }
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": content]
            ],
            "max_completion_tokens": 2048,
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (bytes, urlResponse) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw ChatGPTError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            var errorData = Data()
            for try await byte in bytes {
                errorData.append(byte)
            }
            if let errorJson = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ChatGPTError.apiError(message)
            }
            throw ChatGPTError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        for try await line in bytes.lines {
            try Task.checkCancellation()
            
            guard line.hasPrefix("data: ") else { continue }
            let payload = String(line.dropFirst(6))
            
            if payload == "[DONE]" {
                break
            }
            
            guard let data = payload.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let delta = first["delta"] as? [String: Any],
                  let token = delta["content"] as? String,
                  !token.isEmpty else {
                continue
            }
            
            continuation.yield(token)
        }
    }
}

enum ChatGPTError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Please add your OpenAI API key in Settings"
        case .invalidResponse:
            return "Invalid response from ChatGPT"
        case .apiError(let message):
            return message
        }
    }
}
