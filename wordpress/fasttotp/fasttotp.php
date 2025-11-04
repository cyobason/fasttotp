<?php
/*
Plugin Name: FastTOTP
Description: No registration, no password – Minimalist QR code login: Scan, verify, log in fast. Integrates FastTOTP app with WordPress for secure QR code authentication.
Version: 1.0
Requires at least: 5.8
Requires PHP: 7.2
Author: Cyobason
Author URI: https://github.com/cyobason/fasttotp
License: GPLv2 or later
Text Domain: fasttotp
*/

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly
}

// Include REST API endpoint classes
require_once plugin_dir_path(__FILE__) . 'includes/endpoints/endpoints-loader.php';

/**
 * FastTOTP WordPress Plugin
 *
 * Integrates FastTOTP app with WordPress for QR code based authentication.
 */
class FastTOTP_WordPress {
    private static $instance = null;
    public $request_store = array();
    
    /**
     * REST endpoint instances.
     *
     * @var array
     */
    private $endpoints = array();
    
    /**
     * Get singleton instance
     */
    public static function get_instance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * Constructor
     */
    private function __construct() {
        $this->init_hooks();
    }
    
    /**
     * Load plugin translations
     */
    public function load_textdomain() {
        load_plugin_textdomain('fasttotp', false, dirname(plugin_basename(__FILE__)) . '/languages');
    }
    
    /**
     * Replace standard WordPress login form with only FastTOTP login
     * This method replaces only the #loginform element with our QR code login form
     * Used with login_footer action to ensure DOM is fully loaded before manipulation
     */
    public function replace_standard_login_form() {
        // Add JavaScript to replace #loginform element with our QR code login using jQuery
        $ajax_url = esc_url(admin_url('admin-ajax.php?action=fasttotp_get_qr_login'));
        $check_url = esc_url(rest_url('fasttotp/v1/check'));
        $status_text = __('Please scan the QR code with your FastTOTP app', 'fasttotp');
        
        echo <<<JS
<script>
jQuery(document).ready(function($) {
    // Get the login form element using jQuery
    var _loginForm = $('#loginform');
    
    // Only proceed if login form exists
    if (_loginForm.length) {
        // Fetch our QR code login HTML via jQuery AJAX
        $.ajax({
            url: "$ajax_url",
            type: "GET",
            dataType: "html",
            success: function(response) {
                // Replace the entire login form element with our QR code login
                _loginForm.replaceWith(response);
                
                // Initialize FastTOTP login functionality after form replacement
                if (typeof window.FastTOTP !== 'undefined') {
                    window.FastTOTP.initLogin({
                        checkUrl: "$check_url",
                        statusText: "$status_text"
                    });
                }
            }
        });
    }
});
</script>
JS;
    }
    
    /**
     * Initialize hooks and actions
     * Sets up all necessary WordPress hooks for FastTOTP functionality
     */
    private function init_hooks() {
        // Check if FastTOTP is enabled before adding login form
        $enabled = get_option('fasttotp_enabled', true);
        $only = get_option('fasttotp_only', false);
        
        if ($enabled) {
            // Register login JavaScript file on login page
            add_action('login_enqueue_scripts', array($this, 'enqueue_login_scripts'));
            
            // If only FastTOTP login is allowed, replace the standard login form
            if ($only) {
                // To properly replace the login form, use login_footer action to ensure DOM is fully loaded
                add_action('login_footer', array($this, 'replace_standard_login_form'), 99);
            } else {
                // Add FastTOTP login form to WordPress login page normally
                add_action('login_form', array($this, 'add_qr_code_login'));
                // Initialize login script for normal login form
                add_action('login_footer', array($this, 'render_qr_code_login_script'), 99);
            }
        }
        
        // Register AJAX action for fetching QR code login form
        add_action('wp_ajax_fasttotp_get_qr_login', array($this, 'get_qr_code_login_ajax')); // For authenticated users
        add_action('wp_ajax_nopriv_fasttotp_get_qr_login', array($this, 'get_qr_code_login_ajax')); // For non-authenticated users
        
        // Register AJAX action for getting new QR code
        add_action('wp_ajax_fasttotp_get_qr_code', array($this, 'get_qr_code_ajax')); // For authenticated users
        add_action('wp_ajax_nopriv_fasttotp_get_qr_code', array($this, 'get_qr_code_ajax')); // For non-authenticated users
        
        // Register REST API endpoints for FastTOTP authentication
        add_action('rest_api_init', array($this, 'register_rest_endpoints'));
        
        // Add admin settings page
        add_action('admin_menu', array($this, 'add_admin_menu'));
        add_action('admin_init', array($this, 'register_settings'));
        // Register handle_key_generation directly in init_hooks
        add_action('admin_init', array($this, 'handle_key_generation'));
        
        // Load text domain for translations
        add_action('plugins_loaded', array($this, 'load_textdomain'));
    }
    
