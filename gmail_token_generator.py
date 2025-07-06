#!/usr/bin/env python3
"""
Gmail OAuth2 Token Generator
Generates refresh_token for Gmail API access
"""

import json
import webbrowser
from urllib.parse import urlparse, parse_qs
from http.server import HTTPServer, BaseHTTPRequestHandler
import requests
import threading
import time

# Configuration - Using Gmail Token Generator credentials
CLIENT_ID = "1059917372502-qb8ivqvhhh2h3iqbh357h0hekb5qdtrg.apps.googleusercontent.com"
CLIENT_SECRET = "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"
REDIRECT_URI = "http://localhost:8080"
SCOPES = "https://www.googleapis.com/auth/gmail.send"

# Global variable to store authorization code
auth_code = None
server_running = True

class AuthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global auth_code, server_running
        
        if self.path.startswith('/?code='):
            # Extract authorization code
            parsed_url = urlparse(self.path)
            query_params = parse_qs(parsed_url.query)
            auth_code = query_params.get('code', [None])[0]
            
            # Send success response
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            success_html = """
            <html>
            <head><title>Authorization Successful</title></head>
            <body style="font-family: Arial; text-align: center; padding: 50px;">
                <h1 style="color: green;">✅ Authorization Successful!</h1>
                <p>You can close this window and return to the terminal.</p>
                <p>The refresh token will be generated shortly...</p>
            </body>
            </html>
            """
            self.wfile.write(success_html.encode())
            
            # Stop server after successful auth
            threading.Timer(1.0, self.shutdown_server).start()
        else:
            self.send_response(404)
            self.end_headers()
    
    def shutdown_server(self):
        global server_running
        server_running = False
    
    def log_message(self, format, *args):
        # Suppress server logs
        pass

def get_authorization_url():
    """Generate OAuth2 authorization URL"""
    auth_url = (
        f"https://accounts.google.com/o/oauth2/auth?"
        f"client_id={CLIENT_ID}&"
        f"redirect_uri={REDIRECT_URI}&"
        f"scope={SCOPES}&"
        f"response_type=code&"
        f"access_type=offline&"
        f"prompt=consent"
    )
    return auth_url

def exchange_code_for_tokens(auth_code):
    """Exchange authorization code for access and refresh tokens"""
    token_url = "https://oauth2.googleapis.com/token"
    
    data = {
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'code': auth_code,
        'grant_type': 'authorization_code',
        'redirect_uri': REDIRECT_URI
    }
    
    response = requests.post(token_url, data=data)
    return response.json()

def main():
    print("🚀 Gmail OAuth2 Token Generator")
    print("=" * 50)
    
    # Start local server
    server = HTTPServer(('localhost', 8080), AuthHandler)
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()
    
    print("📡 Local server started on http://localhost:8080")
    
    # Generate and open authorization URL
    auth_url = get_authorization_url()
    print(f"🌐 Opening authorization URL...")
    print(f"📋 URL: {auth_url}")
    
    webbrowser.open(auth_url)
    
    print("\n⏳ Waiting for authorization...")
    print("   Please complete the authorization in your browser...")
    
    # Wait for authorization code
    timeout = 300  # 5 minutes timeout
    start_time = time.time()
    
    while auth_code is None and (time.time() - start_time) < timeout:
        time.sleep(1)
    
    server.shutdown()
    
    if auth_code is None:
        print("❌ Authorization timed out or failed!")
        return
    
    print(f"✅ Authorization code received!")
    print("🔄 Exchanging code for tokens...")
    
    # Exchange code for tokens
    token_response = exchange_code_for_tokens(auth_code)
    
    if 'error' in token_response:
        print(f"❌ Error getting tokens: {token_response}")
        return
    
    # Extract tokens
    access_token = token_response.get('access_token')
    refresh_token = token_response.get('refresh_token')
    
    if not refresh_token:
        print("❌ No refresh token received! Make sure you used 'access_type=offline' and 'prompt=consent'")
        return
    
    print("\n🎉 SUCCESS! Tokens generated:")
    print("=" * 50)
    print(f"📧 Access Token: {access_token[:50]}...")
    print(f"🔄 Refresh Token: {refresh_token}")
    print("=" * 50)
    
    # Save tokens to file
    tokens = {
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "refresh_token": refresh_token,
        "access_token": access_token,
        "type": "authorized_user"
    }
    
    with open('gmail_credentials.json', 'w') as f:
        json.dump(tokens, f, indent=2)
    
    print("💾 Tokens saved to 'gmail_credentials.json'")
    print("\n🚀 You can now use these credentials in your Flutter app!")
    
    # Show Flutter integration example
    print("\n📱 For Flutter integration:")
    print(f"   CLIENT_ID: {CLIENT_ID}")
    print(f"   CLIENT_SECRET: {CLIENT_SECRET}")
    print(f"   REFRESH_TOKEN: {refresh_token}")

if __name__ == "__main__":
    main()
