# Error

This tool does not work with base `minimal`.

## Details

When running `aicage cline` with base `minimal` in a project folder, it crashes with:
```
Cleaning up core process (PID: 51)
Cleaning up host process (PID: 50)
Error: failed to start new instance: failed to start instance: operation failed to after 12 attempts: instance not found in registry: instance localhost:39487 not found

This is usually caused by an incompatible Node.js version

REQUIREMENTS:
• Node.js version 20+ is required
• Current Node.js version: v25.2.1

DEBUGGING STEPS:
1. View recent logs: cline log list
2. Logs are available in: ~/.cline/logs/
3. The most recent cline-core log file is usually valuable

For additional help, visit: https://github.com/cline/cline/issues
```
followed by clines usage output.

