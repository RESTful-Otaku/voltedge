<script>
	// Technology stack data
	const technologies = [
		{
			name: "Zig",
			description: "Low-level simulation engine",
			role: "High-performance core",
			features: ["100K+ events/sec", "Memory safe", "Deterministic"],
			color: "orange"
		},
		{
			name: "Go",
			description: "Microservices & orchestration",
			role: "Service layer",
			features: ["REST APIs", "WebSocket streaming", "Observability"],
			color: "blue"
		},
		{
			name: "Svelte",
			description: "Modern reactive frontend",
			role: "User interface",
			features: ["Real-time updates", "D3.js visualization", "Responsive design"],
			color: "red"
		}
	];
	
	// Get color classes
	function getColorClasses(color) {
		const colors = {
			orange: {
				bg: 'bg-orange-100',
				text: 'text-orange-600',
				border: 'border-orange-200',
				badge: 'bg-orange-600'
			},
			blue: {
				bg: 'bg-blue-100',
				text: 'text-blue-600',
				border: 'border-blue-200',
				badge: 'bg-blue-600'
			},
			red: {
				bg: 'bg-red-100',
				text: 'text-red-600',
				border: 'border-red-200',
				badge: 'bg-red-600'
			}
		};
		return colors[color] || colors.blue;
	}
</script>

<section class="py-20 bg-gray-50">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="text-center mb-16">
			<h2 class="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
				Technology Stack
			</h2>
			<p class="text-xl text-gray-600 max-w-3xl mx-auto">
				Built with modern technologies that deliver exceptional performance, scalability, and developer experience.
			</p>
		</div>
		
		<div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
			{#each technologies as tech}
				{@const colorClasses = getColorClasses(tech.color)}
				<div class="bg-white rounded-xl border {colorClasses.border} p-8 hover:shadow-lg transition-shadow duration-300">
					<!-- Header -->
					<div class="flex items-center mb-6">
						<div class="w-12 h-12 {colorClasses.bg} rounded-lg flex items-center justify-center mr-4">
							<span class="text-2xl font-bold {colorClasses.text}">
								{tech.name.charAt(0)}
							</span>
						</div>
						<div>
							<h3 class="text-xl font-bold text-gray-900">{tech.name}</h3>
							<span class="inline-block px-3 py-1 {colorClasses.badge} text-white text-xs font-medium rounded-full">
								{tech.role}
							</span>
						</div>
					</div>
					
					<!-- Description -->
					<p class="text-gray-600 mb-6">
						{tech.description}
					</p>
					
					<!-- Features -->
					<div class="space-y-2">
						{#each tech.features as feature}
							<div class="flex items-center">
								<div class="w-2 h-2 {colorClasses.text} bg-current rounded-full mr-3"></div>
								<span class="text-sm text-gray-700">{feature}</span>
							</div>
						{/each}
					</div>
				</div>
			{/each}
		</div>
		
		<!-- Architecture Diagram Placeholder -->
		<div class="mt-16 text-center">
			<div class="bg-white rounded-xl border border-gray-200 p-8">
				<h3 class="text-xl font-semibold text-gray-900 mb-4">System Architecture</h3>
				<div class="flex items-center justify-center space-x-8 text-sm text-gray-600">
					<div class="text-center">
						<div class="w-16 h-16 bg-orange-100 rounded-lg flex items-center justify-center mx-auto mb-2">
							<span class="text-orange-600 font-bold">Z</span>
						</div>
						<p>Zig Core</p>
					</div>
					<div class="flex-1 h-px bg-gray-300"></div>
					<div class="text-center">
						<div class="w-16 h-16 bg-blue-100 rounded-lg flex items-center justify-center mx-auto mb-2">
							<span class="text-blue-600 font-bold">G</span>
						</div>
						<p>Go Services</p>
					</div>
					<div class="flex-1 h-px bg-gray-300"></div>
					<div class="text-center">
						<div class="w-16 h-16 bg-red-100 rounded-lg flex items-center justify-center mx-auto mb-2">
							<span class="text-red-600 font-bold">S</span>
						</div>
						<p>Svelte UI</p>
					</div>
				</div>
			</div>
		</div>
	</div>
</section>

