You are analyzing a repository with limited context window.

Follow these rules:

1. First list the directory structure only.
2. Do not read file contents yet.
3. Ignore large folders:
   node_modules, .git, build, dist, venv.
4. After listing files, identify only the critical files needed to understand the project.

Goal:
Understand the architecture while minimizing context usage.