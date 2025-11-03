<?php
/**
 * FastTOTP Check Login Status Endpoint
 *
 * Handles the REST API endpoint for checking login status.
 *
 * @package FastTOTP
 */

/**
 * Class FastTOTP_Check_Login_Status
 */
class FastTOTP_Check_Login_Status {

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
     * Check login status endpoint handler
     *
     * @param WP_REST_Request $request The REST request object.
     * @return WP_REST_Response The REST response object.
     */
    public function handle_request($request) {
        $request_id = $request->get_param('request_id');
        
        // First check if request exists in memory
        $request_data = isset($this->fasttotp->request_store[$request_id]) ? $this->fasttotp->request_store[$request_id] : null;
        
        // If not in memory, try to get from transients (cross-request persistence)
        if (!$request_data) {
            $request_data = get_transient('fasttotp_request_' . $request_id);
        }
        
        // If we still don't have request data, it's invalid
        if (!$request_id || !$request_data) {
            return new WP_REST_Response(array(
                'logged_in' => false
            ));
        }
        
        // Update request data in memory
        $this->fasttotp->request_store[$request_id] = $request_data;
        
        // Check if the request is verified and we have a token
        if ($this->fasttotp->request_store[$request_id]['status'] === 'verified' && $this->fasttotp->request_store[$request_id]['user_id']) {
            $token = get_transient('fasttotp_' . $request_id);
            $user_token = get_user_meta($this->fasttotp->request_store[$request_id]['user_id'], 'fasttotp_token', true);
            
            if ($token && $user_token && $token === $user_token) {
                // Log the user in
                wp_set_current_user($this->fasttotp->request_store[$request_id]['user_id']);
                wp_set_auth_cookie($this->fasttotp->request_store[$request_id]['user_id']);
                
                // Clean up
                delete_transient('fasttotp_' . $request_id);
                delete_user_meta($this->fasttotp->request_store[$request_id]['user_id'], 'fasttotp_token');
                // Reset failed attempts counter for successful user lookup
                $this->fasttotp->remove_failed_attempts_counter();
                
                return new WP_REST_Response(array(
                    'logged_in' => true
                ));
            }
        }
        
        return new WP_REST_Response(array(
            'logged_in' => false
        ));
    }
}