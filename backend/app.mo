import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import LlmCanister "mo:llm";

actor UserManager {

    type User = {
        username: Text;
        password: Text;
    };

    stable var userBuffer: [(Text, User)] = [];

    var users: HashMap.HashMap<Text, User> = HashMap.HashMap<Text, User>(
        10, Text.equal, Text.hash
    );

    system func preupgrade() {
        userBuffer := Iter.toArray(users.entries());
    };

    system func postupgrade() {
        users := HashMap.fromIter<Text, User>(
            Iter.fromArray(userBuffer),
            10,
            Text.equal,
            Text.hash
        );
    };

    public func register(username: Text, password: Text): async Text {
        if (users.get(username) != null) {
            return "⚠️ Username sudah terdaftar!";
        };

        let newUser: User = { username = username; password = password };
        users.put(username, newUser);

        return "✅ Registrasi berhasil!";
    };

    public func login(username: Text, password: Text): async Text {
        switch (users.get(username)) {
            case (null) { return "❌ User tidak ditemukan!"; };
            case (?user) {
                if (user.password == password) {
                    return "✅ Login sukses!";
                } else {
                    return "❌ Password salah!";
                };
            };
        };
    };

    public func isUserExists(username: Text): async Bool {
        return users.get(username) != null;
    };

    // Objek HoaxVerifier sebagai bagian dari UserManager
    let hoaxVerifier = object {
        public func checkNews(newsText : Text) : async Text {
            let prompt = "Saya memiliki berita berikut:\n\n" # newsText # "\n\n" #
            "Tolong analisis berita ini dan tentukan apakah ini hoax atau fakta berdasarkan sumber terpercaya dan pola hoax yang umum.\n" #
            "Berikan output dalam format berikut:\n\n" #
            "1. **Kesimpulan:** (Apakah berita ini HOAX atau FAKTA?)\n" #
            "2. **Alasan:** (Jelaskan mengapa berita ini dianggap hoax atau fakta, berdasarkan sumber atau pola berita yang digunakan)\n" #
            "3. **Tingkat Kepercayaan:** (Persentase kemungkinan hoax atau fakta, misalnya 90% HOAX atau 85% FAKTA)\n" #
            "4. **Diagram atau Visualisasi:**\n" #
            "   - Jika memungkinkan, buatlah dalam format JSON yang bisa diterjemahkan menjadi grafik.\n" #
            "   - Contoh output JSON untuk visualisasi:\n" #
            "   ```json\n" #
            "   {\n" #
            "     \"status\": \"HOAX\",\n" #
            "     \"confidence\": 90,\n" #
            "     \"evidence\": {\n" #
            "       \"clickbait\": 85,\n" #
            "       \"source_unreliable\": 70,\n" #
            "       \"manipulated_images\": 95\n" #
            "     }\n" #
            "   }\n" #
            "   ```\n" #
            "   - Jika bisa, sertakan analisis singkat dalam bentuk tabel atau diagram teks.\n\n" #
            "Gunakan analisis berbasis model AI terbaru untuk mendapatkan hasil yang akurat.";

            let result = await LlmCanister.prompt(#Llama3_1_8B, prompt);
            return result;
        };
    };

    public shared func checkNews(newsText: Text) : async Text {
        await hoaxVerifier.checkNews(newsText);
    };
};
