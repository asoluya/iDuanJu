import XCTest

/// Walks the glass surfaces (bars, panels, sheets, dialogs) on offline fixtures and attaches a screenshot of each state, in
/// light and dark. Every step also asserts that the surface is there, so it doubles as a regression test of the chrome.
final class GlassShotsUITests: XCTestCase {
    private var app: XCUIApplication!
    private var tag = ""
    private static let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("STVTests/Fixtures").path

    private func el(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }
    private func launch(_ env: [String: String]) {
        app = XCUIApplication()
        app.launchEnvironment = ["STV_HERO_STILL": "1"].merging(env) { $1 }
        app.launch()
    }
    private func shot(_ name: String, settle: TimeInterval = 0.9) {
        Thread.sleep(forTimeInterval: settle)
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = "\(name)-\(tag)"
        a.lifetime = .keepAlways
        add(a)
    }
    private func need(_ id: String, _ timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(el(id).waitForExistence(timeout: timeout), "missing \(id)", file: file, line: line)
    }
    private func tap(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        need(id, file: file, line: line)
        el(id).tap()
    }
    private func at(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate { app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)) }
    private func bothAppearances(_ body: () -> Void) {
        continueAfterFailure = true
        for (style, name) in [(XCUIDevice.Appearance.light, "light"), (.dark, "dark")] {
            XCUIDevice.shared.appearance = style
            tag = name
            body()
            app.terminate()
        }
        XCUIDevice.shared.appearance = .light
    }

    func testDetailBars() {
        bothAppearances {
            launch(["STV_ROUTE": "detail:ui-detail-full"])
            need("detail.play")
            shot("detail-1-top")
            app.swipeUp()
            need("detail.playbar")
            shot("detail-2-scrolled")
            app.swipeDown(velocity: .slow)
            shot("detail-3-back")
            app.terminate()
            launch(["STV_ROUTE": "detail:ui-detail-lines"])
            need("detail.lines")
            shot("detail-lines-1-top")
            tap("detail.line.l2")
            tap("detail.order")
            app.swipeUp(velocity: .slow)
            shot("detail-lines-2-named")
        }
    }

    func testReaderPanels() {
        bothAppearances {
            launch(["STV_HOME_TAB": "novel", "STV_NOVEL_SEED": "x/novel_sample_gbk.txt"])
            tap("novel.book.novel_sample_gbk")
            need("novel.page")
            at(0.5, 0.5).tap()
            need("novel.menu.目录")
            shot("reader-1-menu")
            tap("novel.menu.亮度"); tap("novel.theme.0")
            shot("reader-2-light")
            tap("novel.theme.1"); tap("novel.menu.设置")
            shot("reader-3-cream-settings")
            tap("novel.menu.目录")
            shot("reader-4-cream-toc")
            tap("novel.menu.亮度"); tap("novel.theme.3"); tap("novel.menu.进度")
            shot("reader-5-night-progress")
            tap("novel.listen")
            shot("reader-6-night-listen")
            at(0.5, 0.1).tap()
            shot("reader-7-mini")
            at(0.5, 0.5).tap(); tap("novel.menu.亮度"); tap("novel.theme.0")
        }
    }

    func testSheetsAndDialogs() {
        bothAppearances {
            launch(["STV_ROUTE": "plugins", "STV_PLUGINS_RESET": "1", "STV_PLUGIN_DEMO": "1", "STV_CMS_FIXTURE": "1"])
            tap("plugins.add.url")
            XCTAssertTrue(app.buttons["下一步"].waitForExistence(timeout: 5))
            shot("dialog-input")
            app.buttons["取消"].firstMatch.tap()
            Thread.sleep(forTimeInterval: 0.6)
            tap("plugins.add.paste")
            shot("sheet-paste")
            app.terminate()

            launch(["STV_ROUTE": "history", "STV_SEED_WATCH": "5"])
            tap("history.clear")
            XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH '清空 '")).firstMatch.waitForExistence(timeout: 5))
            shot("dialog-confirm")
            app.terminate()

            launch(["STV_HOME_TAB": "eporner", "STV_SOURCES": "eporner", "STV_FIXTURE_SITES": "1"])
            need("home.filter")
            shot("home-1-top", settle: 2)
            el("home.page.Eporner").swipeUp(velocity: .slow)
            shot("home-2-scrolled")
            tap("home.filter")
            need("home.channelPanel")
            shot("home-3-panel")
            app.terminate()

            launch(["STV_HOME_TAB": "novel", "STV_NOVEL_PAGE": "import", "STV_UI_PREVIEW": "1"])
            need("import.url")
            shot("sheet-import")
            app.terminate()

            launch(["STV_HOME_TAB": "novel", "STV_NOVEL_PAGE": "rank", "STV_UI_PREVIEW": "1"])
            need("novel.rank.source")
            shot("rank-1", settle: 3)
            tap("novel.rank.source")
            shot("rank-2-sources")
        }
    }

    func testNovelDetail() {
        bothAppearances {
            launch(["STV_HOME_TAB": "novel", "STV_NOVEL_PAGE": "search", "STV_UI_PREVIEW": "1", "STV_NOVEL_QUERY": "长夜"])
            let hit = el("search.result.长夜星河")
            XCTAssertTrue(hit.waitForExistence(timeout: 20))
            shot("novel-search")
            hit.tap()
            need("detail.read")
            shot("novel-detail-1", settle: 3)
            app.swipeUp(velocity: .slow)
            shot("novel-detail-2-scrolled")
            app.swipeDown()
            tap("detail.source")
            shot("novel-detail-3-sources")
        }
    }

    func testMangaAndFeed() {
        bothAppearances {
            launch(["STV_HOME_TAB": "manga", "STV_MANGA_FIXTURE": "1"])
            tap("manga.cell.fx0")
            need("manga.read")
            shot("manga-detail")
            tap("manga.read")
            need("manga.reader")
            shot("manga-reader", settle: 2)
            app.terminate()

            launch(["STV_HOME_TAB": "channels", "STV_TG_FIXTURE_DIR": Self.fixtures, "STV_TG_CHANNELS": "telegram,gallery"])
            let post = el("tg.post.gallery/7")
            XCTAssertTrue(post.waitForExistence(timeout: 15))
            shot("feed-1")
            tap("tg.manage")
            need("tg.add.field")
            shot("feed-2-manage")
            app.terminate()
            launch(["STV_ROUTE": "sources"])
            need("sources.huangguo")
            app.swipeUp()
            shot("sources-bottom")
        }
    }
}
