/**
 * Mobile utilities for Capacitor integration
 * Provides helper functions to detect and use native mobile features
 */

import { App } from '@capacitor/app';
import { Device } from '@capacitor/device';
import { Network } from '@capacitor/network';

/**
 * Check if the app is running on a native mobile platform
 */
export const isNativeMobile = (): boolean => {
	if (typeof window === 'undefined') return false;
	return !!(window as any).capacitor;
};

/**
 * Get device information
 */
export const getDeviceInfo = async () => {
	if (!isNativeMobile()) {
		return null;
	}
	try {
		return await Device.getInfo();
	} catch (error) {
		console.error('Failed to get device info:', error);
		return null;
	}
};

/**
 * Check current network status
 */
export const checkNetworkStatus = async () => {
	if (!isNativeMobile()) {
		return {
			connected: navigator.onLine,
			connectionType: 'unknown'
		};
	}
	try {
		const status = await Network.getStatus();
		return {
			connected: status.connected,
			connectionType: status.connectionType
		};
	} catch (error) {
		console.error('Failed to check network status:', error);
		return {
			connected: navigator.onLine,
			connectionType: 'unknown'
		};
	}
};

/**
 * Listen for network status changes
 */
export const listenToNetworkChanges = (callback: (connected: boolean) => void) => {
	if (!isNativeMobile()) {
		// Fallback to browser online/offline events
		window.addEventListener('online', () => callback(true));
		window.addEventListener('offline', () => callback(false));
		return () => {
			window.removeEventListener('online', () => callback(true));
			window.removeEventListener('offline', () => callback(false));
		};
	}

	try {
		const unsubscribe = Network.addListener('networkStatusChange', (status) => {
			callback(status.connected);
		});
		return () => unsubscribe.remove();
	} catch (error) {
		console.error('Failed to listen to network changes:', error);
		return () => {};
	}
};

/**
 * Handle app pause/resume
 */
export const setupAppLifecycle = (
	onPause?: () => void,
	onResume?: () => void
) => {
	if (!isNativeMobile()) {
		// Fallback to visibility change events
		document.addEventListener('visibilitychange', () => {
			if (document.hidden) {
				onPause?.();
			} else {
				onResume?.();
			}
		});
		return () => {
			document.removeEventListener('visibilitychange', () => {});
		};
	}

	try {
		const pauseListener = App.addListener('pause', onPause ?? (() => {}));
		const resumeListener = App.addListener('resume', onResume ?? (() => {}));

		return () => {
			pauseListener.remove();
			resumeListener.remove();
		};
	} catch (error) {
		console.error('Failed to setup app lifecycle:', error);
		return () => {};
	}
};

/**
 * Handle app back button (Android)
 */
export const setupBackButton = (callback: () => void) => {
	if (!isNativeMobile()) {
		return () => {};
	}

	try {
		const backListener = App.addListener('backButton', callback);
		return () => backListener.remove();
	} catch (error) {
		console.error('Failed to setup back button listener:', error);
		return () => {};
	}
};

/**
 * Get platform information
 */
export const getPlatformInfo = async () => {
	if (!isNativeMobile()) {
		return {
			platform: 'web',
			version: navigator.userAgent
		};
	}

	try {
		const info = await Device.getInfo();
		return {
			platform: info.platform,
			version: info.osVersion,
			model: info.model,
			manufacturer: info.manufacturer
		};
	} catch (error) {
		console.error('Failed to get platform info:', error);
		return {
			platform: 'unknown',
			version: 'unknown'
		};
	}
};

export default {
	isNativeMobile,
	getDeviceInfo,
	checkNetworkStatus,
	listenToNetworkChanges,
	setupAppLifecycle,
	setupBackButton,
	getPlatformInfo
};
