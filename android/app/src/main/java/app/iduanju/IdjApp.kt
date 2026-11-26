package app.iduanju

import android.app.Application
import app.iduanju.core.hongguo.HGPlayerDevice
import app.iduanju.core.hongguo.HongguoClient
import app.iduanju.data.LibraryStore
import app.iduanju.data.SettingsStore
import org.json.JSONArray

class IdjApp : Application(), coil.ImageLoaderFactory {
    lateinit var settings: SettingsStore
        private set
    lateinit var hongguo: HongguoClient
        private set
    lateinit var hgWebAccount: app.iduanju.data.HongguoWebAccount
        private set
    lateinit var library: LibraryStore
        private set
    lateinit var cms: app.iduanju.data.CMSStore
    lateinit var tvbox: app.iduanju.tvbox.TVBoxStore
        private set
    lateinit var plugins: app.iduanju.plugin.PluginStore
        private set
    lateinit var tg: app.iduanju.tg.TGStore
        private set
    lateinit var manga: app.iduanju.manga.MangaStore
        private set
    lateinit var huangguo: app.iduanju.core.huangguo.HuangguoClient
        private set
    lateinit var updater: app.iduanju.update.AppUpdater
        private set

    /** Covers: 黄果 CDNs obfuscate images (AES / XOR) — decoded in an OkHttp interceptor; TVBox covers carry request headers. */
    override fun newImageLoader(): coil.ImageLoader = coil.ImageLoader.Builder(this)
        .okHttpClient {
            okhttp3.OkHttpClient.Builder().addInterceptor(app.iduanju.huangguo.CoverDecryptInterceptor)
                .dns(app.iduanju.tvbox.TVBoxPictureGuard).addNetworkInterceptor(app.iduanju.tvbox.TVBoxPictureGuard).build()
        }
        .components { add(app.iduanju.tvbox.TVBoxPictureInterceptor); add(app.iduanju.plugin.PluginImageFetcher.Factory()) }
        .crossfade(true).build()

    override fun onCreate() {
        super.onCreate()
        instance = this
        settings = SettingsStore(this)
        seedBuiltinNovelSources()
        app.iduanju.core.novel.NovelSources.configureStorage(filesDir)
        HGPlayerDevice.storageDir = filesDir
        app.iduanju.core.hongguo.HGNet.playerUsesSystemProxy = settings.playerUsesSystemProxy
        HGPlayerDevice.overrideProvider = {
            settings.playerDeviceOverride()?.let { it }
        }
        hongguo = HongguoClient(filesDir)
        hgWebAccount = app.iduanju.data.HongguoWebAccount(this)
        app.iduanju.core.hls.HLSAdFilter.enabled = getSharedPreferences("idj", MODE_PRIVATE).getBoolean("stv.hls.adstrip", true)
        library = LibraryStore(this)
        cms = app.iduanju.data.CMSStore(this)
        tvbox = app.iduanju.tvbox.TVBoxStore(this)
        plugins = app.iduanju.plugin.PluginStore(this)
        tg = app.iduanju.tg.TGStore(this)
        manga = app.iduanju.manga.MangaStore(this)
        huangguo = app.iduanju.core.huangguo.HuangguoClient(filesDir, app.iduanju.huangguo.PrefsMap(this), app.iduanju.huangguo.WebViewCookieJar)
        app.iduanju.core.hls.HLSAdFilter.enabled = settings.adStripEnabled
        updater = app.iduanju.update.AppUpdater(this)
        app.iduanju.core.novel.LegadoWebView.backstage = app.iduanju.novel.AndroidBackstageWebView(this)
    }

    /** One-time seed of the bundled novel book sources (assets/novel/builtin_sources.json): merged into the novel prefs by bookSourceUrl; the marker keeps it from ever running again, so sources the user deletes stay deleted. */
    private fun seedBuiltinNovelSources() {
        val prefs = getSharedPreferences("novel", MODE_PRIVATE)
        if (prefs.getBoolean("builtinSeeded.v1", false)) return
        Thread {
            runCatching {
                val builtin = JSONArray(assets.open("novel/builtin_sources.json").readBytes().toString(Charsets.UTF_8))
                val current = runCatching { JSONArray(prefs.getString("sources", "[]") ?: "[]") }.getOrDefault(JSONArray())
                val seen = HashSet<String>()
                for (i in 0 until current.length()) current.optJSONObject(i)?.optString("bookSourceUrl")?.takeIf { it.isNotEmpty() }?.let { seen.add(it) }
                var added = 0
                for (i in 0 until builtin.length()) {
                    val o = builtin.optJSONObject(i) ?: continue
                    val url = o.optString("bookSourceUrl")
                    if (url.isEmpty() || !seen.add(url)) continue
                    current.put(o); added++
                }
                val e = prefs.edit().putBoolean("builtinSeeded.v1", true)
                if (added > 0) e.putString("sources", current.toString())
                e.apply()
            }
        }.start()
    }

    companion object {
        lateinit var instance: IdjApp
            private set
    }
}
