package com.example.ubeer

import android.content.Context
import android.webkit.JavascriptInterface
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.Source
import com.google.android.gms.tasks.Tasks
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest
import java.util.UUID
import android.util.Base64
import android.net.ConnectivityManager
import android.net.NetworkCapabilities

/** Explicit, immutable cloud backups. Local POS storage remains the source of truth. */
class CloudBackup(private val context: Context, private val reply: (JSONObject) -> Unit) {
    private val configured = FirebaseApp.getApps(context).any {
        it.name == FirebaseApp.DEFAULT_APP_NAME && it.options.projectId == "beer-b74cb"
    }
    private val auth: FirebaseAuth? = if (configured) FirebaseAuth.getInstance() else null
    private val store: FirebaseFirestore? = if (configured) FirebaseFirestore.getInstance() else null
    private var busy = false

    private fun status(): JSONObject = JSONObject().put("configured", configured)
        .put("project", if (configured) FirebaseApp.getInstance().options.projectId else "beer-b74cb")
        .put("email", auth?.currentUser?.email ?: "").put("signedIn", auth?.currentUser != null)

    private fun finish(action: String, data: Any? = null, error: String? = null) {
        busy = false
        reply(JSONObject().put("action", action).put("ok", error == null)
            .put("status", status()).put("data", data ?: JSONObject.NULL).put("error", error ?: ""))
    }

    @JavascriptInterface fun statusJson(): String = status().toString()

    @JavascriptInterface fun request(action: String, payload: String) {
        // All state and Firebase callbacks run on the activity's main thread.
        (context as MainActivity).runOnUiThread {
            if (busy) { reply(JSONObject().put("action", "busy").put("ok", false).put("error", "A cloud operation is already running.")); return@runOnUiThread }
            if (!configured) { finish(action, error = "Firebase configuration is missing. Add the Beer project's google-services.json and rebuild the app."); return@runOnUiThread }
            busy = true
            try {
                if (action != "signOut") {
                    val network = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                    val capabilities = network.getNetworkCapabilities(network.activeNetwork)
                    require(capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true) {
                        "No internet connection. Your POS data is still saved on this device."
                    }
                }
                val input = JSONObject(payload)
                when (action) {
                    "signIn", "createAccount" -> {
                        val email = input.getString("email").trim()
                        val password = input.getString("password")
                        val task = if (action == "createAccount") auth!!.createUserWithEmailAndPassword(email, password)
                            else auth!!.signInWithEmailAndPassword(email, password)
                        task.addOnSuccessListener { finish(action) }.addOnFailureListener { finish(action, error = it.localizedMessage ?: "Sign-in failed") }
                    }
                    "signOut" -> { auth!!.signOut(); finish(action) }
                    "backup" -> backup(input.getString("json"))
                    "list" -> list()
                    "restore" -> restore(input.getString("id"))
                    else -> finish(action, error = "Unknown cloud operation")
                }
            } catch (e: Exception) { finish(action, error = e.localizedMessage ?: "Cloud operation failed") }
        }
    }

    private fun backups() = store!!.collection("users").document(
        auth?.currentUser?.uid ?: throw IllegalStateException("Sign in before using cloud backups.")
    ).collection("backups")

    private fun digest(bytes: ByteArray): String = MessageDigest.getInstance("SHA-256")
        .digest(bytes).joinToString("") { "%02x".format(it.toInt() and 255) }

    private fun backup(json: String) {
        val bytes = json.toByteArray(Charsets.UTF_8)
        require(bytes.size <= 6 * 1024 * 1024) { "Backup exceeds 6 MB. Use the local backup export instead." }
        val parsed = JSONObject(json)
        require(parsed.getInt("version") == 1) { "Unsupported backup format" }
        val ref = backups().document(UUID.randomUUID().toString())
        val batch = store!!.batch()
        val chunkSize = 128 * 1024
        val count = (bytes.size + chunkSize - 1) / chunkSize
        for (i in 0 until count) {
            val chunk = bytes.copyOfRange(i * chunkSize, minOf((i + 1) * chunkSize, bytes.size))
            batch.set(ref.collection("chunks").document(i.toString()), mapOf("data" to Base64.encodeToString(chunk, Base64.NO_WRAP)))
        }
        batch.set(ref, mapOf("createdAt" to FieldValue.serverTimestamp(), "chunks" to count,
            "bytes" to bytes.size, "sha256" to digest(bytes), "version" to 1,
            "invoices" to parsed.getJSONArray("invoices").length(), "products" to parsed.getJSONArray("products").length(),
            "customers" to (parsed.optJSONArray("customers")?.length() ?: 0)))
        // Success means the server acknowledged the complete atomic backup, not just a local write.
        batch.commit().addOnSuccessListener { finish("backup", ref.id) }
            .addOnFailureListener { finish("backup", error = it.localizedMessage ?: "Backup failed") }
    }

    private fun list() {
        backups().orderBy("createdAt", Query.Direction.DESCENDING).limit(20).get(Source.SERVER)
            .addOnSuccessListener { snapshot ->
                val rows = JSONArray()
                for (doc in snapshot.documents.filter { Regex("[a-zA-Z0-9-]+").matches(it.id) }) rows.put(JSONObject().put("id", doc.id)
                    .put("created", doc.getTimestamp("createdAt")?.toDate()?.time ?: 0)
                    .put("invoices", doc.getLong("invoices") ?: 0).put("products", doc.getLong("products") ?: 0)
                    .put("customers", doc.getLong("customers") ?: 0))
                finish("list", rows)
            }.addOnFailureListener { finish("list", error = it.localizedMessage ?: "Could not load backups") }
    }

    private fun restore(id: String) {
        require(Regex("[a-zA-Z0-9-]+").matches(id)) { "Invalid backup ID" }
        val ref = backups().document(id)
        ref.get(Source.SERVER).addOnSuccessListener { manifest ->
            try {
                require(manifest.exists()) { "Backup no longer exists" }
                val count = manifest.getLong("chunks")?.toInt() ?: 0
                require(count in 1..48) { "Invalid backup size" }
                val reads = (0 until count).map { ref.collection("chunks").document(it.toString()).get(Source.SERVER) }
                Tasks.whenAllSuccess<com.google.firebase.firestore.DocumentSnapshot>(reads)
                    .addOnSuccessListener { chunks ->
                        try {
                            val bytes = java.io.ByteArrayOutputStream()
                            for (chunk in chunks) {
                                bytes.write(Base64.decode(chunk.getString("data") ?: error("Incomplete backup"), Base64.NO_WRAP))
                                require(bytes.size() <= 6 * 1024 * 1024) { "Backup exceeds size limit" }
                            }
                            val result = bytes.toByteArray()
                            require(result.size.toLong() == manifest.getLong("bytes") && digest(result) == manifest.getString("sha256")) { "Backup integrity check failed" }
                            finish("restore", String(result, Charsets.UTF_8))
                        } catch (e: Exception) { finish("restore", error = e.localizedMessage ?: "Invalid backup") }
                    }.addOnFailureListener { finish("restore", error = it.localizedMessage ?: "Could not download backup") }
            } catch (e: Exception) { finish("restore", error = e.localizedMessage ?: "Invalid backup") }
        }.addOnFailureListener { finish("restore", error = it.localizedMessage ?: "Could not download backup") }
    }
}
