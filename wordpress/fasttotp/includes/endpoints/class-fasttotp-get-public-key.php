<?php
/**
 * FastTOTP Get Public Key Endpoint
 *
 * Handles the REST API endpoint for retrieving the public key.
 *
 * @package FastTOTP
 */

/**
 * Class FastTOTP_Get_Public_Key
 */
class FastTOTP_Get_Public_Key {
    
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
     * Get public key endpoint handler
     *
     * @param WP_REST_Request $request The REST request object.
     * @return WP_REST_Response The REST response object.
     */
    public function handle_request($request) {
        // Get request ID from header
        $request_id = $request->get_header('totp_requestid');
        
        // Initialize the request in request_store if request_id is provided
        if ($request_id) {
            // Use transients API to store request data for persistence across requests
            $request_data = array(
                'created_at' => time(),
                'status' => 'initialized',
                'user_id' => null
            );
            
            // Store in transients with 5 minute expiration
            set_transient('fasttotp_request_' . $request_id, $request_data, 5 * MINUTE_IN_SECONDS);
            
            // Also keep in memory for current request
            $this->fasttotp->request_store[$request_id] = $request_data;
        }
        
        return new WP_REST_Response(array(
            'key' => get_option('fasttotp_public_key', ''),
            'request_id' => $request_id,
        ));
    }
}