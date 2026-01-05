import type {SchedStat} from '@forensic-trace/protocol';

/**
 * Test cross package type imports
 */
function ghostParser(raw: string): SchedStat {
	const [cpuTime, runDelay, pCount] = raw.trim().split(/\s+/);

	return {
		cpuTime: cpuTime || '0',
		runDelay: runDelay || '0',
		pCount: pCount || '0',
	};
}

// Simulated line from /proc/[pid]/schedstat
const sampleLine = '145000200 5000 12';
const telemetry = ghostParser(sampleLine);

console.log('👻 Lab 01: Ghosthunter');
console.log('-------------------------------------');
console.log(`Metric (Wait Time): ${telemetry.runDelay}ns`);
console.log(`Status: ${BigInt(telemetry.runDelay) > 0 ? 'INVESTIGATE (CPU Theft detected)' : 'NOMINAL'}`);
