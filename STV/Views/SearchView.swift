import SwiftUI

struct SearchView: View {
    var pushed = false
    var initialQuery: String? = nil
    var initialSource: DramaSource? = nil
    var startEditingHistory = false
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var submitted = ""
    @State private var source: DramaSource?
    @StateObject private var pager = Pager()
    @State private var editingHistory = false
    @Environment(\.layoutMetrics) private var layout
    @ObservedObject private var gate = SourceGate.shared

    @MainActor
    init(pushed: Bool = false, initialQuery: String? = nil, initialSource: DramaSource? = nil, startEditingHistory: Bool = false) {
        self.pushed = pushed
        self.initialQuery = initialQuery
        self.initialSource = initialSource
        self.startEditingHistory = startEditingHistory
        let resolved: DramaSource? = {
            if let initialSource, SourceGate.shared.searchSources.contains(initialSource) { return initialSource }
            return SourceGate.shared.searchSources.first
        }()
        _source = State(initialValue: resolved)
    }

    private var searchPlaceholder: String {
        if let source { return "搜索\(source.label)" }
        return "请先导入视频插件"
    }

    var body: some View {
        let sources = gate.searchSources
        ScrollView {
            if sources.isEmpty {
                VStack(spacing: 18) {
                    DSEmptyState("暂无可搜索的片源", systemImage: "puzzlepiece.extension", message: "请先在「我的 → 插件」导入视频/短剧插件或采集站。")
                        .padding(.top, 48)
                    NavigationLink(value: Route.plugins) { PillButtonLabel(title: "前往插件管理") }.buttonStyle(PressScale())
                }
            } else if submitted.isEmpty {
                landing
            } else {
                results
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .liquidTopBar {
            VStack(spacing: 6) {
                SearchField(text: $query, placeholder: searchPlaceholder, floating: true, onSubmit: submit, onCancel: pushed ? { dismiss() } : (submitted.isEmpty ? nil : { query = ""; submitted = "" }))
                    .padding(.horizontal, 16)
                if sources.count > 1, let active = source ?? sources.first {
                    TextTabStrip(items: sources, selection: Binding(get: { active }, set: { source = $0 }), label: { $0.label }, floating: true)
                }
            }
            .padding(.top, 4).padding(.bottom, 8)
        }
        .background(STVTheme.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if startEditingHistory { editingHistory = true }
            if let q = initialQuery, submitted.isEmpty, !q.isEmpty { query = q; submit() }
        }
        .compatOnChange(of: query) { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !submitted.isEmpty && trimmed != submitted { submitted = "" }
        }
        .compatOnChange(of: source) {
            if !submitted.isEmpty { run() }
            else if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { submit() }
        }
        .compatOnChange(of: gate.searchSources) {
            if let s = source, !gate.searchSources.contains(s) { source = gate.searchSources.first }
            else if source == nil { source = gate.searchSources.first }
        }
    }

    // MARK: landing

    @ViewBuilder private var landing: some View {
        VStack(alignment: .leading, spacing: 20) {
            SearchHistorySection(editing: $editingHistory, pick: pick)
        }.padding(.vertical, 8)
    }

    // MARK: results

    @ViewBuilder private var results: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let e = pager.error, pager.items.isEmpty { ErrorStateView(error: e) { run() } }
            else if !pager.isLoading && pager.items.isEmpty {
                DSEmptyState("无搜索结果", systemImage: "magnifyingglass", message: "没有找到与“\(submitted)”相关的内容")
            } else {
                NumberedGrid(items: pager.items, numbered: false, hasMore: pager.hasMore, loading: pager.isLoading) { pager.loadMore() }
            }
        }.padding(.vertical, 8)
    }

    private func pick(_ t: String) { query = t; submit() }
    private func submit() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines); guard !q.isEmpty else { return }
        LibraryStore.shared.addSearch(q); submitted = q; run()
    }
    private func run() {
        let q = submitted; guard !q.isEmpty, let active = source ?? gate.searchSources.first else { return }
        if let p = Sites.provider(active) { pager.reset { prev, _ in try await p.search(q, page: max(1, prev.nextOffset ?? 1)) } }
    }
}

/// Own view: the library also publishes playback progress, which is no business of the search page.
private struct SearchHistorySection: View {
    @Binding var editing: Bool
    let pick: (String) -> Void
    @ObservedObject private var library = LibraryStore.shared
    var body: some View {
        if !library.searchHistory.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "历史搜索") {
                    HStack(spacing: 18) {
                        if editing {
                            Button("全部删除") { library.clearSearch(); editing = false }.foregroundStyle(DSTone.danger)
                            Button("完成") { withAnimation(DS.select) { editing = false } }.foregroundStyle(STVTheme.accent)
                        } else {
                            Button { withAnimation(DS.select) { editing = true } } label: {
                                Image(systemName: "trash").foregroundStyle(STVTheme.secondary).contentShape(Rectangle().inset(by: -12))
                            }
                            .accessibilityLabel("编辑历史搜索")
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .buttonStyle(PressScale())
                }
                ChipFlow(items: library.searchHistory, onRemove: editing ? { t in withAnimation(DS.select) { library.removeSearch(t) } } : nil) { t in
                    if editing { withAnimation(DS.select) { library.removeSearch(t) } } else { pick(t) }
                }
            }
        }
    }
}

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 { state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state }
}
