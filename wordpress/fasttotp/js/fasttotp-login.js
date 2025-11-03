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
        
        // Set global request ID if provided
        if (options.requestId) {
            window.fasttotpCurrentRequestId = options.requestId;
        }
        
        // Check if jQuery is loaded, wait or use native JavaScript if not
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
                            setTimeout(checkLogin, 2000);
                        },
                        error: function() {
                            setTimeout(checkLogin, 2000);
                        }
                    });
                }
                
                // Initialize
                if (jq('.fasttotp-login-section').length) {
                    updateStatus();
                    checkLogin();
                }
            } else if (typeof window.jQuery === 'undefined' && typeof wp !== 'undefined' && wp.element) {
                // If WordPress wp.element is available but jQuery is not, use native JavaScript fallback
                fallbackImplementation();
            } else {
                // jQuery not loaded, try again after a short delay
                setTimeout(initFastTOTP, 500);
            }
        }
        
        // Native JavaScript fallback implementation
        function fallbackImplementation() {
            var requestId = window.fasttotpCurrentRequestId;
            var statusElement = document.getElementById('fasttotp-status');
            
            if (statusElement) {
                statusElement.textContent = fasttotpStatusText;
            }
            
            function checkLogin() {
                if (!requestId) {
                    setTimeout(checkLogin, 2000);
                    return;
                }
                
                // Use native XMLHttpRequest
                var xhr = new XMLHttpRequest();
                xhr.open('GET', fasttotpCheckUrl + '?request_id=' + encodeURIComponent(requestId));
                xhr.responseType = 'json';
                xhr.onload = function() {
                    if (xhr.status === 200 && xhr.response && xhr.response.logged_in) {
                        window.location.href = '/wp-admin/';
                        return;
                    }
                    setTimeout(checkLogin, 2000);
                };
                xhr.onerror = function() {
                    setTimeout(checkLogin, 2000);
                };
                xhr.send();
            }
            
            checkLogin();
        }
        
        // If document is already loaded, initialize immediately; otherwise wait for DOMContentLoaded
        if (document.readyState === 'complete' || document.readyState === 'interactive') {
            setTimeout(initFastTOTP, 10);
        } else {
            document.addEventListener('DOMContentLoaded', initFastTOTP);
        }
    };
})(window);