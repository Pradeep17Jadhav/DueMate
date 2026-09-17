import DueMateCore
import SwiftUI

struct TasksView: View {
    @Environment(AppSession.self) private var session
    @State private var query = TaskQuery()

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped(), id: \.date) { group in
                    Section(Formatters.date(group.date, style: .full)) {
                        ForEach(group.items) { record in
                            NavigationLink {
                                OccurrenceDetailView(record: record)
                            } label: {
                                ObligationRow(record: record)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { try? await session.store.deleteOccurrence(record.occurrence.id); await session.refresh() }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if record.occurrence.status != .paid {
                                    Button {
                                        session.pendingPayment = record
                                    } label: {
                                        Label("Mark Paid", systemImage: "checkmark")
                                    }
                                    .tint(.green)
                                }
                            }
                            .contextMenu {
                                if record.occurrence.status != .paid {
                                    Button("Mark Paid") { session.pendingPayment = record }
                                }
                                Button("Edit") { }
                                Button("Duplicate") {
                                    Task { try? await session.store.duplicateObligation(record.obligation.id); await session.refresh() }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .searchable(text: $query.search)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        Picker("Status", selection: $query.filter) {
                            ForEach(TaskFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        Picker("Sort", selection: $query.sort) {
                            ForEach(TaskSort.allCases) { sort in
                                Text(sort.title).tag(sort)
                            }
                        }
                    }
                }
            }
            .overlay {
                if grouped().isEmpty {
                    EmptyStateView(
                        title: "You're all caught up",
                        systemImage: "checkmark.circle",
                        message: "No tasks match these filters."
                    )
                }
            }
        }
    }

    private func grouped() -> [(date: CalendarDate, items: [OccurrenceRecord])] {
        let items = session.records(query)
        let dates = Dictionary(grouping: items, by: \.occurrence.scheduledDate)
        return dates.keys.sorted().map { ($0, dates[$0] ?? []) }
    }
}