    /**
     * Enqueue JavaScript files for login page
     * Used to register the FastTOTP login JavaScript file
     */
    public function enqueue_login_scripts() {
        wp_enqueue_script('fasttotp-login', plugin_dir_url(__FILE__) . 'js/fasttotp-login.js', array(), '1.0.0', true);
    }
    
    /**
     * Add QR code login to WordPress login form
     */
    public function add_qr_code_login() {
        $this->render_qr_code_login();
    }
    
    /**
     * Render QR code login form
     * This is used both for the normal login form insertion and the AJAX replacement
     */
    private function render_qr_code_login() {
        // Generate request_id and QR code URL directly in PHP
        $request_id = $this->generate_request_id();
        $base_url = rest_url('fasttotp/v1');
        $qr_code_url = add_query_arg(array('request_id' => $request_id), $base_url);
        
        // Store request_id for later verification
        $this->store_request($request_id);
        
        // Store request in transient with 5 minute expiration
        $request_data = $this->request_store[$request_id];
        set_transient('fasttotp_request_' . $request_id, $request_data, 5 * MINUTE_IN_SECONDS);
        
        // Generate QR code image URL directly
        $qr_code_image = 'https://api.qrserver.com/v1/create-qr-code/?data=' . urlencode($qr_code_url) . '&size=200x200';
        
        // Add CSS styles
        echo '<style>';
        echo '.fasttotp-login-section { margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; background-color: #f8f9fa; }';
        echo '.fasttotp-login-section h2 { margin-top: 0; text-align: center; color: #23282d; }';
        echo '.fasttotp-login-section p { text-align: center; margin-bottom: 20px; }';
        echo '.fasttotp-qr-container { text-align: center; margin: 20px 0; }';
        echo '.fasttotp-qr-code { margin: 0 auto; padding: 10px; background: white; border-radius: 5px; display: inline-block; }';
        echo '#fasttotp-status { text-align: center; margin-top: 10px; font-weight: bold; }';
        echo '#fasttotp-countdown { text-align: center; margin-top: 5px; color: #666; }';
        echo '.fasttotp-refresh-btn { text-align: center; margin-top: 15px; }';
        echo '.fasttotp-refresh-btn button { padding: 8px 16px; background-color: #0073aa; color: white; border: none; border-radius: 4px; cursor: pointer; }';
        echo '.fasttotp-refresh-btn button:hover { background-color: #005177; }';
        echo '.login form { margin-top: 20px; }';
        echo '</style>';
        
        // Store request ID in a data attribute for JS access
        echo '<div class="fasttotp-login-section" data-request-id="' . esc_attr($request_id) . '" data-created-at="' . time() . '">';
        echo '<h2>' . __('FastTOTP Scan Login', 'fasttotp') . '</h2>';
        echo '<div class="fasttotp-qr-container">';
        echo '<div class="fasttotp-qr-code">';
        // Use generated QR code image directly
        echo '<img id="fasttotp-qr-image" src="' . esc_url($qr_code_image) . '" alt="FastTOTP Login QR Code" />';
        echo '</div>';
        echo '</div>';
        echo '<div id="fasttotp-status"></div>';
        echo '<div id="fasttotp-countdown"></div>';
        echo '<div class="fasttotp-refresh-btn" style="display: none;">';
        echo '<button id="fasttotp-refresh-qr">' . __('Refresh QR Code', 'fasttotp') . '</button>';
        echo '</div>';
        echo '</div>';
        
        // Store request ID in a global variable for the footer script
        echo '<script>';
        echo 'var fasttotpCurrentRequestId = "' . esc_js($request_id) . '";';
        echo 'var fasttotpQRCodeExpiry = 300; // 5 minutes in seconds';
        echo 'var fasttotpQRCodeCreated = ' . time() . ';';
        echo '</script>';
    }
    
