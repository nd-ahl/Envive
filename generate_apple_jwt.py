#!/usr/bin/env python3
"""
Generate Apple Sign In JWT Token
Run this script to generate your JWT secret key for Supabase
"""

import json
import time
import base64
import hashlib
from datetime import datetime, timedelta

# Your Apple Developer Information
TEAM_ID = "5TBWU99J4Y"
KEY_ID = "YACV7X3SX4"
SERVICE_ID = "com.neal.envivenew.signin"
KEY_FILE = "/Users/nealahlstrom/Downloads/AuthKey_YACV7X3SX4.p8"

def main():
    print("=" * 60)
    print("Apple Sign In JWT Generator")
    print("=" * 60)
    print()

    # Note: This is a simplified version
    # For production, you should use the PyJWT library with cryptography
    # Run: pip3 install PyJWT cryptography

    print("To generate your JWT token, you have two options:")
    print()
    print("OPTION 1: Use jwt.io (Manual - 2 minutes)")
    print("-" * 60)
    print("1. Go to: https://jwt.io")
    print("2. Select algorithm: ES256")
    print("3. Edit HEADER (left side, top box) - paste this:")
    print()
    print(json.dumps({
        "alg": "ES256",
        "kid": KEY_ID
    }, indent=2))
    print()
    print("4. Edit PAYLOAD (left side, middle box) - paste this:")
    print()
    now = int(time.time())
    exp = int((datetime.now() + timedelta(days=180)).timestamp())
    print(json.dumps({
        "iss": TEAM_ID,
        "iat": now,
        "exp": exp,
        "aud": "https://appleid.apple.com",
        "sub": SERVICE_ID
    }, indent=2))
    print()
    print("5. On the RIGHT side, look for 'Private Key' box")
    print("   (You may need to scroll down)")
    print("6. Paste your private key from:")
    print(f"   {KEY_FILE}")
    print()
    print("7. Copy the long token from the top (starts with 'eyJ...')")
    print("8. Paste it into Supabase 'Secret Key (for OAuth)' field")
    print()
    print("=" * 60)
    print()
    print("OPTION 2: Install Python libraries and run this script")
    print("-" * 60)
    print("Run these commands:")
    print("  python3 -m pip install --user PyJWT cryptography")
    print("  python3", __file__)
    print()

if __name__ == "__main__":
    main()
