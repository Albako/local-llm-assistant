import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  	appId: 'com.openwebui.app',
  	appName: 'Open WebUI',
  	webDir: 'build',
  	server: {
    	androidScheme: 'https',
    	url: 'http://<IP address of the server with backend>:3000',
    	cleartext: true
  	},
	plugins: {
		StatusBar: {
			style: 'dark',
			backgroundColor: '#000000'
		},
		SafeArea: {
			customColorsForSystemBars: true
		}
	}
};

export default config;
