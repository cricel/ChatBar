//
//  ChatMenuView.swift
//  ChatBar
//
//  Created by cricel on 2/21/26.
//

import SwiftUI
import AppKit

enum PromptMode: String, CaseIterable, Identifiable {
    case quick = "Quick"
    case reword = "Reword"
    case reply = "Reply"
    
    var id: String { rawValue }
    
    var symbolName: String {
        switch self {
        case .quick: return "sparkles"
        case .reword: return "arrow.triangle.2.circlepath"
        case .reply: return "arrowshape.turn.up.left.fill"
        }
    }
    
    var placeholder: String {
        switch self {
        case .quick: return "Ask anything…"
        case .reword: return "Paste text to reword…"
        case .reply: return "Your main idea for the reply…"
        }
    }
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
    @Environment(\.dismiss) private var dismiss
    
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
    @State private var showSettings: Bool = false
    @State private var streamTask: Task<Void, Never>?
    @Namespace private var glassNamespace
    
    private let chatGPTService = ChatGPTService()
    
    private var selectedModel: ChatGPTModel {
        ChatGPTModel(rawValue: selectedModelRaw) ?? .gpt5Mini
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if showSettings {
                        settingsPanel
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    modePicker
                    
                    inputArea
                        .animation(.snappy(duration: 0.25), value: selectedMode)
                    
                    sendButton
                    
                    if let error = errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .labelStyle(.titleAndIcon)
                    }
                    
                    if isLoading || !response.isEmpty {
                        responsePanel
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(16)
                .animation(.snappy(duration: 0.28), value: showSettings)
                .animation(.snappy(duration: 0.28), value: isLoading && response.isEmpty)
            }
        }
        .frame(width: 400, height: 540)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            if apiKey.isEmpty {
                showSettings = true
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text("ChatBar")
                .font(.headline)
            
            Spacer(minLength: 0)
            
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 6) {
                    Button {
                        withAnimation(.snappy(duration: 0.28)) {
                            showSettings.toggle()
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .foregroundStyle(showSettings || apiKey.isEmpty ? Color.accentColor : Color.primary)
                    .help("Settings")
                    .glassEffectID("settings", in: glassNamespace)
                    
                    Button(action: collapsePanel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .help("Close")
                    .glassEffectID("close", in: glassNamespace)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Settings
    
    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("API Key")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                SecureField("sk-…", text: $apiKey)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(fieldBackground)
            }
            
            HStack {
                Text("Model")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Model", selection: $selectedModelRaw) {
                    ForEach(ChatGPTModel.allCases) { model in
                        Text(model.displayName).tag(model.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
            }
            
            Divider()
            
            Button(role: .destructive, action: quitApp) {
                Label("Quit ChatBar", systemImage: "power")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .tint(.red)
            .controlSize(.regular)
        }
        .padding(14)
        .background(panelBackground)
    }
    
    // MARK: - Mode
    
    private var modePicker: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(PromptMode.allCases) { mode in
                    modeButton(mode)
                }
            }
        }
    }
    
    @ViewBuilder
    private func modeButton(_ mode: PromptMode) -> some View {
        let isSelected = selectedMode == mode
        Button {
            withAnimation(.snappy(duration: 0.25)) {
                selectedMode = mode
            }
        } label: {
            Label(mode.rawValue, systemImage: mode.symbolName)
                .font(.subheadline.weight(.medium))
                .labelStyle(.titleAndIcon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .applyModeButtonStyle(isSelected: isSelected)
        .glassEffectID(mode.id, in: glassNamespace)
    }
    
    // MARK: - Input
    
    @ViewBuilder
    private var inputArea: some View {
        switch selectedMode {
        case .quick:
            inputField(placeholder: PromptMode.quick.placeholder, text: $quickInput, height: 96)
        case .reword:
            inputField(placeholder: PromptMode.reword.placeholder, text: $rewordInput, height: 96)
        case .reply:
            VStack(alignment: .leading, spacing: 10) {
                inputField(placeholder: "Paste the message you’re replying to…", text: $replyPastContent, height: 110)
                inputField(placeholder: PromptMode.reply.placeholder, text: $replyMainIdea, height: 72)
            }
        }
    }
    
    private func inputField(placeholder: String, text: Binding<String>, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
            
            TextEditor(text: text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .frame(height: height)
        .background(fieldBackground)
    }
    
    // MARK: - Send
    
    private var sendButton: some View {
        Button(action: isLoading ? cancelStream : sendToChatGPT) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                    Text("Stop")
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Send")
                }
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .disabled((!isLoading && !canSend) || apiKey.isEmpty)
        .opacity(((!isLoading && !canSend) || apiKey.isEmpty) ? 0.55 : 1)
    }
    
    // MARK: - Response
    
    private var responsePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Response")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if isLoading {
                    Text("Streaming…")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Button(action: copyResponse) {
                    Label(
                        copiedToClipboard ? "Copied" : "Copy",
                        systemImage: copiedToClipboard ? "checkmark" : "doc.on.doc"
                    )
                    .font(.caption.weight(.medium))
                    .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.glass)
                .controlSize(.small)
                .disabled(response.isEmpty)
                .foregroundStyle(copiedToClipboard ? Color.green : Color.primary)
            }
            
            ScrollView {
                Group {
                    if response.isEmpty && isLoading {
                        Text("…")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(response)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(minHeight: 80, maxHeight: 180)
        }
        .padding(14)
        .background(panelBackground)
    }
    
    // MARK: - Surfaces
    
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(nsColor: .textBackgroundColor).opacity(0.85))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }
    
    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.primary.opacity(0.04))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }
    
    // MARK: - Logic
    
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
        
        streamTask?.cancel()
        errorMessage = nil
        isLoading = true
        response = ""
        
        let prompt = buildPrompt()
        let key = apiKey
        let model = selectedModel.rawValue
        
        streamTask = Task {
            var receivedAnyToken = false
            
            do {
                let stream = await chatGPTService.streamMessage(prompt, apiKey: key, model: model)
                for try await token in stream {
                    try Task.checkCancellation()
                    await MainActor.run {
                        if !receivedAnyToken {
                            withAnimation(.snappy(duration: 0.28)) {
                                response = token
                            }
                        } else {
                            response += token
                        }
                        receivedAnyToken = true
                    }
                }
                await MainActor.run {
                    isLoading = false
                    if response.isEmpty {
                        errorMessage = "No response from ChatGPT"
                    } else {
                        response = response.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            } catch is CancellationError {
                await MainActor.run {
                    isLoading = false
                }
            } catch let urlError as URLError where urlError.code == .cancelled {
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    if !Task.isCancelled {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
            }
        }
    }
    
    private func cancelStream() {
        streamTask?.cancel()
        streamTask = nil
        isLoading = false
    }
    
    private func copyResponse() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(response, forType: .string)
        withAnimation(.snappy(duration: 0.2)) {
            copiedToClipboard = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.snappy(duration: 0.2)) {
                copiedToClipboard = false
            }
        }
    }
    
    private func collapsePanel() {
        // Prefer SwiftUI dismiss when supported.
        dismiss()
        
        // MenuBarExtra (.window) often ignores dismiss — hide the panel without quitting.
        for window in NSApp.windows where window.isVisible {
            // Keep the status-bar item window; close the popover/panel content.
            if window.className.contains("NSStatusBarWindow") {
                continue
            }
            window.orderOut(nil)
        }
        
        // Drop key status so the menu-bar item un-highlights.
        NSApp.deactivate()
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

private extension View {
    @ViewBuilder
    func applyModeButtonStyle(isSelected: Bool) -> some View {
        if isSelected {
            self
                .buttonStyle(.glassProminent)
                .tint(.accentColor)
        } else {
            self
                .buttonStyle(.glass)
        }
    }
}

#Preview {
    ChatMenuView()
        .frame(width: 400, height: 540)
}
