import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import { viteStaticCopy } from 'vite-plugin-static-copy';
import { SvelteKitPWA } from '@vite-pwa/sveltekit';

export default defineConfig({
	plugins: [
		sveltekit(),
		viteStaticCopy({
			targets: [
				{
					src: 'node_modules/onnxruntime-web/dist/*.jsep.*',

					dest: 'wasm'
				}
			]
		}),
		SvelteKitPWA({
            registerType: 'autoUpdate',
            devOptions: {
                enabled: true
            },
            manifest: false,
            workbox: {
                globPatterns: ['**/*.{js,css,html,ico,png,svg,json,woff,woff2,ttf}'],
                navigateFallbackDenylist: [/^\/api/],
                maximumFileSizeToCacheInBytes: 5 * 1024 * 1024
            }
        })
	],
	define: {
		APP_VERSION: JSON.stringify(process.env.npm_package_version),
		APP_BUILD_HASH: JSON.stringify(process.env.APP_BUILD_HASH || 'dev-build')
	},
	build: {
		sourcemap: true
	},
	worker: {
		format: 'es'
	},
	esbuild: {
		pure: ['console.log', 'console.debug']
	}
});
