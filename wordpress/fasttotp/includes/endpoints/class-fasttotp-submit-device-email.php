<?php
/**
 * FastTOTP Submit Device and Email Endpoint
 *
 * Handles the REST API endpoint for submitting device information and email.
 *
 * @package FastTOTP
 */

/**
 * Class FastTOTP_Submit_Device_Email
 */
class FastTOTP_Submit_Device_Email {

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
     * Submit device and email endpoint handler
     *
     * @param WP_REST_Request $request The REST request object.
     * @return WP_REST_Response The REST response object.
     */
    public function handle_request($request) {
        $request_id = $request->get_header('totp_requestid');
        $encrypted_device_id = $request->get_header('totp_id');
        $encrypted_email = $request->get_header('totp_email');
        
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
        $email = $this->fasttotp->decrypt_with_rsa($encrypted_email, $private_key);
        
        // Validate that we have all required decrypted data
        if (empty($device_id) || empty($email)) {
            return new WP_REST_Response(array(
                'error' => __('Failed to decrypt required data', 'fasttotp')
            ));
        }
        
        // Find user
        $user = $email ? get_user_by('email', $email) : false;
        
        // Check IP rate limiting if user not found
        if (!$user) {
            // Get client IP address
            // Use the centralized IP blocking check method
            return $this->fasttotp->check_ip_blocking();
        }
        
        // Store user ID and device ID if found
        // Update in-memory store
        $this->fasttotp->request_store[$request_id]['user_id'] = $user->ID;
        $this->fasttotp->request_store[$request_id]['device_id'] = $device_id;
        $this->fasttotp->request_store[$request_id]['status'] = 'submitted';
        
        // Update transient storage for cross-request persistence
        $request_data = $this->fasttotp->request_store[$request_id];
        set_transient('fasttotp_request_' . $request_id, $request_data, 5 * MINUTE_IN_SECONDS);
        
        // Check if user_fasttotp_secret exists
        $user_fasttotp_secret = get_user_meta($user->ID, 'user_fasttotp_secret', true);
        
        // Prepare response data
        $response_data = array(
            'error' => '', // Empty string indicates success
            'name' => get_bloginfo('name'),
            'domain' => parse_url(home_url(), PHP_URL_HOST),
            'unique_id' => get_option('siteurl')
        );
        
        // Add secret field only if user_fasttotp_secret does not exist
        if (empty($user_fasttotp_secret)) {
            $response_data['secret'] = 'true'; // Whether to include secret in verification
        }
        
        return new WP_REST_Response($response_data);
    }
}