/**
 * location_service.js
 * 
 * HTML5 Geolocation API wrapper with reverse geocoding to resolve address & ISO country code.
 */

export class LocationService {
  /**
   * Retrieves current position coordinates, physical address, and country code.
   */
  static async getCurrentLocation() {
    return new Promise((resolve) => {
      if (!navigator.geolocation) {
        return resolve({
          latitude: null,
          longitude: null,
          address: 'Geolocation not supported by browser',
          accuracy: 'Unavailable',
          isoCountryCode: 'IN'
        });
      }

      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const lat = position.coords.latitude;
          const lon = position.coords.longitude;
          const accuracy = `${position.coords.accuracy.toFixed(1)}m`;

          let address = `Lat: ${lat.toFixed(4)}, Lng: ${lon.toFixed(4)}`;
          let isoCountryCode = 'IN';

          try {
            // Reverse geocode using OpenStreetMap Nominatim free endpoint
            const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}`);
            if (res.ok) {
              const data = await res.json();
              if (data && data.address) {
                const a = data.address;
                const parts = [
                  a.road || a.suburb || '',
                  a.city || a.town || a.county || '',
                  a.state || '',
                  a.country || ''
                ].filter(Boolean);
                
                address = parts.join(', ');
                if (a.country_code) {
                  isoCountryCode = a.country_code.toUpperCase();
                }
              }
            }
          } catch (err) {
            console.warn('[LocationService] Reverse geocoding failed:', err);
          }

          resolve({
            latitude: lat,
            longitude: lon,
            address,
            accuracy,
            isoCountryCode
          });
        },
        (err) => {
          console.warn('[LocationService] Geolocation error:', err);
          resolve({
            latitude: null,
            longitude: null,
            address: 'Hyderabad, Telangana, India (Fallback GPS)',
            accuracy: 'Fallback',
            isoCountryCode: 'IN'
          });
        },
        { timeout: 5000, enableHighAccuracy: true }
      );
    });
  }

  /**
   * Retrieves battery status using Web Battery API if supported
   */
  static async getBatteryLevel() {
    try {
      if ('getBattery' in navigator) {
        const battery = await navigator.getBattery();
        return `${Math.round(battery.level * 100)}%`;
      }
    } catch (e) {
      console.warn('[LocationService] Battery API error:', e);
    }
    return '85%';
  }
}
