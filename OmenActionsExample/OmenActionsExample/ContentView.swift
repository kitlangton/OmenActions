//
//  ContentView.swift
//  OmenActionsExample
//
//  Created by Kit Langton on 12/19/23.
//

import OmenActions
import SwiftData
import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationStack {
      List(selection: $selectedItems) {
        ForEach(items) { item in
          Text("\(item.name)")
            .padding(.vertical, 12)
            .tag(item)
        }
        .onDelete(perform: deleteItems)

        Text("HELLO I AM A RECT")
//          .macActionMenuRect()
      }
      .toolbar {
        ToolbarItemGroup(placement: .automatic) {
          Button {
            showActionMenu = true
          } label: {
            Label("Menu", systemImage: "ellipsis.circle")
          }
          .keyboardShortcut("k")
          .popover(isPresented: $showActionMenu, arrowEdge: .bottom) {
            ActionMenuView(
              actionMenu: actionMenu,
              handleClose: {
                showActionMenu = false
              }
            )
          }

          Button(action: addItem) {
            Label("Add Item", systemImage: "plus")
          }

          // DELETE ALL
          Button(action: deleteAllItems) {
            Label("Delete All", systemImage: "trash")
          }
        }
      }
    }
    .onAppear {
      addItem()
      Task {
        addItem()
        Task {
          addItem()
        }
      }
    }
    .background {
      #if os(macOS)
        ActionMenuShortcutsView(actionMenu: actionMenu)
      #endif
    }
  }

  func deleteAllItems() {
    withAnimation {
      for item in items {
        modelContext.delete(item)
      }
    }
  }

  @Environment(\.modelContext) private var modelContext

  @State private var showActionMenu = false
  @State private var selectedItems: Set<Item> = []
  @Query private var items: [Item]

  private var actionMenu: ActionMenu {
    ActionMenu(
      sections: [
        ActionSection(name: "Items", actions: [
          Action(
            systemName: "plus",
            name: "Add Item",
            shortcut: .init(
              key: "a",
              modifiers: .command
            ),
            action: {
              addItem()
            }
          ),
          // Duplicate
          Action(
            systemName: "doc.on.doc",
            name: "Duplicate",
            shortcut: .init(
              key: "d",
              modifiers: .command
            ),
            action: {
              for item in selectedItems {
                let newItem = Item(name: item.name, timestamp: Date())
                modelContext.insert(newItem)
              }
            }
          ),
          // Delete
          Action(
            systemName: "trash",
            name: "Delete",
            shortcut: .init(
              key: .delete,
              modifiers: .command
            ),
            action: {
              deleteItems(offsets: IndexSet(selectedItems.compactMap { items.firstIndex(of: $0) }))
            }
          ),
        ]),
      ]
    )
  }

  private func addItem() {
    withAnimation {
      let newItem = Item(name: "Item \(items.count)", timestamp: Date())
      modelContext.insert(newItem)
    }
  }

  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        modelContext.delete(items[index])
      }
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: Item.self, inMemory: true)
}
