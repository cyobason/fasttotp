(function(window) {
    // FastTOTP login handler
    window.FastTOTP = window.FastTOTP || {};
    
    /**
     * Initialize FastTOTP login functionality
     * @param {Object} options - Configuration options
     * @param {string} options.checkUrl - URL to check login status
     * @param {string} options.statusText - Status text to display
     * @param {string} [options.requestId] - Optional request ID
     */
    window.FastTOTP.initLogin = function(options) {
        if (!options || !options.checkUrl) {
            console.error('FastTOTP: Missing required options');
            return;
        }
        
        var fasttotpCheckUrl = options.checkUrl;
        var fasttotpStatusText = options.statusText || 'Please scan the QR code with your FastTOTP app';
        var fasttotpExpiredText = 'QR code has expired. Please refresh.';
        
        // Set global request ID if provided
        if (options.requestId) {
            window.fasttotpCurrentRequestId = options.requestId;
        }
        
        // Initialize expiry time if not set
        if (!window.fasttotpQRCodeExpiry) {
            window.fasttotpQRCodeExpiry = 300; // 5 minutes in seconds
        }
        
        // Initialize created time if not set
        if (!window.fasttotpQRCodeCreated) {
            window.fasttotpQRCodeCreated = Math.floor(Date.now() / 1000);
        }
        
        // Check if jQuery is loaded
        function initFastTOTP() {
            if (typeof jQuery !== 'undefined') {
                // jQuery available, use jQuery implementation
                var jq = jQuery;
                
                // Status update function
                function updateStatus() {
                    jq("#fasttotp-status").text(fasttotpStatusText);
                }
                
                // Login check function
                function checkLogin() {
                    // Check if QR code has expired before making the request
                    if (isQRCodeExpired()) {
                        return; // Stop checking when expired
                    }
                    
                    // Get request ID
                    var requestId = window.fasttotpCurrentRequestId || jq('.fasttotp-login-section').data('request-id');
                    
                    if (!requestId) {
                        setTimeout(checkLogin, 2000);
                        return;
                    }
                    
                    jq.ajax({
                        url: fasttotpCheckUrl,
                        type: "GET",
                        data: { request_id: requestId },
                        dataType: "json",
                        success: function(data) {
                            if (data && data.logged_in) {
                                window.location.href = '/wp-admin/';
                                return;
                            }
                            // Only continue checking if QR code is still valid
                            if (!isQRCodeExpired()) {
                                setTimeout(checkLogin, 2000);
                            }
                        },
                        error: function() {
                            // Only continue checking if QR code is still valid
                            if (!isQRCodeExpired()) {
                                setTimeout(checkLogin, 2000);
                            }
                        }
                    });
                }
                
                // Check if QR code is expired
                function isQRCodeExpired() {
                    var currentTime = Math.floor(Date.now() / 1000);
                    var elapsedTime = currentTime - window.fasttotpQRCodeCreated;
                    return elapsedTime >= window.fasttotpQRCodeExpiry;
                }
                
                // Update countdown display
                function updateCountdown() {
                    var countdownElement = jq('#fasttotp-countdown');
                    var refreshButtonContainer = jq('.fasttotp-refresh-btn');
                    
                    // Clear any existing timeout to prevent multiple countdowns running simultaneously
                    if (window.fasttotpCountdownTimeout) {
                        clearTimeout(window.fasttotpCountdownTimeout);
                    }
                    
                    function update() {
                        if (isQRCodeExpired()) {
                            countdownElement.text(fasttotpExpiredText);
                            countdownElement.css('color', '#dc3545');
                            jq('.fasttotp-qr-code').css('opacity', '0.5');
                            refreshButtonContainer.show();
                            return;
                        }
                        
                        var currentTime = Math.floor(Date.now() / 1000);
                        var elapsedTime = currentTime - window.fasttotpQRCodeCreated;
                        var remainingTime = window.fasttotpQRCodeExpiry - elapsedTime;
                        
                        // Format as MM:SS
                        var minutes = Math.floor(remainingTime / 60);
                        var seconds = remainingTime % 60;
                        var formattedTime = minutes.toString().padStart(2, '0') + ':' + seconds.toString().padStart(2, '0');
                        
                        countdownElement.text('Valid for: ' + formattedTime);
                        countdownElement.css('color', '#666');
                        refreshButtonContainer.hide();
                        
                        // Store timeout reference to clear it later if needed
                        window.fasttotpCountdownTimeout = setTimeout(update, 1000);
                    }
                    
                    update(); // Initial update
                }
                
                // Setup refresh button functionality
                function setupRefreshButton() {
                    jq('#fasttotp-refresh-qr').on('click', function() {
                        // Show loading state
                        jq(this).text('Refreshing...');
                        
                        // Make AJAX request to get new QR code
                        jq.ajax({
                            url: window.ajaxurl || '/wp-admin/admin-ajax.php',
                            type: 'GET',
                            data: {
                                action: 'fasttotp_get_qr_code',
                                nonce: typeof fasttotpQrNonce !== 'undefined' ? fasttotpQrNonce : ''
                            },
                            dataType: 'json',
                            success: function(data) {
                                if (data && data.success && data.data) {
                                    // Update QR code image
                                    jq('#fasttotp-qr-image').attr('src', data.data.qr_code);
                                    
                                    // Update request ID
                                    window.fasttotpCurrentRequestId = data.data.request_id;
                                    jq('.fasttotp-login-section').data('request-id', data.data.request_id);
                                    
                                    // Update timestamps (critical for expiry check)
                                    window.fasttotpQRCodeCreated = Math.floor(Date.now() / 1000);
                                    
                                    // Reset UI
                                    updateStatus();
                                    jq('#fasttotp-countdown').css('color', '#666');
                                    jq('.fasttotp-qr-code').css('opacity', '1');
                                    jq('.fasttotp-refresh-btn').hide();
                                    
                                    // Restart countdown with new timestamp
                                    updateCountdown();
                                    
                                    // Restart login checking
                                    checkLogin();
                                }
                            },
                            complete: function() {
                                // Reset button text
                                jq('#fasttotp-refresh-qr').text('Refresh QR Code');
                            }
                        });
                    });
                }
                
                // Initialize
                if (jq('.fasttotp-login-section').length) {
                    updateStatus();
                    updateCountdown(); // Start countdown
                    setupRefreshButton(); // Setup refresh button
                    
                    // Only check login if QR code is valid
                    if (!isQRCodeExpired()) {
                        checkLogin();
                    }
                }
            }
        }
        
        // If document is already loaded, initialize immediately; otherwise wait for DOMContentLoaded
        if (document.readyState === 'complete' || document.readyState === 'interactive') {
            setTimeout(initFastTOTP, 10);
        } else {
            document.addEventListener('DOMContentLoaded', initFastTOTP);
        }
    };
})(window);