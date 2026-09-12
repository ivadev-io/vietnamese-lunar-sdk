package io.ivadev.lunar.api

import java.io.IOException
import java.net.HttpURLConnection
import java.net.URI
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

data class LunarApiResponse(
    val status: Int,
    val json: String,
    val dailyLimit: Int?,
    val dailyRemaining: Int?,
    val dailyResetEpochSeconds: Long?
)

class LunarApiException(val status: Int, val responseJson: String) : IOException("Vietnamese Lunar API returned HTTP $status")

/** Transport-only JVM/Android client. It contains no calendar algorithm. */
class LunarApiClient(
    private val apiKey: String,
    private val baseUrl: String = "https://lunar.ivadev.workers.dev",
    private val connectTimeoutMillis: Int = 10_000,
    private val readTimeoutMillis: Int = 10_000
) {
    init { require(apiKey.isNotBlank()) { "apiKey is required" } }

    fun toLunar(date: String, profile: String? = null) = get("/v1/lunar?date=${encode(date)}${profilePart(profile)}")

    fun toSolar(day: Int, month: Int, year: Int, isLeapMonth: Boolean = false, profile: String? = null) =
        get("/v1/solar?day=$day&month=$month&year=$year&leap=$isLeapMonth${profilePart(profile)}")

    fun solarTerms(year: Int, profile: String? = null) = get("/v1/solar-terms?year=$year${profilePart(profile)}")

    fun toLunarBatch(dates: List<String>, profile: String? = null): LunarApiResponse {
        require(dates.size in 1..31) { "dates must contain 1 to 31 values" }
        val escaped = dates.joinToString(",") { "\"${jsonEscape(it)}\"" }
        val body = "{\"dates\":[$escaped]${profile?.let { ",\"profile\":\"${jsonEscape(it)}\"" } ?: ""}}"
        return request("/v1/lunar/batch", "POST", body)
    }

    private fun get(path: String) = request(path, "GET", null)

    private fun request(path: String, method: String, body: String?): LunarApiResponse {
        val connection = URI.create(baseUrl.trimEnd('/') + path).toURL().openConnection() as HttpURLConnection
        connection.requestMethod = method
        connection.connectTimeout = connectTimeoutMillis
        connection.readTimeout = readTimeoutMillis
        connection.setRequestProperty("Accept", "application/json")
        connection.setRequestProperty("X-API-Key", apiKey)
        connection.setRequestProperty("X-Client-Version", "kotlin/1.0.0")
        if (body != null) {
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json")
            connection.outputStream.use { it.write(body.toByteArray(StandardCharsets.UTF_8)) }
        }
        val status = connection.responseCode
        val stream = if (status in 200..299) connection.inputStream else connection.errorStream
        val json = stream?.bufferedReader(StandardCharsets.UTF_8)?.use { it.readText() } ?: ""
        val result = LunarApiResponse(status, json, connection.intHeader("X-RateLimit-Daily-Limit"), connection.intHeader("X-RateLimit-Daily-Remaining"), connection.longHeader("X-RateLimit-Daily-Reset"))
        connection.disconnect()
        if (status !in 200..299) throw LunarApiException(status, json)
        return result
    }

    private fun profilePart(profile: String?) = profile?.let { "&profile=${encode(it)}" } ?: ""
    private fun encode(value: String) = URLEncoder.encode(value, StandardCharsets.UTF_8.name())
    private fun jsonEscape(value: String) = value.replace("\\", "\\\\").replace("\"", "\\\"")
    private fun HttpURLConnection.intHeader(name: String) = getHeaderField(name)?.toIntOrNull()
    private fun HttpURLConnection.longHeader(name: String) = getHeaderField(name)?.toLongOrNull()
}
