import SwiftUI

struct LabeledTextField: View {
    
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack {
            Text(label)
            TextField(label, text: $value).multilineTextAlignment(.trailing)
        }
    }
    
    init(_ label: String, value: Binding<String>) {
        self.label = label
        self._value = value
    }
}
