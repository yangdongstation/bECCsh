# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

bECCsh is a pure Bash implementation of elliptic curve cryptography (ECC) with zero external dependencies. The project demonstrates that complex cryptographic algorithms can be implemented entirely using Bash built-in functionality, including:

- Complete ECDSA (Elliptic Curve Digital Signature Algorithm) signing and verification
- Support for multiple standard curves: secp256r1, secp256k1, secp384r1, secp521r1
- Pure Bash big integer arithmetic (no `bc`, `awk`, or external tools)
- RFC 6979 deterministic k-value generation
- ASN.1 DER signature encoding
- 8-layer entropy collection system
- Side-channel attack mitigations

**⚠️ Important**: This is primarily an educational and proof-of-concept project. While cryptographically correct, it's 30,000-45,000x slower than OpenSSL. Use only for learning, research, or resource-constrained environments without access to standard crypto libraries.

## Quick Commands

### Building & Testing

```bash
# Run all tests
./becc.sh test -c secp256r1

# Run specific curve tests
./becc.sh test -c secp256k1

# Performance benchmarks (will take minutes)
./becc.sh benchmark -c secp256r1 -n 10

# Run test suite
bash tests/runnable_test.sh
```

### Development Operations

```bash
# Generate a key pair for testing
./becc.sh keygen -c secp256r1 -f test_key.pem

# Sign a message
./becc.sh sign -c secp256r1 -k test_key.pem -m "Hello World" -f signature.der

# Verify a signature
./becc.sh verify -c secp256r1 -k test_key_public.pem -m "Hello World" -s signature.der

# Show help
./becc.sh --help
```

## Project Structure

### Core Files

**Main Entry Point:**
- `becc.sh` - Main CLI tool with commands: keygen, sign, verify, test, benchmark

**Library Modules (in `lib/`):**
- `bash_math.sh` - Hex/decimal conversion and basic math functions
- `bigint.sh` - Pure Bash arbitrary-precision integer arithmetic
- `ec_curve.sh` - Elliptic curve parameter definitions and initialization
- `ec_point.sh` - Elliptic curve point operations (addition, doubling, scalar multiplication)
- `ecdsa.sh` - ECDSA signing and verification algorithms
- `entropy.sh` - Random number generation with 8 entropy sources
- `security.sh` - Security utilities (key management, memory clearing, timing attacks)
- `asn1.sh` - ASN.1 DER encoding for signatures

**Utilities:**
- `tools/security_functions.sh` - Additional key format handling
- `tools/fixed_pure_bash_hex.sh` - Hex conversion tools
- `tools/improved_random.sh` - Enhanced entropy collection

### Test Files (in `tests/`)

Various test scripts demonstrating functionality and validating against OpenSSL:
- `runnable_test.sh` - Core functionality tests
- `test_openssl_compatibility_final.sh` - Validation against OpenSSL
- `test_quick_functionality.sh` - Quick sanity checks
- `detailed_test_failure_analysis.sh` - Debugging test failures

### Documentation

**Learning Path (from beginner to expert):**
1. `index.html` - Interactive learning center with visual navigation
2. `MATH_CRYPTOGRAPHY_GUIDE.md` - Beginner-friendly cryptography guide (easy-to-understand concepts)
3. `MATHEMATICS_DEEP_FOUNDATIONS.md` - Knowledge evolution from problems to solutions (WHY things were invented)
4. `IMPLEMENTATION_GUIDE.md` - From math to code (HOW concepts translate to Bash implementation)
5. `beccsh/MATH_DOCUMENTATION.md` - Detailed elliptic curve mathematics (formal definitions)

**Supporting Documents:**
- `README.md` - Project overview and quick start
- `RELIABILITY_REPORT.md` - Quality assessment and test results
- `CRYPTOGRAPHIC_SECURITY_ANALYSIS.md` - Security analysis and limitations

## Key Architecture Patterns

### Module Organization

