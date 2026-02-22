//
//  ChatMenuView.swift
//  MenuChat
//
//  Created by cricel on 2/21/26.
//

import SwiftUI
import AppKit

enum PromptMode: String, CaseIterable {
    case quick = "Quick"
    case reword = "Reword"
    case reply = "Reply"
}

enum ChatGPTModel: String, CaseIterable, Identifiable {
    case gpt52 = "gpt-5.2"
    case gpt5Mini = "gpt-5-mini"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .gpt52: return "GPT-5.2"
        case .gpt5Mini: return "GPT-5 Mini"
        }
    }
}

struct ChatMenuView: View {
    @State private var selectedMode: PromptMode = .quick
    @State private var quickInput: String = ""
    @State private var rewordInput: String = ""
    @State private var replyPastContent: String = ""
    @State private var replyMainIdea: String = ""
    @AppStorage("OpenAI_API_Key") private var apiKey: String = ""
    @AppStorage("ChatGPT_Model") private var selectedModelRaw: String = ChatGPTModel.gpt5Mini.rawValue
    @State private var response: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var copiedToClipboard: Bool = false
    
    private let chatGPTService = ChatGPTService()
    
    private var selectedModel: ChatGPTModel {
        ChatGPTModel(rawValue: selectedModelRaw) ?? .gpt5Mini
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // API Key
                VStack(alignment: .leading, spacing: 4) {
                    Text("OpenAI API Key")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("sk-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Model selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Model")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Model", selection: $selectedModelRaw) {
                        ForEach(ChatGPTModel.allCases) { model in
                            Text(model.displayName).tag(model.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Divider()
                
                // Mode selector
                Picker("Mode", selection: $selectedMode) {
                    ForEach(PromptMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            
            // Input area based on mode
            switch selectedMode {
            case .quick:
                quickInputView
            case .reword:
                rewordInputView
            case .reply:
                replyInputView
            }
            
            // Send button
            Button(action: sendToChatGPT) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Sending...")
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Send to ChatGPT")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || !canSend || apiKey.isEmpty)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            // Response area
            if !response.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Response")
                            .font(.headline)
                        Spacer()
                        Button(action: copyResponse) {
                            Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                                .foregroundStyle(copiedToClipboard ? .green : .accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    ScrollView {
                        Text(response)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                }
            }
            }
        }
        .padding(16)
        .frame(width: 420, height: 520)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private var quickInputView: some View {
        inputSection(label: "Ask anything", text: $quickInput, height: 80)
    }

    private var rewordInputView: some View {
        inputSection(label: "Text to reword", text: $rewordInput, height: 80)
    }

    private var replyInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            inputSection(label: "Content to reply to (paste here)", text: $replyPastContent, height: 100)
            inputSection(label: "Your main idea for the reply", text: $replyMainIdea, height: 80)
        }
    }

    private func inputSection(label: String, text: Binding<String>, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: text)
                .font(.body)
                .frame(height: height)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
        }
    }
    
    private var canSend: Bool {
        switch selectedMode {
        case .quick:
            return !quickInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .reword:
            return !rewordInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .reply:
            return !replyPastContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !replyMainIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func buildPrompt() -> String {
        switch selectedMode {
        case .quick:
            return quickInput
        case .reword:
            return "reword\n\(rewordInput)"
        case .reply:
            return """
            Here is the content I need to reply to:
            
            \(replyPastContent)
            
            My main idea for the reply:
            
            \(replyMainIdea)
            
            Please help me write a reply based on the above.
            """
        }
    }
    
    private func sendToChatGPT() {
        guard canSend else { return }
        
        errorMessage = nil
        isLoading = true
        response = ""
        
        let prompt = buildPrompt()
        
        Task {
            do {
                let result = try await chatGPTService.sendMessage(prompt, apiKey: apiKey, model: selectedModel.rawValue)
                await MainActor.run {
                    response = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func copyResponse() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(response, forType: .string)
        copiedToClipboard = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedToClipboard = false
        }
    }
}

#Preview {
    ChatMenuView()
        .frame(width: 420, height: 520)
}