    /**
     * Initialize FastTOTP login JavaScript
     * This method initializes the login functionality for normal login form
     * Used when fasttotp_enabled is true and fasttotp_only is false
     */
    public function render_qr_code_login_script() {
        $check_url = esc_url(rest_url('fasttotp/v1/check'));
        $status_text = __('Please scan the QR code with your FastTOTP app', 'fasttotp');
        
        // Initialize FastTOTP login with required options
        echo <<<JS
<script>
// Initialize FastTOTP login when document is ready
jQuery(document).ready(function() {
    if (typeof window.FastTOTP !== 'undefined') {
        window.FastTOTP.initLogin({
            checkUrl: "$check_url",
            statusText: "$status_text"
        });
    }
});
</script>
JS;
    }
    
    /**
     * Handle AJAX request for QR code login form
     * This is used when replacing the standard login form completely
     */
    public function get_qr_code_login_ajax() {
        $this->render_qr_code_login();
        wp_die(); // Required to terminate the AJAX request
    }
    
    /**
     * Handle AJAX request for getting a new QR code
     * Returns JSON response with new request_id and QR code
     */
    public function get_qr_code_ajax() {
        // No nonce verification to allow non-logged in users to refresh QR codes
        
        // Generate new request ID
        $request_id = $this->generate_request_id();
        
        // Store request with 5 minute expiration
        $request_data = array(
            'created_at' => time(),
            'status' => 'pending',
            'user_id' => null
        );
        
        // Store request in memory
        $this->store_request($request_id);
        $this->request_store[$request_id] = $request_data;
        
        // Store in transient with 5 minute expiration
        set_transient('fasttotp_request_' . $request_id, $request_data, 5 * MINUTE_IN_SECONDS);
        
        // Generate QR code content
        $base_url = rest_url('fasttotp/v1');
        $qr_code_url = add_query_arg(array('request_id' => $request_id), $base_url);
        
        // Generate QR code image URL
        $qr_code_image = 'https://api.qrserver.com/v1/create-qr-code/?data=' . urlencode($qr_code_url) . '&size=200x200';
        
        // Prepare response data
        $response = array(
            'success' => true,
            'data' => array(
                'request_id' => $request_id,
                'qr_code' => $qr_code_image,
                'expiry_time' => 300, // 5 minutes in seconds
                'created_at' => time()
            )
        );
        
        // Send JSON response
        wp_send_json($response);
    }
    
    /**
     * Generate unique request ID
     */
    private function generate_request_id() {
        return wp_generate_uuid4();
    }
    
    /**
     * Store request ID in memory
     */
    public function store_request($request_id) {
        $this->request_store[$request_id] = array(
            'created_at' => time(),
            'status' => 'pending',
            'user_id' => null
        );
    }
    
