# Vivd Security Considerations

This document describes the security properties, limitations, and responsible use guidelines for the Vivd face liveness detection SDK.

---

## Session Signing

### HMAC-SHA256 Signing

When `VivdConfig.hmacKey` is configured with a non-empty string, Vivd signs liveness results with HMAC-SHA256 to enable server-side verification.

**Signing process:**

1. A `SessionManager` instance is created with the provided key and session duration.
2. On `startLiveness()`, a new `Session` is created with:
   - `sessionId` -- 16 random hex bytes (cryptographically random via `Random.secure()`)
   - `nonce` -- 32 random hex bytes (cryptographically random)
   - `createdAt` -- current timestamp in milliseconds
   - `expiresAt` -- `createdAt + sessionDurationSeconds * 1000`
3. After the liveness session completes, `signResults()` builds the payload string:
   ```
   "{sessionId}|{nonce}|{timestamp}|{score}"
   ```
4. HMAC-SHA256 is computed over the payload string using the shared key.
5. A `SignedPayload` is returned containing the session data and hex-encoded signature.

**What is signed:**

- `sessionId` -- unique session identifier
- `nonce` -- random value for replay protection
- `timestamp` -- when the signature was generated
- `score` -- the overall liveness confidence score

**What is NOT signed:**

- Individual action results (included in the JSON payload but not part of the HMAC computation)
- The `actions` list

This means an attacker with access to a valid signed payload could modify the `results` array without invalidating the signature. The server should independently validate that the reported actions match expected challenge sequences.

### Nonce and Replay Protection

Each session generates a unique 32-byte (64 hex character) nonce. This prevents replay attacks where an attacker captures a valid signed payload and resubmits it.

**Server-side implementation:**

1. On receiving a signed payload, extract the nonce.
2. Check if the nonce has been seen before (use a database or key-value store with TTL).
3. If the nonce exists, reject as replay attack.
4. If new, store the nonce with expiration matching `sessionDurationSeconds`.
5. Proceed with signature verification.

**Client-side behavior:**

- Nonces are generated via `Random.secure()` which uses the platform's cryptographic RNG.
- Each call to `startLiveness()` generates a fresh session with a fresh nonce.
- The SDK does not cache or reuse nonces.

### Key Management

- The HMAC key is passed as a string in `VivdConfig.hmacKey`.
- The key must match between client and server.
- The key is stored in the app's memory during the SDK lifetime and released on `dispose()`.
- The key is NOT persisted to disk by the SDK.

**Recommendations:**

- Use a key of at least 32 bytes (256 bits) for adequate security.
- Rotate keys periodically.
- Do not hardcode the key in source code. Fetch it from a secure configuration service or use platform keychain storage.
- Consider using separate keys per environment (development, staging, production).

---

## Anti-Spoof Limitations

### Current Status: Basic Texture Analysis

The current `AntiSpoofEngine` (Phase 0-1) uses a simplified Laplacian texture variance heuristic. This is a minimal implementation and is **NOT sufficient for production anti-spoof requirements**.

**What it detects:**
- Low-texture screen replay attacks (uniform brightness, lack of skin micro-texture)

**What it does NOT detect:**
- High-resolution printed photographs
- Video replay attacks with realistic texture
- Deepfake or generative AI face swaps
- 3D mask attacks (silicone, resin, paper)
- Partial face attacks (photo with cutout eyes for blinking)

### Known Bypass Vectors

| Attack Type | Detected? | Notes |
|---|---|---|
| Low-res screen replay | Partial | Low texture variance may trigger, but not reliable |
| High-res screen replay | No | Screen textures are increasingly realistic |
| Printed photo (matte) | No | Paper has sufficient texture variance |
| Printed photo (glossy) | Partial | May detect uniform reflections |
| Video replay (phone) | No | Full texture and motion |
| Deepfake video | No | Texture analysis has no deepfake detection capability |
| 3D silicone mask | No | Realistic texture and 3D structure |
| Paper mask with eye holes | No | User can perform blink action through holes |

### Future: ML-Based PAD

Phase 3 plans to replace the texture heuristic with an ONNX/TFLite model trained on real vs. spoof datasets. This will significantly improve detection but still has limitations:

- ML PAD models generalize poorly across unknown attack types
- Models must be retrained periodically as attack methods evolve
- There is no single model that handles all attack types reliably
- Complementary methods (3D depth, infrared, liveness texture) are recommended for high-security applications

---

## Known Limitations

### No 3D Depth Analysis

Vivd relies entirely on 2D camera input. It cannot distinguish a flat surface (photo/screen) from a 3D face using depth cues. Depth sensing would require:

- Time-of-flight (ToF) sensors
- Structured light (Apple Face ID)
- Stereo camera systems
- LiDAR

