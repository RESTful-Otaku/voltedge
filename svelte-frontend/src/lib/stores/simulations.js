import { writable } from 'svelte/store';

// Simulation store
export const simulationStore = writable({
	simulations: [],
	loading: false,
	error: null
});

// Connection store
export const connectionStore = writable({
	connected: false,
	lastConnected: null
});

// Notification store
export const notificationStore = writable({
	notifications: []
});

// Simulation store methods
export const simulations = {
	async loadSimulations() {
		simulationStore.update(store => ({ ...store, loading: true, error: null }));
		
		try {
			// Mock data for testing
			const mockSimulations = [
				{
					id: 'sim_1',
					name: 'Test Grid Simulation',
					description: 'A test energy grid simulation',
					status: 'running',
					config: {
						power_plants: [
							{
								id: '1',
								name: 'Coal Plant Alpha',
								type: 'coal',
								max_capacity_mw: 500.0,
								current_output_mw: 300.0,
								efficiency: 0.85,
								location: { x: 0.2, y: 0.3, name: 'North Region' },
								is_operational: true
							},
							{
								id: '2',
								name: 'Wind Farm Beta',
								type: 'wind',
								max_capacity_mw: 200.0,
								current_output_mw: 150.0,
								efficiency: 0.95,
								location: { x: 0.7, y: 0.4, name: 'Coastal Region' },
								is_operational: true
							}
						],
						transmission_lines: [
							{
								id: '1',
								from_node: '1',
								to_node: '2',
								capacity_mw: 300.0,
								length_km: 50.0,
								is_operational: true
							}
						],
						base_frequency: 50.0,
						base_voltage: 230.0,
						load_profile: {
							base_load_mw: 400.0,
							peak_multiplier: 1.5,
							daily_variation: 0.3,
							random_variation: 0.1
						}
					},
					tags: ['test', 'demo'],
					metadata: {},
					created_at: new Date().toISOString(),
					updated_at: new Date().toISOString()
				}
			];
			
			simulationStore.update(store => ({
				...store,
				simulations: mockSimulations,
				loading: false
			}));
		} catch (error) {
			simulationStore.update(store => ({
				...store,
				loading: false,
				error: error.message
			}));
		}
	}
};

// Connection store methods
export const connection = {
	setConnected(connected) {
		connectionStore.update(store => ({
			...store,
			connected,
			lastConnected: connected ? new Date() : store.lastConnected
		}));
	}
};

// Notification store methods
export const notifications = {
	add(notification) {
		const id = Date.now() + Math.random();
		const newNotification = {
			id,
			...notification,
			timestamp: new Date()
		};
		
		notificationStore.update(store => ({
			...store,
			notifications: [...store.notifications, newNotification]
		}));
		
		// Auto-remove after duration
		if (notification.duration) {
			setTimeout(() => {
				notifications.remove(id);
			}, notification.duration);
		}
	},
	
	remove(id) {
		notificationStore.update(store => ({
			...store,
			notifications: store.notifications.filter(n => n.id !== id)
		}));
	},
	
	clear() {
		notificationStore.update(store => ({
			...store,
			notifications: []
		}));
	}
};

