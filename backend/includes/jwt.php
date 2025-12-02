<?php
/**
 * JWT Helper Class
 * Handles JWT token generation and validation
 */

class JWT {
    // Secret key for signing tokens - CHANGE THIS IN PRODUCTION!
    private static $secret_key = "your-secret-key-change-this-in-production-2025";
    private static $algorithm = 'HS256';
    private static $token_expiry = 86400; // 24 hours in seconds

    /**
     * Generate JWT token
     * @param array $payload
     * @return string
     */
    public static function encode($payload) {
        $header = [
            'typ' => 'JWT',
            'alg' => self::$algorithm
        ];

        // Add issued at and expiration time
        $payload['iat'] = time();
        $payload['exp'] = time() + self::$token_expiry;

        // Encode header and payload
        $headerEncoded = self::base64UrlEncode(json_encode($header));
        $payloadEncoded = self::base64UrlEncode(json_encode($payload));

        // Create signature
        $signature = hash_hmac('sha256', "$headerEncoded.$payloadEncoded", self::$secret_key, true);
        $signatureEncoded = self::base64UrlEncode($signature);

        // Return complete token
        return "$headerEncoded.$payloadEncoded.$signatureEncoded";
    }

    /**
     * Decode and validate JWT token
     * @param string $token
     * @return array|false
     */
    public static function decode($token) {
        try {
            // Split token into parts
            $parts = explode('.', $token);
            
            if (count($parts) !== 3) {
                return false;
            }

            list($headerEncoded, $payloadEncoded, $signatureEncoded) = $parts;

            // Verify signature
            $signature = hash_hmac('sha256', "$headerEncoded.$payloadEncoded", self::$secret_key, true);
            $signatureCheck = self::base64UrlEncode($signature);

            if ($signatureEncoded !== $signatureCheck) {
                return false; // Invalid signature
            }

            // Decode payload
            $payload = json_decode(self::base64UrlDecode($payloadEncoded), true);

            // Check expiration
            if (isset($payload['exp']) && $payload['exp'] < time()) {
                return false; // Token expired
            }

            return $payload;
        } catch (Exception $e) {
            return false;
        }
    }

    /**
     * Get token from request headers
     * @return string|null
     */
    public static function getBearerToken() {
        $headers = self::getAuthorizationHeader();
        
        if (!empty($headers)) {
            if (preg_match('/Bearer\s(\S+)/', $headers, $matches)) {
                return $matches[1];
            }
        }
        
        return null;
    }

    /**
     * Get Authorization header
     * @return string|null
     */
    private static function getAuthorizationHeader() {
        $headers = null;
        
        if (isset($_SERVER['Authorization'])) {
            $headers = trim($_SERVER['Authorization']);
        } elseif (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $headers = trim($_SERVER['HTTP_AUTHORIZATION']);
        } elseif (function_exists('apache_request_headers')) {
            $requestHeaders = apache_request_headers();
            $requestHeaders = array_combine(
                array_map('ucwords', array_keys($requestHeaders)),
                array_values($requestHeaders)
            );
            
            if (isset($requestHeaders['Authorization'])) {
                $headers = trim($requestHeaders['Authorization']);
            }
        }
        
        return $headers;
    }

    /**
     * Base64 URL encode
     * @param string $data
     * @return string
     */
    private static function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Base64 URL decode
     * @param string $data
     * @return string
     */
    private static function base64UrlDecode($data) {
        return base64_decode(strtr($data, '-_', '+/'));
    }
}
