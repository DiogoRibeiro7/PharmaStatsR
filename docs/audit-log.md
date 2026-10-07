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

## External HMAC reference vectors

The [fixed-vector tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-audit-reference.R)
include a three-row chain whose HMAC-SHA256 values were calculated outside R and
outside the package with Python's standard-library \`hmac\` and \`hashlib\`
implementations.

The test key is \`reference-key-164\`. The package's historical serialization
uses one space between the message, timestamp, and previous hash. For the
genesis row the previous value is the literal text produced by R's
\`NA_character_\` inside \`paste()\`, namely \`NA\`.

| Row | Step | Timestamp | Previous hash | Expected HMAC-SHA256 |
| ---: | --- | --- | --- | --- |
| 1 | \`genesis\` | \`2026-01-02 03:04:05 UTC\` | \`NA\` | \`438418a710bb511683c6a7a39fbf1e92a01274fbeec7ffbb3f499d578e340cd2\` |
| 2 | \`Load "trial", data\` | \`2026-01-02 03:04:06 UTC\` | row 1 hash | \`b41f5af5f230a80e84b1f389009d0d207797d3bbfc71ff81023cb5af3dff44e8\` |
| 3 | \`Fit model v1\` | \`2026-01-02 03:04:07 UTC\` | row 2 hash | \`54a93366dbc94990c7cef060770a56c621e43c0ceddd3e763d0a4e580d6e5781\` |

For example, the exact authenticated genesis string is:

\`\`\`text
genesis 2026-01-02 03:04:05 UTC NA
\`\`\`

and the second row authenticates:

\`\`\`text
Load "trial", data 2026-01-02 03:04:06 UTC 438418a710bb511683c6a7a39fbf1e92a01274fbeec7ffbb3f499d578e340cd2
\`\`\`

The package must verify the externally generated CSV with the test key and
reject it under a different key. Editing the message, timestamp, link, or
stored HMAC must fail verification. The quoted comma-containing message also
checks CSV round-trip preservation independently of the HMAC calculation.

The writer is additionally required to accept this externally generated valid
chain and append a new row whose \`previous_hash\` is exactly the third fixed
digest. This checks interoperability with the documented serialization without
changing historical log compatibility.

Deleting the third row leaves the first two rows as a cryptographically valid
prefix, and verification intentionally still succeeds. That fixed test records
the central limitation of an in-file hash chain: without an external expected
final hash or record count, tail deletion is not detectable.

These vectors validate the implemented HMAC serialization and chain verification
against one independent cryptographic implementation. They do not provide key
management, append-only storage, concurrency control, access control, external
anchoring, tail-deletion detection, or regulatory audit compliance.


## Scope

The chain is only evidence about **records still in the file**. Anyone able to remove the final rows can leave a valid prefix. To detect that, preserve the expected final hash or record count outside the file. The helper does not prevent deletion, replacement of the file, concurrent edits, loss of the key, or unauthorized access. It is not a regulated audit system. See [limitations and validation](limitations.md).

## R help

Full arguments and return values:

- [`pharma_audit_log()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_audit_log.Rd)
- [`pharma_audit_verify()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_audit_verify.Rd)

In an installed package, run `help(package = "PharmaStatsR")` to open the corresponding topics.