    /**
     * Register REST API endpoints
     */
    public function register_rest_endpoints() {
        // Initialize endpoint instances
        $this->endpoints['get_public_key'] = new FastTOTP_Get_Public_Key($this);
        $this->endpoints['submit_device_email'] = new FastTOTP_Submit_Device_Email($this);
        $this->endpoints['verify_totp_code'] = new FastTOTP_Verify_TOTP_Code($this);
        $this->endpoints['check_login_status'] = new FastTOTP_Check_Login_Status($this);
        
        // Get public key endpoint
        register_rest_route('fasttotp/v1', '/get_public_key', array(
            'methods' => 'GET',
            'callback' => array($this->endpoints['get_public_key'], 'handle_request'),
            'permission_callback' => '__return_true'
        ));
        
        // Submit device and email endpoint
        register_rest_route('fasttotp/v1', '/submit', array(
            'methods' => 'POST',
            'callback' => array($this->endpoints['submit_device_email'], 'handle_request'),
            'permission_callback' => '__return_true'
        ));
        
        // Verify TOTP code endpoint
        register_rest_route('fasttotp/v1', '/verify', array(
            'methods' => 'POST',
            'callback' => array($this->endpoints['verify_totp_code'], 'handle_request'),
            'permission_callback' => '__return_true'
        ));
        
        // Check login status endpoint
        register_rest_route('fasttotp/v1', '/check', array(
            'methods' => 'GET',
            'callback' => array($this->endpoints['check_login_status'], 'handle_request'),
            'permission_callback' => '__return_true'
        ));
    }
    
    /**
     * Decrypt data using RSA private key
     * 
     * @param string $encrypted_data Encrypted data (Base64 encoded)
     * @param string $private_key RSA private key
     * @return string Decrypted data, empty string on decryption failure
     */
    function decrypt_with_rsa($encrypted_data, $private_key){
        $privateKeyResource = openssl_pkey_get_private($private_key);
        $encryptedData = base64_decode($encrypted_data);
        openssl_private_decrypt(
            $encryptedData,
            $decryptedData,
            $privateKeyResource,
            OPENSSL_PKCS1_OAEP_PADDING
        );
        openssl_free_key($privateKeyResource);
        return $decryptedData;
    }

    /**
     * Add admin menu
     */
    public function add_admin_menu() {
        add_options_page(
            __('FastTOTP Settings', 'fasttotp'),
            'FastTOTP',
            'manage_options',
            'fasttotp',
            array($this, 'render_settings_page')
        );
    }
    
    /**
     * Register settings
     */
    public function register_settings() {
        register_setting('fasttotp', 'fasttotp_enabled', array(
            'type' => 'boolean',
            'default' => true
        ));
        
        register_setting('fasttotp', 'fasttotp_only', array(
            'type' => 'boolean',
            'default' => false
        ));
        
        // Register RSA key settings with custom sanitization to preserve existing values
        register_setting('fasttotp', 'fasttotp_public_key', array(
            'type' => 'string',
            'default' => '',
            'sanitize_callback' => function($input) {
                // If the input is empty but we have an existing key, keep the existing key
                if (empty($input)) {
                    $existing_key = get_option('fasttotp_public_key', '');
                    if (!empty($existing_key)) {
                        return $existing_key;
                    }
                }
                return sanitize_textarea_field($input);
            }
        ));
        
        register_setting('fasttotp', 'fasttotp_max_attempts', array(
            'type' => 'integer',
            'default' => 10,
            'sanitize_callback' => function($input) {
                // Ensure the value is a positive integer
                $value = intval($input);
                return max(1, $value);
            }
        ));
        
        register_setting('fasttotp', 'fasttotp_private_key', array(
            'type' => 'string',
            'default' => '',
            'sanitize_callback' => function($input) {
                // If the input is empty but we have an existing key, keep the existing key
                if (empty($input)) {
                    $existing_key = get_option('fasttotp_private_key', '');
                    if (!empty($existing_key)) {
                        return $existing_key;
                    }
                }
                return sanitize_textarea_field($input);
            }
        ));
        
        add_settings_section(
            'fasttotp_main',
            __('Main Settings', 'fasttotp'),
            array($this, 'render_settings_section'),
            'fasttotp'
        );
        
        add_settings_section(
            'fasttotp_keys',
            __('RSA Key Settings', 'fasttotp'),
            array($this, 'render_keys_section'),
            'fasttotp'
        );
        
        add_settings_field(
            'fasttotp_enabled',
            __('Enable FastTOTP', 'fasttotp'),
            array($this, 'render_enabled_field'),
            'fasttotp',
            'fasttotp_main'
        );
        
        add_settings_field(
            'fasttotp_only',
            __('Only allow FastTOTP login', 'fasttotp'),
            array($this, 'render_only_field'),
            'fasttotp',
            'fasttotp_main'
        );
        
        add_settings_field(
            'fasttotp_max_attempts',
            __('Maximum login attempts before IP block', 'fasttotp'),
            array($this, 'render_max_attempts_field'),
            'fasttotp',
            'fasttotp_main'
        );
        
        add_settings_field(
            'fasttotp_generate_keys',
            __('Generate RSA Keys', 'fasttotp'),
            array($this, 'render_generate_keys_field'),
            'fasttotp',
            'fasttotp_keys'
        );
        
        add_settings_field(
            'fasttotp_public_key_display',
            __('Public Key', 'fasttotp'),
            array($this, 'render_public_key_field'),
            'fasttotp',
            'fasttotp_keys'
        );
        
        // Add a hidden field for the private key to ensure it's included in the form submission
        add_settings_field(
            'fasttotp_private_key_hidden',
            '',
            function() {
                $private_key = get_option('fasttotp_private_key', '');
                echo '<input type="hidden" name="fasttotp_private_key" value="' . esc_attr($private_key) . '" />';
            },
            'fasttotp',
            'fasttotp_keys'
        );
    }
    
