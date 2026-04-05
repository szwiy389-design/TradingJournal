import SwiftUI
import SwiftData

struct AtlasView: View {
    @Query(sort: \Trade.date, order: .reverse) private var trades: [Trade]
    @Query(sort: \DailyJournal.date, order: .reverse) private var journals: [DailyJournal]

    @AppStorage("atlasApiKey") private var apiKey: String = ""
    @AppStorage("dailyLossLimit") private var dailyLossLimit: Double = 0.0
    @State private var messages: [AtlasMessage] = []
    @State private var input: String = ""
    @State private var isLoading: Bool = false
    @State private var showApiKeySheet: Bool = false
    @State private var errorMessage: String? = nil

    private let suggestions = [
        "Analyse mes patterns psychologiques",
        "Quelles émotions me coûtent le plus ?",
        "Résume mes 20 dernières trades",
        "Comment améliorer mon win rate ?"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }

                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }

                inputBar
            }
            .navigationTitle("Atlas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showApiKeySheet = true
                    } label: {
                        Image(systemName: apiKey.isEmpty ? "key.slash" : "key.fill")
                            .foregroundStyle(apiKey.isEmpty ? .red : .green)
                    }
                }
                if !messages.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear") { messages = [] }
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showApiKeySheet) {
                ApiKeySheet(apiKey: $apiKey)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 52))
                        .foregroundStyle(.green)
                    Text("Atlas")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Your AI trading psychology coach.\nAsk me anything about your performance.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggestions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal)

                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            input = suggestion
                            Task { await sendMessage() }
                        } label: {
                            Text(suggestion)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 20)
            }
        }
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Atlas is thinking…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .id("loading")
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: isLoading) { _, loading in
                if loading { withAnimation { proxy.scrollTo("loading", anchor: .bottom) } }
            }
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask Atlas…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? .green : .secondary)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .top)
    }

    private var canSend: Bool { !input.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading }

    // MARK: - Send

    @MainActor
    private func sendMessage() async {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        errorMessage = nil
        input = ""
        messages.append(AtlasMessage(role: .user, text: text))
        isLoading = true

        let prompt = AtlasService.buildPrompt(trades: Array(trades), journals: Array(journals), userMessage: text, dailyLossLimit: dailyLossLimit)

        do {
            let reply = try await AtlasService.ask(prompt: prompt, apiKey: apiKey)
            messages.append(AtlasMessage(role: .atlas, text: reply))
        } catch {
            errorMessage = error.localizedDescription
            messages.removeLast() // remove user message if failed
        }
        isLoading = false
    }
}

// MARK: - Message model

struct AtlasMessage: Identifiable {
    let id = UUID()
    enum Role { case user, atlas }
    let role: Role
    let text: String
}

// MARK: - Message bubble

struct MessageBubble: View {
    let message: AtlasMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .atlas {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .padding(.top, 2)
            }
            Text(message.text)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.role == .user
                    ? Color.green.opacity(0.15)
                    : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - API Key Sheet

struct ApiKeySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var apiKey: String
    @State private var draft: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("sk-ant-…", text: $draft)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Anthropic API Key")
                } footer: {
                    Text("Your key is stored locally in UserDefaults and never sent anywhere except Anthropic's API.")
                }
            }
            .navigationTitle("Atlas API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        apiKey = draft
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { draft = apiKey }
        }
    }
}

#Preview {
    AtlasView()
        .modelContainer(for: [Trade.self, DailyJournal.self], inMemory: true)
}
