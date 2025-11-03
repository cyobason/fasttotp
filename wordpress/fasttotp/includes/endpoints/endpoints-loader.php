<?php
/**
 * FastTOTP Endpoints Loader
 *
 * Loads all REST API endpoint classes.
 *
 * @package FastTOTP
 */

// Include all endpoint classes.
require_once plugin_dir_path(__FILE__) . 'class-fasttotp-get-public-key.php';
require_once plugin_dir_path(__FILE__) . 'class-fasttotp-submit-device-email.php';
require_once plugin_dir_path(__FILE__) . 'class-fasttotp-verify-totp-code.php';
require_once plugin_dir_path(__FILE__) . 'class-fasttotp-check-login-status.php';