defmodule YachanakuyWeb.Components.QRScanner do
  use Phoenix.Component

  attr :on_scan, :string, required: true
  attr :class, :string, default: ""
  attr :title, :string, default: "Escanear Código QR"

  def qr_scanner(assigns) do
    ~H"""
    <div class={["card bg-white shadow-xl border border-gray-200", @class]}>
      <div class="card-body">
        <h2 class="card-title text-primary font-bold text-xl mb-4"><%= @title %></h2>
        <div id="qr-reader" phx-hook="QRScanner" class="w-full">
          <div id="qr-video-container" class="relative">
            <div id="qr-placeholder" class="flex flex-col items-center justify-center border-2 border-dashed border-primary rounded-lg p-8 bg-gray-50">
              <div class="mb-4">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-16 w-16 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" />
                </svg>
              </div>
              <p class="text-center text-gray-600 mb-4">Apunta la cámara hacia el código QR</p>
              <button 
                id="start-scan-btn" 
                phx-click="start_scan" 
                class="mt-2 bg-primary hover:bg-primary-dark text-white font-bold py-3 px-6 rounded-md transition duration-300"
              >
                Iniciar Escaneo
              </button>
            </div>
            <video id="qr-video" style="display: none; width: 100%; max-width: 600px;" playsinline class="rounded-lg shadow"></video>
          </div>
          <div id="qr-scanner-status" class="mt-4 text-center text-sm text-gray-600 min-h-[20px]"></div>
          <div id="qr-scanner-results" class="mt-4 text-center text-sm text-secondary font-medium min-h-[20px]"></div>
        </div>
      </div>
    </div>
    """
  end
end
