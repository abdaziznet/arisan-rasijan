
# Issue: `ERR_CONNECTION_REFUSED` on Email Confirmation

## Problem
After a user signs up and clicks the confirmation link in the email from Supabase, they are redirected to `localhost:3000` which shows an `ERR_CONNECTION_REFUSED` error.

This happens because the email confirmation link is configured to redirect to a frontend URL, which in this case is `localhost:3000`. The error indicates that there is no server running on that port to handle the request. For a Flutter web app, this means the local development server is not running.

## Solution
To fix this, you need to run the Flutter application in a web browser (like Chrome) before clicking the confirmation link. This will start the development server on a specific port (usually a random one, but it can be configured).

### Steps:
1.  **Run the app on the web:**
    Open your terminal in the project root and run:
    ```bash
    flutter run -d chrome --web-port 3000
    ```
    This command does two things:
    *   `flutter run -d chrome`: Compiles and runs your Flutter app in a Chrome browser.
    *   `--web-port 3000`: Forces the app to be served on `localhost:3000`.

2.  **Click the confirmation link:**
    Once the app is running in your browser, go back to your email and click the confirmation link again.

3.  **Check Supabase settings (if needed):**
    If it still doesn't work, you should verify the "Site URL" and "Redirect URLs" in your Supabase project's auth settings.
    *   Go to your Supabase Dashboard -> Authentication -> URL Configuration.
    *   **Site URL** should be `http://localhost:3000` for local development.
    *   **Additional Redirect URLs** should also include `http://localhost:3000/**`. The `/**` is important as a wildcard.

By ensuring the local server is running on the correct port, the redirect from Supabase will be handled correctly, and the user will be properly authenticated.
