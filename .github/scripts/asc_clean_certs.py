"""CI'ın her çalışmada otomatik oluşturduğu geliştirme sertifikalarını temizler.
Yalnızca API anahtarıyla oluşturulmuş ("Created via API") Development sertifikalarına dokunur;
Mac'te Xcode ile oluşturulmuş kişisel sertifikalar ve dağıtım sertifikaları silinmez."""
import os, sys, time, json, urllib.request
import jwt

kid, iss = os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"]
key = open(os.path.expanduser(f"~/private_keys/AuthKey_{kid}.p8")).read()
tok = jwt.encode({"iss": iss, "iat": int(time.time()), "exp": int(time.time()) + 1200, "aud": "appstoreconnect-v1"}, key, algorithm="ES256", headers={"kid": kid})

def call(method, path):
    req = urllib.request.Request("https://api.appstoreconnect.apple.com" + path, method=method, headers={"Authorization": "Bearer " + tok})
    with urllib.request.urlopen(req) as r:
        body = r.read()
        return json.loads(body) if body else {}

certs = call("GET", "/v1/certificates?limit=200")["data"]
for c in certs:
    a = c["attributes"]
    print(a.get("certificateType"), "|", a.get("name"), "|", a.get("displayName"), "|", a.get("expirationDate"))
dev = [c for c in certs if c["attributes"].get("certificateType") in ("DEVELOPMENT", "IOS_DEVELOPMENT")
       and "Created via API" in (c["attributes"].get("name", "") + c["attributes"].get("displayName", ""))]
# Apple sınırına yaklaşmadan dokunma: her iptal kullanıcıya e-posta gönderiyor
if len(dev) < 5:
    print("CI sertifika sayısı", len(dev), "— temizlik gerekmiyor"); sys.exit(0)
dev.sort(key=lambda c: c["attributes"].get("expirationDate", ""))
dev = dev[:-1]   # en yenisini bırak
for c in dev:
    print("revoke", c["id"], c["attributes"].get("name"))
    try:
        call("DELETE", "/v1/certificates/" + c["id"])
    except Exception as e:
        print("  failed:", e)
print("revoked", len(dev))
