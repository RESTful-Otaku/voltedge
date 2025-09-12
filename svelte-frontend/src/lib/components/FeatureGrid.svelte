<script>
	// Feature data
	const features = [
		{
			title: "Real-time Simulation",
			description: "High-performance Zig engine simulating complex energy grids with millisecond precision.",
			icon: "simulation",
			color: "blue"
		},
		{
			title: "Interactive Visualization",
			description: "D3.js-powered grid visualization with real-time updates and interactive controls.",
			icon: "visualization",
			color: "purple"
		},
		{
			title: "Fault Injection",
			description: "Test grid resilience by injecting various types of failures and cyber attacks.",
			icon: "fault",
			color: "red"
		},
		{
			title: "Analytics Dashboard",
			description: "Comprehensive metrics, performance monitoring, and predictive analytics.",
			icon: "analytics",
			color: "green"
		},
		{
			title: "API Gateway",
			description: "RESTful APIs and WebSocket streaming for seamless integration and control.",
			icon: "api",
			color: "indigo"
		},
		{
			title: "Microservices",
			description: "Scalable Go-based microservices architecture with full observability.",
			icon: "microservices",
			color: "yellow"
		}
	];
	
	// Get icon SVG
	function getIcon(iconName) {
		const icons = {
			simulation: `<svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>`,
			visualization: `<svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>`,
			fault: `<svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>`,
			analytics: `<svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>`,
			api: `<svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>`,
			microservices: `<svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path></svg>`
		};
		return icons[iconName] || icons.simulation;
	}
	
	// Get color classes
	function getColorClasses(color) {
		const colors = {
			blue: {
				bg: 'bg-blue-100',
				text: 'text-blue-600',
				border: 'border-blue-200'
			},
			purple: {
				bg: 'bg-purple-100',
				text: 'text-purple-600',
				border: 'border-purple-200'
			},
			red: {
				bg: 'bg-red-100',
				text: 'text-red-600',
				border: 'border-red-200'
			},
			green: {
				bg: 'bg-green-100',
				text: 'text-green-600',
				border: 'border-green-200'
			},
			indigo: {
				bg: 'bg-indigo-100',
				text: 'text-indigo-600',
				border: 'border-indigo-200'
			},
			yellow: {
				bg: 'bg-yellow-100',
				text: 'text-yellow-600',
				border: 'border-yellow-200'
			}
		};
		return colors[color] || colors.blue;
	}
</script>

<section class="py-20 bg-white">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center mb-16">
			<h2 class="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
				Powerful Features
			</h2>
			<p class="text-xl text-gray-600 max-w-3xl mx-auto">
				VoltEdge combines cutting-edge technology with intuitive design to deliver the most advanced energy grid simulation platform available.
			</p>
		</div>
		
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
			{#each features as feature}
				{@const colorClasses = getColorClasses(feature.color)}
				<div class="bg-white rounded-xl border {colorClasses.border} p-8 hover:shadow-lg transition-shadow duration-300">
					<!-- Icon -->
					<div class="w-16 h-16 {colorClasses.bg} rounded-lg flex items-center justify-center mb-6">
						<span class="{colorClasses.text}">
							{@html getIcon(feature.icon)}
						</span>
					</div>
					
					<!-- Content -->
					<h3 class="text-xl font-semibold text-gray-900 mb-3">
						{feature.title}
					</h3>
					<p class="text-gray-600 leading-relaxed">
						{feature.description}
					</p>
				</div>
			{/each}
		</div>
	</div>
</section>

