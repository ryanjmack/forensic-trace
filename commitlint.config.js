export default {
	extends: ['@commitlint/config-conventional'],
	rules: {
		'scope-enum': [2, 'always', ['infra', 'proto', 'core', 'ui', 'lab', 'meta']],
		'type-enum': [2, 'always', ['feat', 'fix', 'perf', 'chore', 'refactor', 'docs']],
	},
};
