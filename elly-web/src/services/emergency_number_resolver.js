/**
 * emergency_number_resolver.js
 * 
 * Resolves country & category-specific emergency numbers (e.g. Police 100, Fire 101,
 * Ambulance 102/108, Universal 112 in India) based on live location coordinates & geocoding.
 */

const countryEmergencyNumbers = {
  IN: '112',
  US: '911',
  CA: '911',
  GB: '999',
  UK: '999',
  AU: '000',
  NZ: '111',
  JP: '110',
  CN: '110',
  DE: '112',
  FR: '112',
  IT: '112',
  ES: '112'
};

const countryServiceNumbers = {
  IN: {
    police: '100',
    fire: '101',
    ambulance: '102',
    medical: '108',
    traffic: '103',
    disaster: '1096',
    child: '1098',
    universal: '112'
  },
  US: {
    police: '911',
    fire: '911',
    ambulance: '911',
    universal: '911'
  },
  GB: {
    police: '999',
    fire: '999',
    ambulance: '999',
    universal: '999'
  },
  AU: {
    police: '000',
    fire: '000',
    ambulance: '000',
    universal: '000'
  }
};

export class EmergencyNumberResolver {
  /**
   * Resolves national universal emergency number (e.g. 112 in India, 911 in US)
   */
  static resolveNumber({ countryCode, address } = {}) {
    if (countryCode) {
      const code = countryCode.toUpperCase().trim();
      if (countryEmergencyNumbers[code]) return countryEmergencyNumbers[code];
    }

    if (address) {
      const addr = address.toUpperCase();
      if (addr.includes('INDIA') || addr.includes('TELANGANA') || addr.includes('HYDERABAD') || addr.includes('DELHI') || addr.includes('MUMBAI') || addr.includes('BENGALURU')) {
        return countryEmergencyNumbers.IN; // 112
      }
      if (addr.includes('UNITED STATES') || addr.includes('USA')) return countryEmergencyNumbers.US;
      if (addr.includes('UNITED KINGDOM') || addr.includes('LONDON')) return countryEmergencyNumbers.GB;
    }

    return '112'; // Default International GSM Universal standard
  }

  /**
   * Resolves category-specific service number (e.g. Police: 100, Ambulance: 102/108, Fire: 101)
   */
  static resolveServiceNumber({ category, countryCode, address } = {}) {
    const catLower = (category || '').toLowerCase().trim();
    let serviceKey = 'universal';

    if (catLower.includes('medical') || catLower.includes('ambulance') || catLower.includes('accident') || catLower.includes('injury')) {
      serviceKey = 'ambulance';
    } else if (catLower.includes('police') || catLower.includes('personal') || catLower.includes('safety') || catLower.includes('threat') || catLower.includes('violence')) {
      serviceKey = 'police';
    } else if (catLower.includes('fire') || catLower.includes('hazard') || catLower.includes('gas')) {
      serviceKey = 'fire';
    } else if (catLower.includes('disaster') || catLower.includes('natural')) {
      serviceKey = 'disaster';
    }

    let country = 'IN'; // Fallback default
    if (countryCode) {
      country = countryCode.toUpperCase().trim();
    } else if (address) {
      const addr = address.toUpperCase();
      if (addr.includes('INDIA') || addr.includes('TELANGANA') || addr.includes('HYDERABAD')) country = 'IN';
      else if (addr.includes('UNITED STATES') || addr.includes('USA')) country = 'US';
      else if (addr.includes('UNITED KINGDOM') || addr.includes('UK')) country = 'GB';
    }

    if (countryServiceNumbers[country] && countryServiceNumbers[country][serviceKey]) {
      return countryServiceNumbers[country][serviceKey];
    }

    return this.resolveNumber({ countryCode: country, address });
  }

  /**
   * Places an immediate emergency telephone call via web tel: URI protocol
   */
  static makeEmergencyCall(phoneNumber) {
    const cleanNumber = phoneNumber.replace(/[^\d+]/g, '');
    console.log(`[EmergencyNumberResolver] Placing emergency call to ${cleanNumber}`);
    window.location.href = `tel:${cleanNumber}`;
  }
}
