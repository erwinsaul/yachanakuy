// QR Scanner functionality using HTML5 and JavaScript
// Based on the MediaDevices API for camera access and jsQR for decoding

export const QRScannerHook = {
  mounted() {
    this.video = this.el.querySelector('#qr-video');
    this.placeholder = this.el.querySelector('#qr-placeholder');
    this.startButton = this.el.querySelector('#start-scan-btn');
    this.canvas = null;
    this.context = null;
    this.scannerInterval = null;
    this.stream = null;
    
    // Wait for jsQR to be loaded
    this.waitForLibrary().then(() => {
      // Add event listener to the start button
      if (this.startButton) {
        this.startButton.addEventListener('click', () => {
          this.startScanner();
        });
      }
    });
  },

  updated() {
    // Component was updated, potentially re-initialize if needed
  },

  destroyed() {
    this.stopScanner();
  },

  waitForLibrary() {
    // Check if jsQR is loaded
    return new Promise((resolve, reject) => {
      const checkLib = () => {
        if (typeof window.jsQR !== 'undefined') {
          resolve(window.jsQR);
        } else {
          setTimeout(checkLib, 100);
        }
      };
      
      setTimeout(() => {
        reject(new Error('jsQR library not loaded'));
      }, 5000); // 5 second timeout
      
      checkLib();
    });
  },

  hasGetUserMedia() {
    return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
  },

  async startScanner() {
    if (!this.hasGetUserMedia()) {
      this.showError('Tu navegador no soporta acceso a la cámara');
      return;
    }

    // Create canvas if it doesn't exist
    if (!this.canvas) {
      this.canvas = document.createElement('canvas');
      this.context = this.canvas.getContext('2d');
    }
    
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ 
        video: { 
          facingMode: 'environment', // Use back camera if available
          width: { ideal: 1280 },
          height: { ideal: 720 }
        } 
      });
      
      this.stream = stream;
      this.video.srcObject = stream;
      this.video.setAttribute('playsinline', true); // Required for iOS
      
      // Show video and hide placeholder
      this.placeholder.style.display = 'none';
      this.video.style.display = 'block';
      
      // Update status
      const statusText = document.getElementById('qr-scanner-status');
      if (statusText) {
        statusText.textContent = 'Escaneando código QR...';
        statusText.className = 'text-center mt-2 text-sm text-gray-600';
      }

      this.video.play().then(() => {
        // Start the scanning process
        this.startScanning();
      }).catch(error => {
        console.error('Error playing video:', error);
        this.showError('Error al iniciar la cámara');
      });
    } catch (error) {
      console.error('Error accessing camera:', error);
      this.showError('No se pudo acceder a la cámara. Asegúrate de permitir el acceso.');
    }
  },

  startScanning() {
    // Clear any existing interval
    if (this.scannerInterval) {
      clearInterval(this.scannerInterval);
    }
    
    this.scannerInterval = setInterval(() => {
      if (this.video.readyState === this.video.HAVE_ENOUGH_DATA) {
        if (this.canvas.width !== this.video.videoWidth) {
          this.canvas.width = this.video.videoWidth;
          this.canvas.height = this.video.videoHeight;
        }
        
        this.context.drawImage(this.video, 0, 0, this.canvas.width, this.canvas.height);
        const imageData = this.context.getImageData(0, 0, this.canvas.width, this.canvas.height);
        
        const code = window.jsQR(imageData.data, imageData.width, imageData.height, {
          inversionAttempts: "dontInvert",
        });
        
        if (code) {
          this.processQRCode(code);
        }
      }
    }, 500); // Scan every 500ms
  },

  processQRCode(code) {
    if (this.lastScannedCode !== code.data) {
      this.lastScannedCode = code.data;
      
      // Stop scanning briefly to avoid duplicate reads
      if (this.scannerInterval) {
        clearInterval(this.scannerInterval);
        this.scannerInterval = null;
      }
      
      // Show success feedback
      const statusText = document.getElementById('qr-scanner-status');
      const resultsDiv = document.getElementById('qr-scanner-results');
      if (statusText) {
        statusText.textContent = '';
      }
      if (resultsDiv) {
        resultsDiv.textContent = `Código escaneado: ${code.data.substring(0, 30)}...`;
        resultsDiv.classList.remove('hidden');
      }
      
      // Send the event to the LiveView
      this.pushEvent('qr_scanned', { data: code.data });
      
      // Resume scanning after a delay
      setTimeout(() => {
        this.startScanning();
      }, 2000);
    }
  },

  stopScanner() {
    if (this.scannerInterval) {
      clearInterval(this.scannerInterval);
      this.scannerInterval = null;
    }
    
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }
  },

  showError(message) {
    const statusText = document.getElementById('qr-scanner-status');
    if (statusText) {
      statusText.innerHTML = `
        <div class="alert alert-error">
          <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>${message}</span>
        </div>
      `;
    }
  }
};