    /**
     * Render max attempts field
     */
    public function render_max_attempts_field() {
        $max_attempts = get_option('fasttotp_max_attempts', 10);
        echo '<input type="number" name="fasttotp_max_attempts" value="' . esc_attr($max_attempts) . '" min="1" max="100" />';
        echo '<p class="description">' . __('Set the maximum number of failed login attempts allowed before an IP address is temporarily blocked.', 'fasttotp') . '</p>';
    }
    
    /**
     * Check and handle IP blocking based on failed attempts
     * 
     * @param string $ip The IP address to check (optional, defaults to current client IP)
     * @return WP_REST_Response|null Returns a WP_REST_Response with error if blocked or near blocking, null otherwise
     */
    public function check_ip_blocking($ip = null) {
        // Use provided IP or get current client IP
        $client_ip = $ip ?: $_SERVER['REMOTE_ADDR'];
        
        // Get current failed attempts count for this IP
        $failed_attempts = get_transient('fasttotp_failed_attempts_' . $client_ip) ?: 0;
        $failed_attempts++;
        
        // Store updated failed attempts count with expiration
        set_transient('fasttotp_failed_attempts_' . $client_ip, $failed_attempts, HOUR_IN_SECONDS);
        
        // Check if IP should be blocked
        $blocked = get_transient('fasttotp_blocked_ip_' . $client_ip);
        
        if ($blocked) {
            // IP is already blocked
            return new WP_REST_Response(array(
                'error' => __('Your IP is temporarily blocked due to too many failed attempts. Please try again later.', 'fasttotp'),
            ));
        }
        
        // Get max attempts from settings
        $max_attempts = get_option('fasttotp_max_attempts', 10);
        
        // Block IP if too many failed attempts
        if ($failed_attempts >= $max_attempts) {
            set_transient('fasttotp_blocked_ip_' . $client_ip, true, 30 * MINUTE_IN_SECONDS); // Block for 30 minutes
            
            return new WP_REST_Response(array(
                'error' => __('Your IP has been temporarily blocked due to too many failed attempts. Please try again in 30 minutes.', 'fasttotp'),
            ));
        }
        
        // Return error message with remaining attempts
        $remaining_attempts = $max_attempts - $failed_attempts;
        return new WP_REST_Response(array(
            'error' => sprintf(__('User not found. You have %d attempts remaining before your IP is temporarily blocked.', 'fasttotp'), $remaining_attempts),
        ));
    }

    /**
     * Reset failed attempts counter for successful user lookup
     */
    public function remove_failed_attempts_counter(){
        $client_ip = $_SERVER['REMOTE_ADDR'];
        delete_transient('fasttotp_failed_attempts_' . $client_ip);
    }
    
