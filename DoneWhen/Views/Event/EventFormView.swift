import SwiftUI
import SwiftData

struct EditEventFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onCreated: (Event) -> Void = { _ in }

    let event: Event

    @State private var name: String = ""
    @State private var hasRepeat: Bool = false
    @State private var repeatPeriod: RepeatPeriod = .week
    @State private var repeatInterval: Int = 1

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $name)
            }

            Section("Repeat") {
                Toggle("Repeat", isOn: $hasRepeat)

                if hasRepeat {
                    HStack {
                        Stepper(value: $repeatInterval, in: 1...365) {
                            Text(repeatInterval.formatted())
                        }

                        Picker("Period", selection: $repeatPeriod) {
                            ForEach(RepeatPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                    }
                }
            }

            #if os(macOS)
            Button("Save", action: save)
            #endif
        }
        .task {
            name = event.name

            if let eventRepeatPeriod = event.repeatPeriod, let eventRepeatInterval = event.repeatInterval {
                hasRepeat = true
                repeatPeriod = eventRepeatPeriod
                repeatInterval = eventRepeatInterval
            } else {
                hasRepeat = false
            }
        }
        .navigationTitle("New Action")
        #if os(macOS)
        .padding()
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
#endif
        }
    }

    func save() {
        event.name = name
        event.repeatPeriod = hasRepeat ? repeatPeriod : nil
        event.repeatInterval = hasRepeat ? repeatInterval : nil
        do {
            try modelContext.save()

            dismiss()
        } catch {
            print(error)
        }
    }
}

#Preview {
    PreviewDataContainer {
        EditEventFormView(
            event: Event(
                name: "Hello World",
                creationDate: Date(),
                repeatInterval: 3,
                repeatPeriod: .week
            )
        )
        .frame(width: 400, height: 300)
    }
}
