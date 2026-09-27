# Local audit log integrity

`pharma_audit_log()` writes a local CSV log. Each row includes a message, UTC timestamp, previous hash, and HMAC-SHA256 computed with a caller supplied key. `pharma_audit_verify()` checks the stored chain. The [openssl hashing reference](https://cran.r-project.org/web/packages/openssl/refman/openssl.html) describes the keyed HMAC behavior.

```r
library(PharmaStatsR)

path <- tempfile(fileext = ".csv")
secret <- Sys.getenv("ANALYSIS_AUDIT_KEY")
stopifnot(nzchar(secret))

pharma_audit_log("Imported synthetic data", path, key = secret)
pharma_audit_log("Fitted planned model", path, key = secret)
stopifnot(pharma_audit_verify(path, key = secret))
```

Keep the key outside the log. Use a separate secret management process for real work; do not put a key in a repository or an issue.

## What verification establishes

For row \(i>1\), let \(H_{i-1}\) be the preceding stored hash. The function checks \(H_i=\operatorname{HMAC}_{K}(m_i\,\Vert\,t_i\,\Vert\,H_{i-1})\) using the message \(m_i\), timestamp \(t_i\), and key \(K\). It also checks the genesis row and CSV columns. The existing serialization uses a space between fields, and is kept for compatibility with existing logs. Verification returns `FALSE` for a wrong key, an edited row, missing links, or malformed CSV. Missing files and invalid arguments raise an error.

When appending to an existing file, the writer first verifies it with the supplied key. If verification fails, it does not append. Previously generated valid logs can still be read and extended with the original key.

## Scope

The chain is only evidence about **records still in the file**. Anyone able to remove the final rows can leave a valid prefix. To detect that, preserve the expected final hash or record count outside the file. The helper does not prevent deletion, replacement of the file, concurrent edits, loss of the key, or unauthorized access. It is not a regulated audit system. See [limitations and validation](limitations.md).
