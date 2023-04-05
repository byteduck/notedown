//
//  ContentView.swift
//  Notedown
//
//  Created by Aaron on 4/5/23.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: NotedownDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(NotedownDocument()))
    }
}
