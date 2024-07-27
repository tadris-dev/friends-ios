import SwiftUI

extension Binding {
    
    static func variable(_ value: Value) -> Self {
        VariableBinding(value: value).binding
    }
    
    private class VariableBinding {
        
        var value: Value
        
        init(value: Value) {
            self.value = value
        }
        
        var binding: Binding<Value> {
            Binding(
                get: { self.value },
                set: { self.value = $0 }
            )
        }
    }
}
