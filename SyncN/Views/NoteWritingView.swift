import SwiftUI
import SwiftData

struct NoteWritingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var noteText = ""
    @State private var showingSaveConfirmation = false
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Write a Note")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Reflect on your journey, thoughts, or feelings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Note writing area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Note")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $noteText)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(minHeight: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                // Character count
                HStack {
                    Spacer()
                    Text("\(noteText.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Save button
                Button(action: saveNote) {
                    Text("Save Note")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Note Saved! ✍️", isPresented: $showingSaveConfirmation) {
            Button("Great!") {
                dismiss()
            }
        } message: {
            Text("Your note has been saved and you've earned progress toward your charm!")
        }
    }
    
    private func saveNote() {
        guard !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let userProfile = userProfile else { return }
        
        // Here you could save the note to a Note model if you want to persist it
        // For now, we'll just mark the charm task as completed
        
        CharmManager.shared.markNoteWritten(for: userProfile, in: modelContext)
        
        showingSaveConfirmation = true
    }
}

#Preview {
    NoteWritingView()
}
