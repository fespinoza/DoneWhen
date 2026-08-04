import SwiftUI
import SwiftData

struct PreviewDataContainer<Content: View>: View {
    let content: () -> Content
    @State var container: ModelContainer?
    @State var errorMessage: String?

    var body: some View {
        VStack {
            if let container {
                content()
                    .modelContainer(container)
            } else {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(Color.red)
                } else {
                    Text("Preparing...")
                }
            }
        }
        .task {
            do {
                container = try ContainerFactory.testContainer()
                print("---container set")
            } catch {
                print("---error \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
}
