import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		port: 5173,
		host: true,
		proxy: {
			'/api': {
				target: 'http://localhost:8080',
				changeOrigin: true,
				secure: false
			},
			'/ws': {
				target: 'ws://localhost:8080',
				ws: true,
				changeOrigin: true
			}
		}
	},
	build: {
		outDir: 'dist',
		sourcemap: true,
		rollupOptions: {
			output: {
				manualChunks: {
					vendor: ['svelte', 'svelte/store']
				}
			}
		}
	},
	define: {
		__VERSION__: JSON.stringify(process.env.npm_package_version)
	}
});