Each library module follows a consistent pattern:
1. Guard clause at top to prevent double-loading
2. Internal helper functions (prefixed with underscore)
3. Public API functions (named clearly with context prefix)
4. Error handling with meaningful return codes

Example from `bash_math.sh`:
```bash
if [[ -n "${BASH_MATH_LOADED:-}" ]]; then
    return 0
fi
readonly BASH_MATH_LOADED=1
```

### Big Integer Arithmetic

bECCsh implements arithmetic using string manipulation and positional notation:
- **Addition**: Digit-by-digit addition with carry propagation
- **Multiplication**: Partial products accumulated from individual digit products
- **Division**: Long division algorithm implemented character-by-character
- **Modular arithmetic**: Based on division remainder

No external tools are used; everything operates on bash variables and string expansion.

### Elliptic Curve Operations

The implementation follows standard ECC algorithms:
- **Point Addition**: Uses slope calculation and coordinate updates (Weierstrass form)
- **Point Doubling**: Special case of point addition when P = Q
- **Scalar Multiplication**: Binary expansion method with optional windowing optimization
- **Point Validation**: Verifies points satisfy the curve equation y² = x³ + ax + b

### ECDSA Implementation

Complete ECDSA flow:
1. **Key Generation**: Private key from entropy, public key via scalar multiplication
2. **Signing**: Hash message, generate RFC 6979 k-value, compute (r,s) signature components
3. **Verification**: Reconstruct point from signature components, validate against message hash
4. **RFC 6979**: Deterministic k-value prevents random number bias

### Entropy Collection (8 layers)

The entropy system uses multiple sources for randomness:
1. Keyboard timing (if interactive)
2. CPU cycle counters
3. System random devices (/dev/urandom, /dev/random)
4. Network interface statistics
5. Hardware random number generators (if available)
6. Process information
7. Timing measurements
8. System entropy pool

## Common Development Tasks

### Adding a New Curve

1. Define curve parameters in `lib/ec_curve.sh` in the `CURVES` associative array
2. Add initialization code to `curve_init()` function
3. Update curve validation in `curve_is_supported()`
4. Add test vectors to `tests/`

### Testing Changes

1. Run affected curve tests: `./becc.sh test -c secp256r1`
2. Verify OpenSSL compatibility: `tests/test_openssl_compatibility_final.sh`
3. Check memory and error conditions in `tests/detailed_test_failure_analysis.sh`

### Understanding Failures

- Check `LOG_DEBUG` level output: `./becc.sh -d [command]`
- Compare output with OpenSSL using test scripts
- Review `CRYPTOGRAPHIC_SECURITY_ANALYSIS.md` for known limitations
- Check integer precision issues (common with very large numbers)

### Learning the Implementation

**To understand how bECCsh works, follow this guided path:**

1. **Start with concepts** (`MATH_CRYPTOGRAPHY_GUIDE.md`)
   - Learn modular arithmetic, elliptic curves, point operations
   - Understand the "what" of cryptography
   - Best for: Getting basic intuition

2. **Understand the "why"** (`MATHEMATICS_DEEP_FOUNDATIONS.md`)
   - See how concepts evolved from solving real problems
   - Understand historical context (from 5000 BC to 2011)
   - Understand design decisions and trade-offs
   - Best for: Deep comprehension and research

3. **Connect theory to code** (`IMPLEMENTATION_GUIDE.md`)
   - See how each mathematical concept translates to Bash
   - View actual code snippets and implementations
   - Understand performance considerations
   - Best for: Code understanding and debugging

4. **Deep mathematical details** (`beccsh/MATH_DOCUMENTATION.md`)
   - Formal definitions and rigorous mathematics
   - Curve parameters and properties
   - Best for: Mathematical verification

**Example workflow for understanding point addition:**
```
1. Read "椭圆曲线运算" in MATH_CRYPTOGRAPHY_GUIDE.md
   → Learn the geometric concept and formula
2. Read "第三部分：椭圆曲线点操作" in MATHEMATICS_DEEP_FOUNDATIONS.md
   → Understand why this operation is defined this way
3. Read "第三部分：椭圆曲线点操作" in IMPLEMENTATION_GUIDE.md
   → See the actual `ec_point_add()` function in Bash
4. Study `lib/ec_point.sh` directly
   → Understand performance optimization tricks
```

