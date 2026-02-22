//
//  ChatGPTService.swift
//  MenuChat
//
//  Created by cricel on 2/21/26.
//

import Foundation

actor ChatGPTService {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    func sendMessage(_ content: String, apiKey: String, model: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw ChatGPTError.missingAPIKey
        }
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": content]
            ],
            "max_completion_tokens": 2048
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw ChatGPTError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ChatGPTError.apiError(message)
            }
            throw ChatGPTError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ChatGPTError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
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
