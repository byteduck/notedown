//
//  ContentView.swift
//  Notedown
//
//  Created by Aaron on 4/5/23.
//

import SwiftUI

struct NDEditorView: View {
    @Binding var document: NDDocument
    @Binding var configuration: NDMarkdownEditorConfiguration
    @State var selectedPage: NDDocument.Page?
    
    @State var presentingNewPageAlert: Bool = false
    @State var newPageName: String = ""

    var body: some View {
        NavigationSplitView {
            List($document.pages, selection: $selectedPage) { page in
                NavigationLink(value: page.wrappedValue) {
                    Text(page.wrappedValue.title)
                }
            }
            
            Button("+", action: {
                newPageName = ""
                presentingNewPageAlert = true
            })
            .buttonStyle(.borderless)
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .trailing)
        } detail: {
            if let page = selectedPage {
                NDMarkdownEditorView(page: page, configuration: configuration)
                    .id(selectedPage)
            } else {
                Text("Select a page")
            }
        }
        .sheet(isPresented: $presentingNewPageAlert) {
            VStack {
                Text("New Page")
                    .font(.headline)
                TextField(text: $newPageName, prompt: Text("Title")) {
                    Text("Title")
                }
                HStack {
                    Button("Cancel") {
                        presentingNewPageAlert = false
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Button("Create") {
                        document.pages.append(NDDocument.Page(
                            document: document,
                            contents: "# \(newPageName)",
                            fileName: "\(newPageName).md"
                        ))
                        presentingNewPageAlert = false
                    }
                }
            }
            .padding(10)
            .frame(minWidth: 200, alignment: .top)
        }
    }
}
