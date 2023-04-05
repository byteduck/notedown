//
//  NotedownApp.swift
//  Notedown
//
//  Created by Aaron on 4/5/23.
//

import SwiftUI

@main
struct NotedownApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: NotedownDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
