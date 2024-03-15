//
//  TagField.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 3/11/24.
//

import SwiftUI

struct TagField: View {
    @Binding var tags: [Tag]
    var body: some View {
        HStack {
            ForEach($tags) { $tag in
                TaggingView(tag: $tag, allTags: $tags)
                    .onChange(of: tag.value) { oldValue, newValue in if newValue.last == " " {
                        //removecomma
                        tag.value.removeLast()
                        // inster new tag item
                        if !tag.value.isEmpty {
                            //safe check
                            tags.append(.init(value: ""))
                        }
                    }
                    }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(.bar, in: .rect(cornerRadius: 12))
        .onAppear(perform: {
            //initialize tag view
            if tags.isEmpty  || (tags.first?.value.isEmpty ?? true) {
                tags.insert(.init(value: "#rlystate"), at: 0)
                tags.append(.init(value: "", isInitial: true))
            }
        })
    }
}


// Tag View
fileprivate struct TaggingView: View {
    @Binding var tag: Tag
    @Binding var allTags: [Tag]
    @FocusState private var isFocused: Bool
    //View Properties
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        BackSpaceListenerTextField(hint: "Tag", text: $tag.value, onBackPressed: {
                                    if allTags.count > 1 {
            if tag.value.isEmpty {
                allTags.removeAll(where: { $0.id == tag.id })
            }
        }
        })
            .focused($isFocused)
            .padding(.horizontal, isFocused || tag.value.isEmpty ? 0: 10)
            .padding(.vertical, 10)
            .background((colorScheme == .dark ? Color.black : Color.white).opacity(isFocused || tag.value.isEmpty ? 0 : 1), in: .rect(cornerRadius: 5))
            .disabled(tag.isInitial)
        
            .onChange(of: allTags, initial: true, { oldValue, newValue in
                if newValue.last?.id == tag.id && !(newValue.last?.isInitial ?? false) && !isFocused {
                    isFocused = true
                }
            })
            .overlay {
                if tag.isInitial {
                    Rectangle()
                        .fill(.clear)
                        .contentShape(.rect)
                        .onTapGesture {
                            tag.isInitial = false
                            isFocused = true
                        }
                }
            }
    }
}

fileprivate struct BackSpaceListenerTextField: UIViewRepresentable {
    var hint: String = "Tag"
    @Binding var text: String
    var onBackPressed: () -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> CustomTextField {
        let textField = CustomTextField()
        textField.delegate = context.coordinator
        textField.onBackPressed = onBackPressed
        //optionals
        textField.placeholder = hint
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        textField.backgroundColor = .clear
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChange(textField:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: CustomTextField, context: Context) {
        uiView.text = text
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        init(text: Binding<String>) {
            self._text = text
        }

        @objc func textChange(textField: UITextField) {
            let newText = textField.text ?? ""
                 text = newText.starts(with: "#") ? newText.lowercased() : "#\(newText.lowercased())"
             }
        
        //close pressing return button
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
        }
    }
}

fileprivate class CustomTextField: UITextField {
    open var onBackPressed: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func deleteBackward() {
        onBackPressed?()
        super.deleteBackward()
    }
}
#Preview {
    ContentView()
}
