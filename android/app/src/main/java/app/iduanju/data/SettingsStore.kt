package app.iduanju.data

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import org.json.JSONArray

/** Public hygiene: optional player device override "did,iid" — never hard-coded. */
class SettingsStore(ctx: Context) {
    private val sp = ctx.getSharedPreferences("idj", Context.MODE_PRIVATE)

    fun playerDeviceOverride(): Pair<String, String>? {
        val s = sp.getString("hg.purePlayerDevice", null) ?: return null
        val p = s.split(",", limit = 2).map { it.trim() }
        return if (p.size == 2 && p[0].isNotEmpty() && p[1].isNotEmpty()) p[0] to p[1] else null
    }

    fun setPlayerDeviceOverride(did: String?, iid: String?) {
        if (did.isNullOrBlank() || iid.isNullOrBlank()) sp.edit().remove("hg.purePlayerDevice").apply()
        else sp.edit().putString("hg.purePlayerDevice", "$did,$iid").apply()
    }

    /** Developer option: let the player/media download follow the system proxy (default off = iOS parity). */
    var playerUsesSystemProxy: Boolean
        get() = sp.getBoolean("dev.playerSystemProxy", false)
        set(v) { sp.edit().putBoolean("dev.playerSystemProxy", v).apply(); app.iduanju.core.hongguo.HGNet.playerUsesSystemProxy = v }

    var adStripEnabled: Boolean
        get() = sp.getBoolean("stv.hls.adstrip", sp.getBoolean("adStrip", true))
        set(v) { sp.edit().putBoolean("stv.hls.adstrip", v).apply() }

    var prefetchEnabled: Boolean
        get() = sp.getBoolean("prefetchEnabled", true)
        set(v) { sp.edit().putBoolean("prefetchEnabled", v).apply() }

    var playbackCacheMB: Int
        get() = sp.getInt("playbackCacheMB", 600).coerceIn(100, 2000)
        set(v) { sp.edit().putInt("playbackCacheMB", v.coerceIn(100, 2000)).apply() }

    /** User-defined order of the home channel tabs (homePages keys); empty = built-in order. State-backed so the home screen re-sorts live. */
    var homePageOrder: List<String> by mutableStateOf(loadHomePageOrder())
        private set

    private fun loadHomePageOrder(): List<String> = runCatching {
        val a = JSONArray(sp.getString("home.pageOrder", "[]") ?: "[]")
        List(a.length()) { a.getString(it) }
    }.getOrDefault(emptyList())

    fun saveHomePageOrder(keys: List<String>) {
        homePageOrder = keys
        sp.edit().putString("home.pageOrder", JSONArray(keys).toString()).apply()
    }

    /** Home pager's current page key (transient, never persisted): the search screen opens on this source. */
    var currentHomePageKey: String? by mutableStateOf(null)

    var danmakuArea: Float
        get() = sp.getFloat("danmakuArea", 1f / 3f)
        set(v) { sp.edit().putFloat("danmakuArea", v).apply() }
}
