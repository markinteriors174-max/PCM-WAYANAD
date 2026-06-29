/**
 * Utility to manage unique device token binding.
 * Generates and stores a unique token in the browser's localStorage if one doesn't exist.
 */
export const getOrCreateDeviceToken = (): string => {
  let token = localStorage.getItem('pcm_device_token');
  if (!token) {
    // Generate a robust unique UUID-like identifier
    const randPart = Math.random().toString(36).substring(2, 15);
    const timePart = Date.now().toString(36);
    const randomBuffer = new Uint32Array(2);
    crypto.getRandomValues(randomBuffer);
    const cryptoPart = Array.from(randomBuffer).map(n => n.toString(36)).join('');
    
    token = `dev_${randPart}_${timePart}_${cryptoPart}`;
    localStorage.setItem('pcm_device_token', token);
  }
  return token;
};
