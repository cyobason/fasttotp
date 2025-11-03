<?php
/**
 * FastTOTP Verify TOTP Code Endpoint
 *
 * Handles the REST API endpoint for verifying TOTP codes.
 *
 * @package FastTOTP
 */

/**
 * Class FastTOTP_Verify_TOTP_Code
 */
class FastTOTP_Verify_TOTP_Code {

    /**
     * The main FastTOTP instance.
     *
     * @var FastTOTP_WordPress
     */
    private $fasttotp;

    /**
     * Constructor
     *
     * @param FastTOTP_WordPress $fasttotp The main FastTOTP instance.
     */
    public function __construct($fasttotp) {
        $this->fasttotp = $fasttotp;
    }

    /**
     * Verify TOTP code endpoint handler
     *
     * @param WP_REST_Request $request The REST request object.
     * @return WP_REST_Response The REST response object.
     */
    public function handle_request($request) {
        $request_id = $request->get_header('totp_requestid');
        $encrypted_device_id = $request->get_header('totp_id');
        $encrypted_totp_code = $request->get_header('totp_code');
        $encrypted_email = $request->get_header('totp_email');
        $encrypted_secret = $request->get_header('totp_secret');
        
        // First check if request exists in memory
        $request_data = isset($this->fasttotp->request_store[$request_id]) ? $this->fasttotp->request_store[$request_id] : null;
        
        // If not in memory, try to get from transients (cross-request persistence)
        if (!$request_data) {
            $request_data = get_transient('fasttotp_request_' . $request_id);
        }
        
        // If we still don't have request data, it's invalid
        if (!$request_id || !$request_data) {
            return new WP_REST_Response(array(
                'error' => __('Invalid request ID', 'fasttotp')
            ));
        }
        
        // Update request data in memory
        $this->fasttotp->request_store[$request_id] = $request_data;
        
        // Get private key
        $private_key = get_option('fasttotp_private_key', '');
        
        // Decrypt all encrypted data except request_id
        $device_id = $this->fasttotp->decrypt_with_rsa($encrypted_device_id, $private_key);
        $totp_code = $this->fasttotp->decrypt_with_rsa($encrypted_totp_code, $private_key);
        $email = $this->fasttotp->decrypt_with_rsa($encrypted_email, $private_key);
        
        // Decrypt secret if provided
        $secret = !empty($encrypted_secret) ? $this->fasttotp->decrypt_with_rsa($encrypted_secret, $private_key) : null;
        
        // Validate that we have all required decrypted data
        if (empty($device_id) || empty($totp_code) || empty($email)) {
            return new WP_REST_Response(array(
                'error' => __('Failed to decrypt required data', 'fasttotp')
            ));
        }
        
        // Now validate the TOTP code using the secret
        $is_valid = false;
        
        // Get the secret key - prioritize the one from request if provided, otherwise get from user meta
        $used_secret = $secret;
        if (empty($used_secret) && $this->fasttotp->request_store[$request_id]['user_id']) {
            $used_secret = get_user_meta($this->fasttotp->request_store[$request_id]['user_id'], 'user_fasttotp_secret', true);
        }
        
        // Only verify if we have a secret
        if (!empty($used_secret)) {
            // Implement TOTP verification
            $is_valid = $this->verify_totp_code($totp_code, $used_secret);
        }
        
        if (!$is_valid) {
            // Call IP blocking check when TOTP code is invalid
            $blocking_response = $this->fasttotp->check_ip_blocking();
            if (!empty($blocking_response)) {
                return $blocking_response;
            }
            
            return new WP_REST_Response(array(
                'error' => __('Invalid TOTP code', 'fasttotp')
            ));
        }
        
        // Set status to verified if code is valid
        $this->fasttotp->request_store[$request_id]['status'] = 'verified';
        
        // Also update the transient with the new status
        set_transient('fasttotp_request_' . $request_id, $this->fasttotp->request_store[$request_id], 300); // Keep for 5 minutes
        
        // If we have a user ID, log them in
        if ($this->fasttotp->request_store[$request_id]['user_id']) {
            // If secret is provided, save it to user meta
            if (!empty($secret)) {
                update_user_meta($this->fasttotp->request_store[$request_id]['user_id'], 'user_fasttotp_secret', $secret);
            }
            
            // Create a secure token for the user
            $secure_token = wp_generate_password(32, true, true);
            update_user_meta($this->fasttotp->request_store[$request_id]['user_id'], 'fasttotp_token', $secure_token);
            set_transient('fasttotp_' . $request_id, $secure_token, 60); // Token valid for 60 seconds
        }
        
        return new WP_REST_Response(array(
            'error' => '' // Empty string indicates success
        ));
    }
    
    /**
     * Verify a TOTP code using the provided secret
     * 
     * @param string $totp_code The TOTP code to verify
     * @param string $secret The TOTP secret key
     * @return bool True if the code is valid, false otherwise
     */
    private function verify_totp_code($totp_code, $secret) {
        // Ensure code is 6 digits and secret is not empty
        if (!preg_match('/^[0-9]{6}$/', $totp_code) || empty($secret)) {
            return false;
        }
        
        // Get current timestamp divided by 30 seconds (TOTP time step)
        $time_step = 30;
        $timestamp = floor(time() / $time_step);
        
        // Handle time drift by checking current, previous, and next time windows
        for ($drift = -1; $drift <= 1; $drift++) {
            $adjusted_timestamp = $timestamp + $drift;
            
            // Convert timestamp to binary
            $timestamp_bin = pack('N', 0) . pack('N', $adjusted_timestamp);
            
            // If secret is base32 encoded, decode it
            // (Common format for TOTP secrets)
            if (preg_match('/^[A-Z2-7=]+$/i', $secret)) {
                $secret_decoded = $this->base32_decode($secret);
            } else {
                $secret_decoded = $secret;
            }
            
            // Generate HMAC-SHA1 hash
            $hash = hash_hmac('sha1', $timestamp_bin, $secret_decoded, true);
            
            // Extract a 4-byte binary from the hash
            $offset = ord($hash[19]) & 0x0F;
            $binary = (
                ((ord($hash[$offset]) & 0x7F) << 24) |
                ((ord($hash[$offset + 1]) & 0xFF) << 16) |
                ((ord($hash[$offset + 2]) & 0xFF) << 8) |
                (ord($hash[$offset + 3]) & 0xFF)
            );
            
            // Convert to 6-digit code
            $calculated_code = str_pad($binary % 1000000, 6, '0', STR_PAD_LEFT);
            
            // Compare with user provided code
            if ($calculated_code === $totp_code) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * Decode base32 encoded string
     * 
     * @param string $str Base32 encoded string
     * @return string Decoded binary data
     */
    private function base32_decode($str) {
        // Base32 decode implementation
        $base32chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
        $str = strtoupper(str_replace('=', '', $str));
        $result = '';
        $buffer = 0;
        $bits_left = 0;
        
        for ($i = 0; $i < strlen($str); $i++) {
            $char = $str[$i];
            $val = strpos($base32chars, $char);
            
            if ($val === false) {
                continue; // Skip invalid characters
            }
            
            $buffer = ($buffer << 5) | $val;
            $bits_left += 5;
            
            if ($bits_left >= 8) {
                $bits_left -= 8;
                $result .= chr(($buffer >> $bits_left) & 0xFF);
            }
        }
        
        return $result;
    }
}