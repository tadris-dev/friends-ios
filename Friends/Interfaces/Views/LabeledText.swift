import SwiftUI

struct LabeledText: View {
    
    let label: String
    let value: String
    
    var body: some View {
        LabeledContent(label, value: value)
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = value
                }) {
                    Text("Copy")
                    Image(systemName: "doc.on.doc")
                }
            }
    }
    
    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }
}
