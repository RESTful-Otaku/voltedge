import adapter from '@sveltejs/adapter-static';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	kit: {
		adapter: adapter({
			pages: 'build',
			assets: 'build',
			fallback: 'index.html',
			precompress: false,
			strict: true
		}),
		paths: {
			base: process.env.NODE_ENV === 'production' ? '/voltedge' : ''
		},
		alias: {
			'$components': 'src/lib/components',
			'$stores': 'src/lib/stores',
			'$utils': 'src/lib/utils',
			'$types': 'src/lib/types'
		}
	}
};

export default config;