## Important Implementation Details

### No External Dependencies

The project intentionally avoids:
- ❌ `bc` calculator (use `bash_math.sh` and `bigint.sh`)
- ❌ `awk` or `sed` (use bash string expansion)
- ❌ Python or other scripting languages
- ❌ External crypto libraries

### Bash Version Requirements

- Minimum: Bash 4.0+ (for associative arrays)
- Tested on: Bash 5.x
- Avoid: Non-standard bash extensions

### Performance Characteristics

- ✅ Suitable for: Educational use, algorithm visualization, emergency use without crypto libs
- ❌ Not suitable for: High-frequency operations, production crypto, time-sensitive applications
- Typical speeds:
  - Key generation: ~120 seconds
  - Signing: ~380 seconds
  - Verification: ~450 seconds
  - (1KB message on modern CPU)

### Security Considerations

- ✅ Correct cryptographic algorithms
- ✅ RFC 6979 deterministic k (prevents randomness bias)
- ✅ Constant-time comparison (where feasible in Bash)
- ⚠️ Bash limitations: Not immune to timing attacks, no process isolation
- ⚠️ Entropy: Depends on system entropy quality
- ⚠️ Not audited by professional security researchers

## Code Style & Conventions

### Naming Conventions

- **Global constants**: `UPPERCASE_WITH_UNDERSCORES`
- **Functions**: `module_function_name()` (e.g., `ecdsa_sign()`)
- **Internal functions**: `_private_function()`
- **Local variables**: `lowercase_with_underscores`
- **Curve-specific**: Prefix with curve name (e.g., `secp256r1_p`, `secp256k1_g`)

### Error Handling

- Return status codes (0 for success, non-zero for errors)
- Use `error_exit()` for fatal errors
- Log via `log()` function with appropriate level
- Validate input at function boundaries

### Comments

- Document non-obvious algorithms with references to standards (NIST, SEC2)
- Explain mathematical concepts briefly
- Include citations to papers or specifications where relevant
- Mark performance-critical sections

## Debugging & Troubleshooting

### Enable Debug Output

```bash
./becc.sh -d [command]  # Full debug output with set -x
./becc.sh -v [command]  # Verbose info logs
```

### Common Issues

1. **"bc not found" errors**: Ensure `bash_math.sh` and `bigint.sh` are loaded before use
2. **Signature mismatch with OpenSSL**: Check hash algorithm alignment and DER encoding
3. **Point validation failures**: Verify curve parameters loaded correctly via `curve_init()`
4. **Slow performance**: Expected; use smaller test vectors for development
5. **Integer overflow**: Bash arithmetic uses arbitrary precision in functions, verify against OpenSSL

### Validation Against OpenSSL

```bash
# Generate keys with openssl
openssl ecparam -genkey -name prime256v1 -out openssl_key.pem

# Compare with bECCsh
./becc.sh keygen -c secp256r1

# Test signature compatibility
bash tests/test_openssl_compatibility_final.sh
```

## References & Resources

### Key Documentation Files
- `MATH_DOCUMENTATION.md` - Elliptic curve mathematics details
- `CRYPTOGRAPHIC_SECURITY_ANALYSIS.md` - Security analysis and limitations
- `beccsh/README.md` - Detailed feature documentation

### External Standards
- FIPS 186-4: Digital Signature Standard (DSS)
- SEC 2: Recommended Elliptic Curve Domain Parameters
- RFC 6979: Deterministic ECDSA
- RFC 5480: ECC in X.509 certificates (key formats)

### Related Curves
- secp256r1 (P-256, prime256v1) - NIST standard
- secp256k1 - Bitcoin standard
- secp384r1 (P-384) - NIST standard
- secp521r1 (P-521) - NIST standard