    /**
     * Clear all FastTOTP related transients
     * Removes all transients with the 'fasttotp_' prefix
     */
    public function clear_all_fasttotp_transients() {
        global $wpdb;
        
        // Get all transient keys with the fasttotp_ prefix
        $prefix = '_transient_';
        $wildcard = $prefix . 'fasttotp_%';
        
        // Query the database for matching transients
        $transient_keys = $wpdb->get_col(
            $wpdb->prepare("SELECT option_name FROM $wpdb->options WHERE option_name LIKE %s", $wildcard)
        );
        
        // Also get the expired transient versions
        $expired_wildcard = $prefix . 'timeout_fasttotp_%';
        $expired_transient_keys = $wpdb->get_col(
            $wpdb->prepare("SELECT option_name FROM $wpdb->options WHERE option_name LIKE %s", $expired_wildcard)
        );
        
        // Combine all transient keys
        $all_transient_keys = array_merge($transient_keys, $expired_transient_keys);
        
        // Delete each transient
        foreach ($all_transient_keys as $key) {
            delete_option($key);
        }
        
        // Return the number of transients cleared
        return count($all_transient_keys);
    }
    
    /**
     * Render settings page
     */
    public function render_settings_page() {
        if (!current_user_can('manage_options')) {
            wp_die(__('You do not have sufficient permissions to access this page.'));
        }
        
        echo '<div class="wrap">';
        echo '<h1>' . __('FastTOTP Settings', 'fasttotp') . '</h1>';
        echo '<form method="post" action="options.php">';
        settings_fields('fasttotp');
        do_settings_sections('fasttotp');
        submit_button();
        echo '</form>';
        echo '</div>';
    }
    
    /**
     * Render settings section
     */
    public function render_settings_section() {
        echo '<p>' . __('Configure FastTOTP authentication settings for your WordPress site.', 'fasttotp') . '</p>';
    }
    
    /**
     * Render keys section
     */
    public function render_keys_section() {
        echo '<p>' . __('Generate and manage RSA keys for secure authentication.', 'fasttotp') . '</p>';
        
        // Check if we just generated keys and show success message
        if (get_transient('fasttotp_keys_generated')) {
            // Display success message
            echo '<div class="updated"><p>' . __('RSA keys generated successfully!', 'fasttotp') . '</p></div>';
            // Delete the transient so message doesn't show on next page load
            delete_transient('fasttotp_keys_generated');
        }
        
        // Check if there was an error generating keys
        if (get_transient('fasttotp_key_generation_error')) {
            // Display error message
            echo '<div class="error"><p>' . __('Failed to generate RSA keys. Please check your server configuration and PHP OpenSSL extension.', 'fasttotp') . '</p></div>';
            // Delete the transient so message doesn't show on next page load
            delete_transient('fasttotp_key_generation_error');
        }
    }
    
    /**
     * Generate RSA key pair
     */
    private function generate_rsa_keys() {
        // Check if OpenSSL is available
        if (!function_exists('openssl_pkey_new')) {
            error_log('FastTOTP: OpenSSL functions are not available. Cannot generate RSA keys.');
            return;
        }
        
        $config = array(
            'private_key_bits' => 2048,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
        );
        
        // Generate the private key
        $private_key_resource = openssl_pkey_new($config);
        
        if ($private_key_resource === false) {
            error_log('FastTOTP: Failed to generate private key: ' . openssl_error_string());
            return;
        }
        
        // Extract private key (with proper error checking)
        $private_key_pem = null;
        $result = openssl_pkey_export($private_key_resource, $private_key_pem, null, $config);
        
        if ($result === false || $private_key_pem === null) {
            error_log('FastTOTP: Failed to export private key: ' . openssl_error_string());
            openssl_free_key($private_key_resource);
            return;
        }
        
        // Extract public key
        $public_key_details = openssl_pkey_get_details($private_key_resource);
        
        if ($public_key_details === false || !isset($public_key_details['key'])) {
            error_log('FastTOTP: Failed to get public key details: ' . openssl_error_string());
            openssl_free_key($private_key_resource);
            return;
        }
        
        $public_key_pem = $public_key_details['key'];
        
        // Store keys in options
        $updated_private = update_option('fasttotp_private_key', $private_key_pem);
        $updated_public = update_option('fasttotp_public_key', $public_key_pem);
        
        if (!$updated_private || !$updated_public) {
            error_log('FastTOTP: Failed to store RSA keys in WordPress options.');
        }
        
        // Free resources
        openssl_free_key($private_key_resource);
    }
    
