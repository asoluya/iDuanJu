import SwiftUI

/// 02 · TVBox 点播展示页 + 03 · TVBox 直播展示页
struct TVBoxHubView: View {
    @ObservedObject private var store = TVBoxStore.shared
    @ObservedObject private var gate = SourceGate.shared

    @State private var mode = 0 // 0 = 点播, 1 = 直播
    @State private var selectedSiteKey: String?
    @State private var selectedLiveId: String?
    @State private var showPicker = false

    var body: some View {
        let activeRepo = store.activeRepo
        let sites = activeRepo.map { store.visibleSites($0, adult: gate.unlocked) } ?? []
        let lives = activeRepo.map { store.visibleLives($0) } ?? []
        let siteUid = selectedSiteKey ?? activeRepo.flatMap { store.state.lastSite[$0.id] }
        let liveUid = selectedLiveId ?? activeRepo.flatMap { store.state.lastLive[$0.id] }
        let currentSite = sites.first { $0.uid == siteUid } ?? sites.first
        let currentLive = lives.first { $0.uid == liveUid } ?? lives.first

        ZStack(alignment: .top) {
            STVTheme.bg.ignoresSafeArea()
            LinearGradient(
                colors: [(mode == 0 ? STVTheme.accent : STVTheme.accentWarm).opacity(0.11), .clear],
                startPoint: .top, endPoint: .center
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部：点播 / 直播 分段 + 右侧站点/直播源切换胶囊 + 配置齿轮
                HStack(spacing: 16) {
                    segmentTab("点播", on: mode == 0) { mode = 0 }
                    segmentTab("直播", on: mode == 1) { mode = 1 }
                    Spacer()
                    if activeRepo != nil {
                        Button { showPicker = true } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(mode == 0 ? Color(red: 0.37, green: 0.82, blue: 0.54) : Color(red: 1.0, green: 0.42, blue: 0.42))
                                    .frame(width: 7, height: 7)
                                Text(mode == 0 ? (currentSite?.site.name ?? "选择站点") : (currentLive?.live.name ?? "选择直播源"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(STVTheme.text)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(STVTheme.secondary)
                            }
                            .padding(.horizontal, 10).frame(height: 32)
                            .frame(maxWidth: 156)
                            .background(STVTheme.glass, in: Capsule())
                            .overlay { Capsule().strokeBorder(STVTheme.glassBorder) }
                        }.buttonStyle(.plain)
                    }
                    Button { Router.push(.tvboxConfig) } label: {
                        Image(systemName: "gearshape")
                            .font(.subheadline)
                            .foregroundStyle(STVTheme.text)
                            .frame(width: 32, height: 32)
                            .background(STVTheme.glass, in: Circle())
                            .overlay { Circle().strokeBorder(STVTheme.glassBorder) }
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)

                if let activeRepo {
                    if mode == 0 {
                        if let currentSite {
                            TVBoxVodCatalogPane(site: currentSite, allSites: sites).id(currentSite.uid)
                        } else {
                            emptySection("当前配置仓没有可用的点播站点", cta: "去配置片源")
                        }
                    } else {
                        if let currentLive {
                            TVBoxLiveCatalogPane(live: currentLive).id(currentLive.uid)
                        } else {
                            emptySection("当前配置仓没有可用的直播列表", cta: "去配置直播源")
                        }
                    }
                } else {
                    emptyRoot
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .compatOnChange(of: activeRepo?.id) {
            selectedSiteKey = nil; selectedLiveId = nil
            if currentSite == nil && !lives.isEmpty { mode = 1 }
        }
        .sheet(isPresented: $showPicker) {
            if let activeRepo {
                NavigationStack {
                    List {
                        if mode == 0 {
                            ForEach(sites) { s in
                                Button {
                                    selectedSiteKey = s.uid; showPicker = false
                                    store.setLastSite(activeRepo.id, s.uid)
                                } label: {
                                    HStack {
                                        Circle().fill(s.uid == currentSite?.uid ? STVTheme.accent : Color(red: 0.37, green: 0.82, blue: 0.54)).frame(width: 7, height: 7)
                                        Text(s.site.name).foregroundStyle(s.uid == currentSite?.uid ? STVTheme.accent : STVTheme.text)
                                        Spacer()
                                        Text(s.site.kind.badge).font(.caption).foregroundStyle(STVTheme.secondary)
                                    }
                                }
                            }
                        } else {
                            ForEach(lives) { l in
                                Button {
                                    selectedLiveId = l.uid; showPicker = false
                                    store.setLastLive(activeRepo.id, l.uid)
                                } label: {
                                    HStack {
                                        Circle().fill(l.uid == currentLive?.uid ? STVTheme.accent : Color(red: 1.0, green: 0.42, blue: 0.42)).frame(width: 7, height: 7)
                                        Text(l.live.name).foregroundStyle(l.uid == currentLive?.uid ? STVTheme.accent : STVTheme.text)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle(mode == 0 ? "切换点播站点" : "切换直播源")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("切换配置仓") { showPicker = false; Router.push(.tvboxConfig) }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func segmentTab(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: on ? 21 : 18, weight: on ? .heavy : .semibold))
                    .foregroundStyle(on ? STVTheme.text : STVTheme.secondary)
                Capsule()
                    .fill(on ? STVTheme.accent : .clear)
                    .frame(width: 22, height: 3)
            }
        }.buttonStyle(.plain)
    }

    private var emptyRoot: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("TVBox 点播与直播").font(.title3.weight(.heavy)).foregroundStyle(STVTheme.text)
            Text("导入你的 HTTP(S) TVBox 配置或 M3U/TXT 直播源，支持多配置仓一键切换、多线路直链解析与横屏秒切台。")
                .font(.subheadline).foregroundStyle(STVTheme.secondary).multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button { Router.push(.tvboxConfig) } label: {
                Text("配置 TVBox 片源")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(STVTheme.bg)
                    .padding(.horizontal, 24).frame(height: 44)
                    .background(STVTheme.text, in: Capsule())
            }.buttonStyle(.plain).padding(.top, 8)
            Spacer()
        }
    }

    private func emptySection(_ msg: String, cta: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Text(msg).font(.subheadline).foregroundStyle(STVTheme.secondary)
            Button { Router.push(.tvboxConfig) } label: {
                Text(cta)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(STVTheme.bg)
                    .padding(.horizontal, 20).frame(height: 36)
                    .background(STVTheme.text, in: Capsule())
            }.buttonStyle(.plain)
            Spacer()
        }
    }
}

private struct TVBoxVodCatalogPane: View {
    let site: TVBoxSiteRef
    let allSites: [TVBoxSiteRef]
    @ObservedObject private var library = LibraryStore.shared

    @State private var query = ""
    @State private var submittedQuery = ""
    @State private var searchAllSites = false
    @State private var selCat = 0
    @State private var home = VodHome()
    @State private var items: [VodItem] = []
    @State private var page = 1
    @State private var hasMore = true
    @State private var loading = false
    @State private var errorMsg: String?

    private var cats: [(id: String, name: String)] {
        [("", "推荐")] + home.categories.map { ($0.id, $0.name) }
    }

    @Environment(\.layoutMetrics) private var layout
    private var cardWidth: CGFloat {
        let count = CGFloat(layout.posterCols)
        return max(1, (layout.width - 32 - (count - 1) * 10) / count)
    }
    private var cardHeight: CGFloat { cardWidth * 2.86 / 2 }
    private var cols: [GridItem] {
        Array(repeating: GridItem(.fixed(cardWidth), spacing: 10, alignment: .top), count: layout.posterCols)
    }

    var body: some View {
        let taskKey = "\(site.uid)|\(selCat)|\(submittedQuery)|\(searchAllSites)"
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 搜索胶囊
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(STVTheme.secondary).font(.subheadline)
                    TextField("搜索 \(site.site.name)，或聚合全站片源", text: $query)
                        .font(.subheadline).foregroundStyle(STVTheme.text)
                        .submitLabel(.search)
                        .onSubmit { submittedQuery = query.trimmingCharacters(in: .whitespaces) }
                        .compatOnChange(of: query) { v in if v.trimmingCharacters(in: .whitespaces).isEmpty { submittedQuery = "" } }
                    Button {
                        searchAllSites.toggle()
                        if !query.trimmingCharacters(in: .whitespaces).isEmpty { submittedQuery = query.trimmingCharacters(in: .whitespaces) }
                    } label: {
                        Text("全站搜")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(searchAllSites ? STVTheme.accent : STVTheme.text)
                            .padding(.horizontal, 10).frame(height: 28)
                            .background(searchAllSites ? STVTheme.accent.opacity(0.20) : STVTheme.glass, in: Capsule())
                    }.buttonStyle(.plain)
                }
                .padding(.leading, 14).padding(.trailing, 6).frame(height: 40)
                .background(STVTheme.glass, in: Capsule())
                .overlay { Capsule().strokeBorder(STVTheme.glassBorder) }
                .padding(.horizontal, 16)

                // 分类胶囊
                if submittedQuery.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(cats.indices, id: \.self) { i in
                                let on = i == selCat
                                Button { selCat = i } label: {
                                    Text(cats[i].name)
                                        .font(.caption.weight(on ? .semibold : .medium))
                                        .foregroundStyle(on ? STVTheme.bg : STVTheme.secondary)
                                        .padding(.horizontal, 13).frame(height: 30)
                                        .background(on ? STVTheme.text : STVTheme.glass, in: Capsule())
                                }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 16)
                    }
                }

                // 轻量继续观看条
                if submittedQuery.isEmpty, let latest = library.continueWatching.first(where: { $0.series.source.tvboxUID != nil }) {
                    Button {
                        Router.push(.play(latest.series, latest.episodeIndex))
                    } label: {
                        HStack(spacing: 10) {
                            CoverView(url: latest.series.cover, corner: 8)
                                .frame(width: 56, height: 38).clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(latest.series.title) · 第\(latest.episodeNumber)集").font(.caption.weight(.semibold)).foregroundStyle(STVTheme.text).lineLimit(1)
                                Text(latest.series.source.label).font(.caption2).foregroundStyle(STVTheme.secondary).lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "play.fill").font(.caption).foregroundStyle(STVTheme.bg)
                                .frame(width: 30, height: 30).background(STVTheme.text, in: Circle())
                        }
                        .padding(9)
                        .background(STVTheme.glass, in: RoundedRectangle(cornerRadius: 14))
                        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(STVTheme.glassBorder) }
                    }.buttonStyle(.plain).padding(.horizontal, 16)
                }

                // 标题行
                HStack {
                    Text(submittedQuery.isEmpty ? (cats.indices.contains(selCat) ? cats[selCat].name : "推荐") : "搜索「\(submittedQuery)」")
                        .font(.headline.weight(.bold)).foregroundStyle(STVTheme.text)
                    Spacer()
                    Text(searchAllSites && !submittedQuery.isEmpty ? "聚合 \(allSites.count) 站" : "\(site.site.name) · \(home.categories.count) 分类")
                        .font(.caption).foregroundStyle(STVTheme.secondary)
                }.padding(.horizontal, 16)

                // 3 列无框海报网格
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                        Button {
                            Router.push(.series(item.series))
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                ZStack(alignment: .topTrailing) {
                                    CoverView(url: item.cover, corner: 0)
                                        .frame(width: cardWidth, height: cardHeight)
                                        .clipped()
                                    if !item.remark.isEmpty {
                                        Text(item.remark)
                                            .font(.system(size: 10, weight: .semibold)).foregroundStyle(.white)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Color.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 5))
                                            .padding(6)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text(item.title).font(.caption.weight(.semibold)).foregroundStyle(STVTheme.text).lineLimit(1)
                                Text(item.tags.prefix(2).joined(separator: " · ").nilIfEmpty ?? DramaSource.tvbox(item.uid).label)
                                    .font(.caption2).foregroundStyle(STVTheme.secondary).lineLimit(1)
                            }
                            .frame(width: cardWidth, alignment: .leading)
                        }.buttonStyle(.plain)
                        .onAppear {
                            if idx >= items.count - 4, hasMore, !loading {
                                Task { await loadMore() }
                            }
                        }
                    }
                }.padding(.horizontal, 16)

                if loading {
                    ProgressView().frame(maxWidth: .infinity).padding(20)
                } else if let errorMsg {
                    Button("\(errorMsg) · 点击重试") { Task { await loadMore() } }
                        .font(.caption).foregroundStyle(STVTheme.secondary).frame(maxWidth: .infinity).padding(20)
                } else if items.isEmpty {
                    Text("暂无内容，试试切换分类或站点").font(.caption).foregroundStyle(STVTheme.secondary).frame(maxWidth: .infinity).padding(20)
                }
            }.padding(.bottom, 24)
        }
        .task(id: taskKey) {
            loading = false; items = []; page = 1; hasMore = true; errorMsg = nil
            await loadMore()
        }
    }

    private func loadMore() async {
        guard !loading, hasMore else { return }
        loading = true
        defer { loading = false }
        let engine = TVBoxStore.engine
        func append(_ list: [VodItem]) {
            var seen = Set(items.map(\.id))
            items += list.filter { !$0.folder && $0.action.isEmpty && seen.insert($0.id).inserted }
        }
        do {
            if !submittedQuery.isEmpty && searchAllSites {
                let targets = allSites.filter { $0.site.searchable && $0.site.quickSearch }.map(\.uid)
                for await hit in engine.searchAll(targets, submittedQuery) { append(hit.items) }
                hasMore = false
            } else if !submittedQuery.isEmpty {
                let r = try await engine.search(site.uid, submittedQuery, page: page)
                append(r.items)
                hasMore = r.hasMore; page += 1
            } else if selCat == 0 {
                for try await s in engine.home(site.uid) {
                    home = s.value
                    items = s.value.items.filter { !$0.folder && $0.action.isEmpty }
                }
                hasMore = false
            } else if cats.indices.contains(selCat) {
                let first = page == 1
                for try await s in engine.category(site.uid, cats[selCat].id, page) {
                    if first { items = [] }
                    append(s.value.items)
                    hasMore = s.value.hasMore
                }
                page += 1
            }
            errorMsg = nil
        } catch is CancellationError {
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

private struct TVBoxLiveCatalogPane: View {
    let live: TVBoxLiveRef
    @ObservedObject private var store = TVBoxStore.shared

    @State private var channels: [HGEpisode] = []
    @State private var loading = false
    @State private var errorMsg: String?
    @State private var selectedGroup = "全部"
    @State private var activeName: String?

    var body: some View {
        let groups = ["全部", "收藏"] + Array(NSOrderedSet(array: channels.compactMap(\.page)).compactMap { $0 as? String })
        let filtered: [HGEpisode] = {
            switch selectedGroup {
            case "全部": return channels
            case "收藏": return channels.filter { store.isFavoriteChannel($0.title) }
            default: return channels.filter { $0.page == selectedGroup }
            }
        }()
        let activeCh = channels.first { $0.vid == activeName } ?? filtered.first ?? channels.first

        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // 单焦点直播预览框
                if let activeCh {
                    Button { Router.push(.play(store.liveSeries(live), activeCh.ep - 1)) } label: {
                        ZStack {
                            LinearGradient(colors: [Color(red: 0.06, green: 0.09, blue: 0.14), Color(red: 0.12, green: 0.15, blue: 0.23), Color(red: 0.05, green: 0.07, blue: 0.09)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            VStack {
                                HStack {
                                    HStack(spacing: 6) {
                                        Circle().fill(Color(red: 1.0, green: 0.42, blue: 0.42)).frame(width: 7, height: 7)
                                        Text("LIVE · HLS").font(.caption2.weight(.semibold)).foregroundStyle(.white)
                                    }
                                    .padding(.horizontal, 9).padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6), in: Capsule())
                                    Spacer()
                                    Text("线路 1 / \(LiveHooks.sourceCount(activeCh))")
                                        .font(.caption2.weight(.semibold)).foregroundStyle(.white)
                                        .padding(.horizontal, 9).padding(.vertical, 4)
                                        .background(Color.black.opacity(0.6), in: Capsule())
                                }
                                Spacer()
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(activeCh.title).font(.headline.weight(.heavy)).foregroundStyle(.white).lineLimit(1)
                                        Text("\(live.live.name) · \(activeCh.page ?? "")").font(.caption2).foregroundStyle(.white.opacity(0.72))
                                    }
                                    Spacer()
                                    Label("全屏观看", systemImage: "arrow.up.left.and.arrow.down.right")
                                        .font(.caption.weight(.bold)).foregroundStyle(.black)
                                        .padding(.horizontal, 13).frame(height: 32)
                                        .background(.white, in: Capsule())
                                }
                            }.padding(14)
                        }
                        .frame(height: 170)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain).padding(.horizontal, 16)
                }

                // 分组胶囊
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(groups, id: \.self) { g in
                            let on = g == selectedGroup
                            Button { selectedGroup = g } label: {
                                Text(g == "全部" ? "全部 \(channels.count)" : g)
                                    .font(.caption.weight(on ? .semibold : .medium))
                                    .foregroundStyle(on ? STVTheme.bg : STVTheme.secondary)
                                    .padding(.horizontal, 13).frame(height: 30)
                                    .background(on ? STVTheme.text : STVTheme.glass, in: Capsule())
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal, 16)
                }

                if loading {
                    ProgressView().frame(maxWidth: .infinity).padding(28)
                } else if let errorMsg {
                    Button("\(errorMsg) · 点击重试") { Task { await load(force: true) } }
                        .font(.caption).foregroundStyle(STVTheme.secondary).frame(maxWidth: .infinity).padding(28)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filtered.enumerated()), id: \.element.vid) { idx, ch in
                            let on = ch.vid == activeCh?.vid
                            let fav = store.isFavoriteChannel(ch.title)
                            HStack(spacing: 11) {
                                Text(String(format: "%02d", idx + 1))
                                    .font(.caption.weight(.semibold)).foregroundStyle(on ? STVTheme.accent : STVTheme.secondary.opacity(0.65))
                                    .frame(width: 24)
                                Text(String(ch.title.prefix(5)))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(on ? STVTheme.accent : STVTheme.text)
                                    .frame(width: 46, height: 30)
                                    .background(on ? STVTheme.accent.opacity(0.16) : STVTheme.glass, in: RoundedRectangle(cornerRadius: 8))
                                    .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(on ? STVTheme.accent.opacity(0.42) : STVTheme.glassBorder) }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ch.title).font(.subheadline.weight(.semibold)).foregroundStyle(on ? STVTheme.accent : STVTheme.text).lineLimit(1)
                                    Text("\(ch.page ?? "") · \(LiveHooks.sourceCount(ch)) 条信号源\(on ? " · 正在预览" : "")")
                                        .font(.caption2).foregroundStyle(STVTheme.secondary).lineLimit(1)
                                }
                                Spacer()
                                Button { store.toggleFavoriteChannel(ch.title) } label: {
                                    Image(systemName: fav ? "star.fill" : "star")
                                        .foregroundStyle(fav ? STVTheme.accentWarm : STVTheme.secondary.opacity(0.6))
                                }.buttonStyle(.plain)
                            }
                            .padding(.vertical, 11)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                activeName = ch.vid
                                Router.push(.play(store.liveSeries(live), ch.ep - 1))
                            }
                            if idx < filtered.count - 1 { Divider().overlay(STVTheme.text.opacity(0.07)) }
                        }
                    }.padding(.horizontal, 16)
                }
            }.padding(.bottom, 24)
        }
        .task(id: live.uid) { if channels.isEmpty { await load(force: false) } }
    }

    private func load(force: Bool) async {
        loading = true
        defer { loading = false }
        do {
            let open = store.unlocked(live.uid)
            if force { for try await _ in TVBoxStore.engine.liveChannels(live.uid, force: true) {} }
            channels = try await TVBoxStore.engine.liveDetail(live.uid, unlocked: open).episodes
            errorMsg = nil
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}
