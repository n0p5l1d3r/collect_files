# collect-files — flatten files from a tree into one folder

**collect-files** is a small, robust Bash utility that recursively scans a parent directory and copies every regular file into a single destination folder. It safely handles filenames with spaces, optional extension filtering, collision resolution modes, and a dry-run preview mode.

> ⚠️ This tool copies files. Use `--dry-run` to preview before running.

---

## Features

- Recursively finds and copies regular files
- Optional extension filter (e.g., `--ext "log,txt"`)
- Two collision modes:
  - `suffix` (default): append `_1`, `_2`, ... to duplicates
  - `prefix`: use the source path as a prefix (slashes → underscores) to avoid collisions
- Preserves timestamps and basic permissions via `cp -p`
- Safe handling of filenames with whitespace and special characters
- `--dry-run` to preview actions

---

## Quick install

Clone or copy the script into your repo and make executable:

```bash
git clone https://github.com/n0p5l1d3r/collect_files.git
cd collect_files/
chmod +x collect_files.sh
```

```bash
./collect_files.sh -s /path/to/source -d /path/to/dest [--mode suffix|prefix] [--ext "jpg,png,txt"] [--dry-run]
```

**Required arguments**
`-s, --source` : parent directory to scan (recursive)
`-d, --dest` : destination directory to copy files into

**Options**
`--mode MODE` : collision strategy: suffix (default) or prefix
  - `suffix`: file.txt, file_1.txt, file_2.txt...
  - `prefix`: subdir_file.txt (preserves origin, minimizes collisions)
`--ext LIST` : comma-separated list of extensions to include (no leading dots). If omitted, all files are copied.
`--dry-run` : print actions but do not actually copy files
`-h`, `--help` : show help


## Examples
1. Copy every file under /home/boss/projects into /tmp/all_files (suffix collision mode):
```
./collect_files.sh -s /home/boss/projects -d /tmp/all_files
```
2. Only copy .log and .txt files, using prefix mode to minimize collisions:
```
./collect_files.sh -s /var/log -d /tmp/logs_flat --mode prefix --ext "log,txt"
```
3. Preview an operation without copying:
```
./collect_files.sh -s . -d /tmp/test_flat --dry-run
```


