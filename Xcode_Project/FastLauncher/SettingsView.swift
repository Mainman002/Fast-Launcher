import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: LauncherModel
    @State private var newPath: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Preferences").font(.headline)
                
                // --- UI Scaling ---
                VStack(alignment: .leading) {
                    Text("Grid Item Size: \(Int(model.gridSize))px")
                    Slider(value: $model.gridSize, in: 80...200, step: 10)
                    
                    Text("Header Icon Size: \(Int(model.headerSize))px")
                    Slider(value: $model.headerSize, in: 30...80, step: 5)
                }
                
                Divider()
                
                // --- Path Management ---
                VStack(alignment: .leading) {
                    Text("Search Directories").font(.subheadline).bold()
                    
                    ForEach(model.directoryList, id: \.self) { path in
                        HStack {
                            Text(path).font(.system(.caption, design: .monospaced))
                            Spacer()
                            Button(action: { model.removePath(path) }) {
                                Image(systemName: "trash")
                            }.buttonStyle(.plain)
                        }
                        .padding(4)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(4)
                    }
                    
                    HStack {
                        TextField("Add path (e.g. /Users/me/Games)", text: $newPath)
                            .textFieldStyle(.roundedBorder)
                        Button("Add") {
                            model.addPath(newPath)
                            newPath = ""
                        }
                    }
                }
            }
            .padding()
        }
        .frame(width: 350, height: 450)
    }
}
