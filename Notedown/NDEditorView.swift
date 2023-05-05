//
//  ContentView.swift
//  Notedown
//
//  Created by Aaron on 4/5/23.
//

import SwiftUI

struct NDEditorView: View {
    /// The document that this view represents
    @ObservedObject var document: NDDocument
    /// The editor configuration for this view
    @Binding var configuration: NDMarkdownEditorConfiguration
    /// The filename of the selected page of the document
    @Binding var selectedPage: String?
    /// Whether or not we're presenting the new page sheet
    @State var presentingNewPageAlert: Bool = false
    /// The name of the new page to be created in the new page sheet
    @State var newPageName: String = ""
    /// Whether we're delting and the page we're deleting
    @State var deletePage: (Bool, Binding<NDDocument.Page>?) = (false, nil)
    
    @Environment(\.undoManager) var undoManager

    var body: some View {
        
        NavigationSplitView {
            // List of pages
            List($document.notebook.pages, selection: $selectedPage) { page in
                NavigationLink(value: page.wrappedValue) {
                    VStack(alignment: .leading) {
                        Text(page.wrappedValue.title)
                        Text(page.wrappedValue.fileName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }.contextMenu {
                    Button("Delete") {
                        deletePage = (true, page)
                    }
                }
            }
            
            // New page button
            Button("+", action: {
                newPageName = ""
                presentingNewPageAlert = true
            })
            .buttonStyle(.borderless)
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .font(.title)
        } detail: {
            if
                let pageName = Binding<String>($selectedPage)?.wrappedValue,
                let page = $document.notebook.pages.first(where: { $0.wrappedValue.fileName == pageName })
            {
                NDMarkdownEditorView(page: page, document: document, configuration: configuration)
                    .id(selectedPage)
                    .edgesIgnoringSafeArea(.top)
            } else {
                Text("Select a page")
            }
        }
        
        // New page creation sheet
        .sheet(isPresented: $presentingNewPageAlert) {
            NewPageView(document: document, pageName: $newPageName, selectedPage: $selectedPage, undoManager: undoManager)
        }
        
        // Page deletion confirmation alert
        .alert("Delete page?", isPresented: $deletePage.0, actions: {
            Button("Delete") {
                deletePage(document.notebook.pages.firstIndex(where: { $0 == deletePage.1?.wrappedValue }))
                deletePage = (false, nil)
            }
            Button("Cancel") {
                deletePage = (false, nil)
            }
        }, message: {
            Text("Are you sure you'd like to delete the page \"\(deletePage.1?.wrappedValue.fileName ?? "nil")\"?")
        })
    }
    
    func deletePage(_ pageIndex: Int?) {
        guard let pageIndex = pageIndex else {
            return
        }
        var page = document.notebook.pages[pageIndex]
        document.notebook.pages.remove(at: pageIndex)
        let wasSelected = selectedPage == page.fileName
        if wasSelected {
            selectedPage = nil
        }
        undoManager?.registerUndo(withTarget: document) { document in
            page.dirty = true
            document.notebook.pages.insert(page, at: pageIndex)
            if wasSelected {
                selectedPage = page.fileName
            }
        }
    }
}

extension NDEditorView {
    struct NewPageView: View {
        @ObservedObject var document: NDDocument
        @Binding var pageName: String
        @Binding var selectedPage: String?
        var undoManager: UndoManager?
        
        @Environment(\.dismiss) var dismiss
        
        var fileName: String { "\(pageName).md" }
        
        var body: some View {
            VStack {
                Text("New Page")
                    .font(.headline)
                TextField(text: $pageName, prompt: Text("Title")) {
                    Text("Title")
                }
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .keyboardShortcut(.cancelAction)
                    
                    Button("Create") {
                        createPage()
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(10)
            .frame(minWidth: 200, alignment: .top)
        }
        
        func createPage() {
            document.notebook.pages.append(NDDocument.Page(
                contents: "# \(pageName)",
                fileName: fileName
            ))
            selectedPage = fileName
            undoManager?.registerUndo(withTarget: document) { document in
                document.notebook.pages.removeAll(where: { $0.fileName == fileName })
            }
        }
    }
}