    /**
     * Render enabled field
     */
    public function render_enabled_field() {
        $enabled = get_option('fasttotp_enabled', true);
        echo '<input type="checkbox" name="fasttotp_enabled" value="1" ' . checked(1, $enabled, false) . ' />';
        echo '<label for="fasttotp_enabled"> ' . __('Enable FastTOTP QR code login', 'fasttotp') . '</label>';
    }
    
    /**
     * Render only field
     */
    public function render_only_field() {
        $only = get_option('fasttotp_only', false);
        echo '<input type="checkbox" name="fasttotp_only" value="1" ' . checked(1, $only, false) . ' />';
        echo '<label for="fasttotp_only"> ' . __('Only allow FastTOTP login (disables password login)', 'fasttotp') . '</label>';
    }
    
    /**
     * Handle RSA key generation through admin action
     */
    public function handle_key_generation() {
        if (isset($_GET['page']) && $_GET['page'] == 'fasttotp' && isset($_GET['action']) && $_GET['action'] == 'generate_keys' && isset($_GET['_wpnonce'])) {
            if (wp_verify_nonce($_GET['_wpnonce'], 'fasttotp_generate_keys')) {
                // Check user capabilities
                if (current_user_can('manage_options')) {
                    // Attempt to generate keys
                    $this->generate_rsa_keys();
                    
                    // Verify if keys were actually generated and stored
                    $private_key = get_option('fasttotp_private_key', '');
                    $public_key = get_option('fasttotp_public_key', '');
                    
                    if (!empty($private_key) && !empty($public_key)) {
                        // Set a transient to show success message
                        set_transient('fasttotp_keys_generated', true, 30);
                    } else {
                        // Set error transient if keys weren't generated
                        set_transient('fasttotp_key_generation_error', true, 30);
                    }
                    
                    // Redirect back to the same settings page
                    wp_redirect(add_query_arg(
                        array('page' => 'fasttotp'),
                        admin_url('options-general.php')
                    ));
                    exit;
                }
            }
        }
    }
    
    /**
     * Render generate keys field
     */
    public function render_generate_keys_field() {
        // Create a secure URL for generating keys that points to the current plugin settings page
        $generate_url = wp_nonce_url(
            add_query_arg(array('page' => 'fasttotp', 'action' => 'generate_keys'), admin_url('options-general.php')),
            'fasttotp_generate_keys'
        );
        
        echo '<a href="' . esc_url($generate_url) . '" class="button button-primary">';
        echo __('Generate New RSA Keys', 'fasttotp');
        echo '</a>';
        echo '<p class="description">' . __('Click to generate a new RSA key pair for secure authentication.', 'fasttotp') . '</p>';
    }
    
    /**
     * Render public key field
     */
    public function render_public_key_field() {
        $public_key = get_option('fasttotp_public_key', '');
        if (!empty($public_key)) {
            echo '<textarea rows="10" cols="60" readonly style="font-family: monospace;">' . esc_textarea($public_key) . '</textarea>';
        } else {
            echo '<p style="color: #ff0000;">' . __('No RSA keys generated yet. Click the button above to generate keys.', 'fasttotp') . '</p>';
        }
    }
}

// Initialize the plugin
function fasttotp_init() {
    FastTOTP_WordPress::get_instance();
}
add_action('plugins_loaded', 'fasttotp_init');

/**
 * Activation hook
 */
function fasttotp_activate() {
    // Set default options
    add_option('fasttotp_enabled', true);
    add_option('fasttotp_only', false);
}
register_activation_hook(__FILE__, 'fasttotp_activate');

/**
 * Deactivation hook
 */
function fasttotp_deactivate() {
    // Clean up if necessary
}
register_deactivation_hook(__FILE__, 'fasttotp_deactivate');