### No Infrared Analysis

Vivd does not use infrared cameras or near-infrared imaging. IR analysis can detect:
- Printed photos (no IR reflectance from ink)
- Screen replay (no IR emission from LCD/OLED)
- 3D masks (different IR absorption than skin)

### No ML-Based Presentation Attack Detection

As described above, the current anti-spoof is a heuristic stub. Production deployments requiring anti-spoof should implement a complementary PAD solution.

### Liveness Challenges Are Predictable

The six challenge types (`blink`, `smile`, `headTurnLeft`, `headTurnRight`, `lookUp`, `lookDown`) are known and enumerable. An attacker could pre-record videos covering all possible combinations. Mitigations:

- Shuffle action order (already implemented via Fisher-Yates)
- Increase the number of actions required
- Use action combinations that are difficult to pre-record
- Add randomized timing between actions

### Euler Angle Accuracy Depends on ML Kit

Head pose estimation uses Google ML Kit's euler angle output. Accuracy varies with:
- Lighting conditions
- Face size in frame
- Partial occlusion
- Extreme angles (>30 degrees)

The `sensorOrientation` parameter corrects for front camera rotation but assumes a fixed orientation. Devices with non-standard sensor orientations may produce incorrect pose estimates.

### No Liveness Texture Analysis

Some advanced liveness systems analyze micro-texture patterns specific to live skin (blood flow, sweat, fine wrinkles). Vivd does not perform this level of analysis.

---

## Responsible Use

### Privacy Considerations

- All processing happens on-device. Camera frames are not transmitted to any server by the SDK.
- Face images are processed in memory and not persisted to disk by the SDK.
- The `FaceIdentity` store is in-memory only and is released when `Vivd.dispose()` is called.
- Applications using Vivd are responsible for their own data handling policies.

### Biometric Data Handling

Vivd processes biometric data (face images) for liveness verification. Applicable regulations may include:

- **GDPR** (EU) -- Special category data (biometric data) under Article 9
- **CCPA/CPRA** (California) -- Sensitive personal information
- **BIPA** (Illinois) -- Biometric Information Privacy Act requires notice and consent
- **PDPA** (Singapore, Thailand, etc.) -- Personal data protection
- **PIPL** (China) -- Personal Information Protection Law

Applications must:
- Obtain explicit user consent before collecting face data
- Provide clear notice of what biometric data is processed and why
- Offer a way to delete biometric data
- Not retain face images beyond the necessary processing period

### Demo and Watermark

The demo application includes a visual watermark on the camera preview. This is to prevent unauthorized use of the demo in production. The SDK itself does not add watermarks.

### Recommended Practices

1. **Combine with other verification methods.** Liveness detection alone is not sufficient for high-value transactions. Combine with:
   - Device attestation (SafetyNet / DeviceCheck)
   - Knowledge-based verification
   - Document verification
   - Multi-factor authentication

2. **Use server-side verification.** Always verify liveness results server-side using HMAC signing. Do not trust client-side results alone.

3. **Monitor for anomalies.** Track session metrics (duration, scores, failure rates) and flag suspicious patterns:
   - Consistently perfect scores (automated replay)
   - Very fast completion times
   - Repeated attempts from the same device

4. **Rate limit.** Limit the number of liveness attempts per device or per user to prevent brute-force attacks.

5. **Keep SDK updated.** Security improvements are released with each version. Track the changelog and update promptly.

---

## Reporting Vulnerabilities

If you discover a security vulnerability in Vivd, please report it responsibly.

### Reporting Process

1. **Do not open a public GitHub issue.** This exposes the vulnerability before it can be fixed.

2. **Send a report to the maintainers.** Preferred methods:
   - Open a **private fork** or use GitHub's **Security advisories** feature (if enabled on the repository)
   - Email the maintainers directly (check the package README for contact information)

3. **Include in your report:**
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)
   - Whether you plan to submit a pull request

4. **Responsible disclosure timeline:**
   - Acknowledgment within 48 hours
   - Initial assessment within 5 business days
   - Fix timeline communicated within 10 business days
   - Coordinated disclosure after fix is released

### Scope

Security reports should relate to:
- Bypass of liveness detection (photo/video replay, mask attacks)
- Session signing vulnerabilities
- Data leakage (face images, biometric data leaving device)
- Denial of service vectors
- Crash or memory safety issues

Out of scope:
- ML Kit vulnerabilities (report to Google)
- Flutter framework vulnerabilities (report to Flutter team)
- Camera plugin vulnerabilities (report to plugin maintainer)

### Security Updates

Security fixes will be released as patch versions following semantic versioning. Subscribe to the package on pub.dev to receive notifications of new releases.
