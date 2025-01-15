import SwiftUI

struct FileBrowserView: View {
    let directories = ["Home", "Documents", "Downloads", "Music", "Pictures"]
    @State var navigationHistory: [String]

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    ForEach(navigationHistory, id: \.self) { directory in
                        Text(directory)
                            .padding(5)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                    }
                }
                .padding()

                List(directories, id: \.self) { directory in
                    NavigationLink(
                        destination: FileBrowserView(navigationHistory: self.navigationHistory + [directory]),
                        label: {
                            Text(directory)
                        })
                }
            }
            .navigationTitle("File Browser")
        }
    }

    var backButton: some View {
        Button(action: {
            if navigationHistory.count > 1 {
                navigationHistory.removeLast()
            }
        }) {
            Text("Back")
        }
    }
}

struct FileBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        FileBrowserView(navigationHistory: ["Root"])
    }
}
