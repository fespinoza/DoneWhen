import SwiftUI

extension OccurrenceListView {
    struct EmptyState: View {
        @Binding var showingAddSheet: Bool

        var body: some View {
            ContentUnavailableView {
                Label("No Occurrences", systemImage: "calendar.badge.plus")
            } description: {
                Text("Add your first occurrence to start building an activity history.")
            } actions: {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Occurrence", systemImage: "plus")
                        .frame(minWidth: 180, minHeight: 30, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: 360)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
}

#Preview {
    @Previewable @State var showingAddSheet: Bool = false

    NavigationStack {
        ScrollView {
            OccurrenceListView.EmptyState(showingAddSheet: $showingAddSheet)
        }
        .navigationTitle(Text("Preview"))
    }
}

